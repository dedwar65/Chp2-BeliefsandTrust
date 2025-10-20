(TeX-add-style-hook
 "results"
 (lambda ()
   (TeX-run-style-hooks
    "../Tables/trust_income_rv557"
    "../Tables/trust_income_pca"
    "../Tables/trust_rv557_returns"
    "../Tables/trust_pca_returns"
    "../Tables/baseline_pooled"
    "../Tables/shares_interacted"
    "../Tables/fixed_effects"
    "../Tables/trust_rv557_returns_avg"
    "../Tables/trust_pca_returns_avg")
   (LaTeX-add-labels
    "sec:results"))
 :latex)

