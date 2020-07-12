Code.compile_file("parser.ex")
layouts = Layout.load("keymap.c") |> hd()

Enum.each(0..8, fn i ->
  layer = Layout.at(layouts, i)

  Layout.Renderer.layer_template(
    "ASETNIOP#{i}",
    Enum.map(15..18, fn index -> Layout.at(layer, index) end),
    Enum.map(53..56, fn index -> Layout.at(layer, index) end)
  )
  |> IO.puts()
end)
