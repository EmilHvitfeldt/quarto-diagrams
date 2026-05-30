function Meta(m)
  if quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "diagrams",
      version = "0.2.0",
      stylesheets = { "diagrams.css" }
    })
    quarto.doc.include_file("after-body", "diagrams.html")
  end
  return m
end
