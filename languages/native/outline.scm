; Templates by name.
((element
  (start_tag
    (structure_tag) @context
    (attribute
      (plain_attribute
        name: (attribute_name) @_attr
        (attribute_text) @name))))
  (#eq? @context "template")
  (#eq? @_attr "name")) @item

; Structure tags only. Every element would be noise.
((element
  (start_tag
    (structure_tag) @name))
  (#any-of? @name "for" "if" "else" "use" "import")) @item
