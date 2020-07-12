defmodule Layout do
  defmodule Tokenizer do
    @token_types [
      {:identifier, ~r/\A(\b[a-zA-z_]+\b)/},
      {:integer, ~r/\A(\b[0-9]+\b)/},
      {:oparen, ~r/\A(\()/},
      {:comma, ~r/\A(,)/},
      {:cparen, ~r/\A(\))/}
    ]

    def tokenize("", tokens), do: Enum.reverse(tokens)

    def tokenize(code, tokens) do
      {type, value} =
        Enum.find_value(@token_types, fn {type, re} ->
          case Regex.run(re, code) do
            nil -> false
            [_, match] -> {type, match}
          end
        end)

      code
      |> String.replace_prefix(value, "")
      |> String.trim()
      |> tokenize([{type, value} | tokens])
    end
  end

  defmodule Parser do
    def parse([], tree), do: Enum.reverse(tree)

    def parse(tokens, tree) do
      {node, rest} = parse(tokens)

      parse(rest, [node | tree])
    end

    def parse(file) when is_binary(file) do
      file
      |> File.read!()
      |> String.trim_leading()
      |> Tokenizer.tokenize([])
      |> parse([])
    end

    def parse([{:integer, value} | tokens]) do
      {{:integer, String.to_integer(value)}, tokens}
    end

    def parse([{:identifier, id} | [{:oparen, _} | rest]]) do
      {args, rest} = parse_args(rest, [])

      {{:call, {id, args}}, rest}
    end

    def parse([{:identifier, id} | rest]) do
      {{:var, id}, rest}
    end

    def parse_args([{:cparen, _} | rest], args), do: {Enum.reverse(args), rest}

    def parse_args([{:comma, _} | rest], args) do
      parse_args(rest, args)
    end

    def parse_args(tokens, args) do
      {arg, rest} = parse(tokens)

      parse_args(rest, [arg | args])
    end
  end

  defmodule Layout.Macros do
    defmacro lt(layer, keycode) do
      quote do
        {:call, {"LT", [{:integer, unquote(layer)}, {:var, unquote(keycode)}]}}
      end
    end

    defmacro key(key) do
      quote do
        {:var, unquote(key)}
      end
    end
  end

  defmodule Renderer do
    import Layout.Macros
    require Layout.Macros

    def pad(<<kc::binary-size(4)>>), do: " " <> kc
    def pad(<<kc::binary-size(3)>>), do: " " <> kc <> " "
    def pad(<<kc::binary-size(2)>>), do: "  " <> kc <> " "
    def pad(<<kc::binary-size(1)>>), do: "  " <> kc <> "  "
    def pad(key), do: String.pad_leading(key, 5, " ")

    def layer_template(name, left_keys, right_keys) do
      row_mapper = fn keys ->
        {headers, keys} =
          Enum.map(keys, fn
            lt(layer, "KC_" <> kc) ->
              {
                "#define KC_LS#{layer - 7}_#{kc} LT(ASETNIOP#{layer - 7}, KC_#{kc})\n",
                "LS#{layer - 7}_#{kc}"
              }

            key("KC_TRANSPARENT") ->
              ""

            key("KC_" <> key) ->
              key
          end)
          |> Enum.map(fn
            {header, kc} -> {header, pad(kc)}
            other -> {"", pad(other)}
          end)
          |> Enum.unzip()

        {Enum.join(headers), Enum.join(keys, ",")}
      end

      {left_headers, left_row} = row_mapper.(left_keys)
      {right_headers, right_row} = row_mapper.(right_keys)

      """
      #{left_headers}#{right_headers}  [#{name}] = LAYOUT_kc(
        //,-----------------------------------.                    ,-----------------------------------.
                ,#{      left_row      },     ,                          ,#{     right_row      },     ,
        //|-----+-----+-----+-----+-----+-----|                    |-----+-----+-----+-----+-----+-----|
                ,     ,     ,     ,     ,     ,                          ,     ,     ,     ,     ,     ,
        //|-----+-----+-----+-----+-----+-----|                    |-----+-----+-----+-----+-----+-----|
                ,     ,     ,     ,     ,     ,                          ,     ,     ,     ,     ,     ,
        //|-----+-----+-----+-----+-----+-----+-----|  |-----+-----+-----+-----+-----+-----+-----+-----|
                                        ,     ,     ,        ,     ,
                                //`-----------------'  `-----------------'
        ),
      """
    end
  end

  def load(file) do
    Parser.parse(file)
  end

  def at({:call, {"LAYOUT" <> _, args}}, index), do: args |> Enum.at(index)

  def key({:var, key}), do: key
  def key({:call, {"LT", [{:integer, _layer}, {:var, key}]}}), do: key
  def key({:call, {"LAYOUT" <> _, _}} = layout, index), do: layout |> at(index) |> key()

  def layer({:call, {"LT", [{:integer, layer}, {:var, _key}]}}), do: layer - 7
  def layer({:call, {"LAYOUTS", args}}, index), do: Enum.at(args, index)
  def layer({:call, {"LAYOUT" <> _, _}} = layout, index), do: layout |> at(index) |> layer()

  def lt?({:call, {"LT", [{:integer, _layer}, {:var, _key}]}}), do: true
  def lt?(_), do: false
  def lt?({:call, {"LAYOUT" <> _, _}} = layout, index), do: layout |> at(index) |> lt?()
end
