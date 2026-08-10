; Templates are the only named, reusable unit in the language, so they are what the outline is
; for — a 465-line view file is a handful of templates plus one root view.
((element
  (start_tag
    (structure_tag) @context
    (attribute
      (plain_attribute
        name: (attribute_name) @_attr
        (attribute_text) @name))))
  (#eq? @context "template")
  (#eq? @_attr "name")) @item

; Structure tags carry the shape of the view; plain elements would drown it.
((element
  (start_tag
    (structure_tag) @name))
  (#any-of? @name "for" "if" "else" "use" "import")) @item
