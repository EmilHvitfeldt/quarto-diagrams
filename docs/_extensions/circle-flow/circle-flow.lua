function Meta(m)
  if quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "circle-flow",
      version = "0.1.0",
      stylesheets = { "circle-flow.css" }
    })
    quarto.doc.include_file("after-body", "circle-flow.html")
  end
  return m
end
