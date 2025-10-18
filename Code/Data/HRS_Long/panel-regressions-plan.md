<!-- 242fc389-648c-4003-89d4-eb949d9c5727 3cbe7423-0dfd-401c-a6da-6d0a38e44ce5 -->
# Panel Dataset and Regression Analysis Plan

## Phase 1: Create Panel Dataset (reg_ret_panel.do)

**Objective**: Convert wide dataset to long format with all computed variables

**Implementation**:
1. Load `_randhrs1992_2022v1_analysis.dta`
2. Keep only variables needed:
   - Return variables: `r_annual_*`, `r_annual_trim_*`, `r_annual_excl_*`, `r_annual_excl_trim_*`
   - All variables with `_YYYY` pattern (2000-2022): asset shares, liability shares, wealth variables, etc.
3. Reshape to long format - **CRITICAL FIX**:
   - First reshape return variables: `reshape long r_annual_ r_annual_trim_ r_annual_excl_ r_annual_excl_trim_, i(hhidpn) j(year)`
   - Then reshape ALL other `_YYYY` variables systematically:
     - Asset shares: `reshape long share_pri_res_ share_sec_res_ share_re_ share_vehicles_ share_bus_ share_ira_ share_stk_ share_chck_ share_cd_ share_bond_ share_other_ risky_share_, i(hhidpn) j(year)`
     - Liability shares: `reshape long liability_share_, i(hhidpn) j(year)`
     - Wealth variables: `reshape long wealth_nonres_ wealth_nonres_decile_, i(hhidpn) j(year)`
     - Wealth deciles: `reshape long wealth_d1_ wealth_d2_ wealth_d3_ wealth_d4_ wealth_d5_ wealth_d6_ wealth_d7_ wealth_d8_ wealth_d9_ wealth_d10_, i(hhidpn) j(year)`
     - Demographics: `reshape long r15agey_b raedyrs r15inlbrf married_ born_us_, i(hhidpn) j(year)`
4. Create year dummies: `tab year, gen(year_)`
5. Set panel structure: `xtset hhidpn year`
6. Save as `_randhrs1992_2022v1_panel.dta`

**Key files**: `reg_ret_panel.do`

---

## Phase 2: Regression Set 1 - Baseline Pooled OLS

**Objective**: Baseline regressions with demographics and wealth controls

**Specification**:
```stata
reg r_annual age age_sq i.education i.married i.born_us i.employment i.wealth_d2-i.wealth_d10 i.year, robust cluster(hhidpn)
```

**Controls (RHS)**:
- Age and age² (continuous)
- Education (categorical)
- Marital status (binary)
- Immigration status (born_us binary)
- Employment status (categorical)
- Wealth deciles (d2-d10, omit d1 as reference)
- Year dummies (time fixed effects)

**Run for each dependent variable**: `r_annual`, `r_annual_trim`, `r_annual_excl`, `r_annual_excl_trim`

**Output**: Regression table with coefficients, standard errors, N, R²

**Key files**: Create `reg_baseline_pooled.do`

---

## Phase 2: Regression Set 2 - Asset Shares Interacted with Years

**Objective**: Test whether asset share effects vary over time

**Specification**:
```stata
reg r_annual age age_sq i.education i.married i.born_us i.employment i.wealth_d2-i.wealth_d10 ///
    c.share_stk##i.year c.share_bond##i.year c.share_re##i.year c.share_ira##i.year c.share_bus##i.year ///
    liability_share, robust cluster(hhidpn)
```

**Why this specification**:
- **Asset shares interacted with year**: Tests if return premium to holding stocks (vs bonds/cash) varies across time periods (e.g., bull vs bear markets)
- **Year dummies still included**: Yes, through the interaction terms. Stata automatically includes main effects when you use `##` (full factorial)
- **Time fixed effects**: Year dummies capture time-specific shocks (market crashes, policy changes, etc.)

**Controls (RHS)**:
- Same baseline controls as Regression 1
- Asset shares × year interactions:
  - `share_stk × year` (stock share interacted with each year)
  - `share_bond × year`
  - `share_re × year` (real estate)
  - `share_ira × year`
  - `share_bus × year` (business, many zeros expected)
- Liability share (continuous, not interacted)

**Joint equality tests**: After each regression, test:
```stata
test 2020.year#c.share_stk 2018.year#c.share_stk 2016.year#c.share_stk ... [all years]
```
This tests whether the stock share coefficient is constant across all years.

**Run for each dependent variable**: `r_annual`, `r_annual_trim`, `r_annual_excl`, `r_annual_excl_trim`

**Output**: 
- Regression table with interaction coefficients
- Joint F-test results for each asset share

**Key files**: Create `reg_shares_interacted.do`

---

## Phase 3: Regression Set 3 - Individual Fixed Effects

**Objective**: Control for time-invariant individual heterogeneity

**Specification**:
```stata
xtreg r_annual age age_sq i.education i.married i.employment risky_share i.year, fe robust cluster(hhidpn)
```

**Note on age with FE**: You said "if age is included we can't have individual FE" but actually we CAN include age with individual FE because age varies within individuals over time. What drops out with individual FE are time-invariant characteristics (like education, birth place). However, since you requested age, education, marital, employment, I'll include them - Stata will automatically drop time-invariant ones.

**Controls (RHS)**:
- Age and age² (varies within person over time - RETAINED)
- Education (time-invariant - DROPPED by xtreg, fe)
- Marital status (can vary over time - RETAINED)
- Immigration status (time-invariant - DROPPED)
- Employment status (can vary over time - RETAINED)
- Wealth deciles (DROPPED - individual FE captures wealth effects)
- Risky share (varies over time - RETAINED)
- Year dummies (time fixed effects - RETAINED)
- Individual fixed effects (implicit via `fe` option)

**Run for each dependent variable**: `r_annual`, `r_annual_trim`, `r_annual_excl`, `r_annual_excl_trim`

**Output**: Regression table with within-R², between-R², overall-R²

**Key files**: Create `reg_fixed_effects.do`

---

## Summary of Differences

| Aspect | Regression 1 | Regression 2 | Regression 3 |
|--------|-------------|--------------|--------------|
| **Estimation** | Pooled OLS | Pooled OLS | Individual FE |
| **Asset shares** | No | Yes (interacted with year) | Only risky_share |
| **Liability share** | No | Yes | No |
| **Wealth deciles** | Yes | Yes | No (absorbed by FE) |
| **Time-invariant controls** | Included | Included | Dropped by FE |
| **Year dummies** | Yes | Yes (through interactions) | Yes |



### To-dos

- [ ] **CRITICAL FIX**: Update reg_ret_panel.do to properly reshape ALL _YYYY variables to long format, not just returns. Need systematic reshaping of asset shares, liability shares, wealth variables, demographics, etc.
- [ ] Create reg_baseline_pooled.do with baseline controls and run for all 4 return measures
- [ ] Create reg_shares_interacted.do with asset shares × year interactions, include joint F-tests
- [ ] Create reg_fixed_effects.do with individual FE and risky_share
