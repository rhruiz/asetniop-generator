Code.compile_file("layout.ex")
layouts = Layout.load("keymap.c") |> hd()

Enum.each(0..8, fn i ->
  layer = Layout.at(layouts, i)

  Layout.Renderer.render(
    "ASETNIOP#{i}",
    Enum.map(15..18, fn index -> Layout.at(layer, index) end),
    Enum.map(53..56, fn index -> Layout.at(layer, index) end),
    &Layout.Renderer.wrapper_template/5
  )
  |> IO.puts()
end)
