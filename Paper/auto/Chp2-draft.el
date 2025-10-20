(TeX-add-style-hook
 "Chp2-draft"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("placeins" "section")))
   (TeX-run-style-hooks
    "latex2e"
    "Subfiles/packages"
    "article"
    "art10"
    "subfiles"
    "footnote"
    "lipsum"
    "graphicx"
    "float"
    "placeins"
    "afterpage"
    "caption"
    "subcaption"
    "booktabs"
    "threeparttable"
    "multirow"))
 :latex)

