# DebarcodeR — Agent Handoff

**Date:** 2026-02-28  
**Branch:** `devel-2026`  
**Last commit:** `e7e00c3` — "docs: modernize README"  
**R CMD check status:** 0 errors, 0 warnings (code), 0 notes  
*(1 pre-existing WARNING about `jurkatFCB.rda` compression — run `R CMD build --resave-data` to resolve; not a code issue)*

---

## What This Package Does

DebarcodeR (Reisman et al., Cytometry A, 2021) demultiplexes fluorescent cell barcoded
(FCB) flow cytometry data. The pipeline per barcoding channel is:

1. **Deskew** (`deskew_fcbFlowFrame`) — MARS/linear regression corrects for differential dye uptake using scatter/morphology channels as predictors
2. **Cluster** (`cluster_fcbFlowFrame`) — GMM or Jenks natural breaks estimates per-cell probability of belonging to each barcoding level
3. **Assign** (`assign_fcbFlowFrame`) — ambiguity and likelihood cutoffs discretely assign cells to samples
4. **EM optimize** (`em_optimize`, optional) — multivariate GMM refines assignments across channels

Output is an `fcbFlowSet` (subclass of `flowSet`) split by well assignment, compatible with the flowCore/Cytoverse ecosystem.

---

## Completed Work

### Phase 1 — Installable & Testable ✅
- Fixed DESCRIPTION, dependencies, class checking, deprecated patterns
- Built test suite (11 test files in `tests/testthat/`)

### Phase 2 — cytoframe/cytoset Support ✅
- `fcbFlowFrame()` and `fcbFlowSet()` constructors accept `cytoframe`/`cytoset`
- `deskew_fcbFlowFrame()` / `deskew_fcbFlowSet()` accept `cytoframe`/`cytoset`
- `as.cytoframe()` / `as.cytoset()` conversion methods added
- `flowWorkspace` in `Suggests:` (optional)

### Phase 4 — Code Quality ✅ (all 8 steps)
- **4.1** Use original channel names (e.g. `"Pacific Blue-A"` not `"pacific_blue_a"`); cleaned names still accepted with deprecation warning via `resolve_channel()` in `R/utils-validation.R`
- **4.2** Replaced custom `match.arg1` with `base::match.arg()`
- **4.3** Extracted `get_barcode_data()` / `set_barcode_data()` helpers into `R/utils-barcode-slots.R`
- **4.4** Extracted `compute_histogram_probs()` helper; `fisher` and `manual.breaks` branches in `cluster_fcbFlowFrame` share the logic
- **4.5** Extracted `split_by_assignments()` helper; `fcbFlowFrame` and `flowFrame` split methods both delegate to it
- **4.6** Added `assert_fcbFlowFrame()` and `coerce_to_flowFrame()` to `R/utils-validation.R`; removed inline validation blocks across 5 files. Also fixed a latent bug in `doRegressContrained.R`: `b(noc+1)` (MATLAB-style function-call indexing) was corrected to `b[noc+1, 1]`
- **4.7** Replaced `cat()` with `message()` in `em_optimize.R`; added `show()` S4 method for `fcbFlowFrame`
- **4.8** Added missing `@importFrom` directives for base R functions; fixed `plot.fcbflowframe` S3 method signature/markup

### Phase 3 — Documentation ✅ (all 3 steps)
- **3.1** Added `@examples` to all exported functions (`\dontrun{}` for pipeline steps, runnable for standalone utilities); added `@seealso` cross-references between all pipeline steps; fixed typos in `cluster_fcbFlowFrame`/`cluster_fcbFlowSet` param docs (`specifiy`, `exlcude`, `originaiting`, `distrubtion`, etc.); rewrote several terse `@param` descriptions with accurate defaults. Commit: `8d0cfd9`
- **3.2** Created `vignettes/debarcoder-tutorial.Rmd` — complete pipeline walkthrough using original FCS channel names (`"Pacific Blue-A"`, `"FSC-A"`, etc.); added `VignetteBuilder: knitr` to DESCRIPTION; all code chunks use `eval = FALSE` so the vignette builds instantly. Commit: `2268065`
- **3.3** Rewrote README: concise overview, quick-start block, pipeline reference table, modernized installation instructions, all channel names updated to original FCS format, links to vignette for the detailed walkthrough. Commit: `e7e00c3`

---

## Currently In Progress

**Nothing.** All planned phases (1, 2, 3, 4) are complete.

---

## Known Bugs (Separate Plan — Not Yet Fixed)

See `plan_knijnenburg.md` in the project root.

### `selectDenseScatterArea.R` line 43 — two bugs on one line

```r
# Current (wrong):
tmin <- optimize(ft, c(0, 1e-4), tol = 1e-9)$objective

# Correct:
tmin <- optimize(ft, c(0, max(z_d)), tol = 1e-9)$minimum
```

1. `$objective` returns the function value at the minimum (~0), not the threshold `t` itself — should be `$minimum`
2. The search interval `c(0, 1e-4)` is too narrow; peak KDE densities on a normalized 256×256 grid can exceed `1e-4`

**Effect:** The density filter in `selectDenseScatterArea` does not actually filter — all grid points are returned regardless of density. The weighted regression still produces reasonable results due to density weighting, but the spatial selection of the 95% contour is broken.

**Fix + test plan** is fully documented in `plan_knijnenburg.md`.

---

## Key Files

| File | Purpose |
|---|---|
| `R/deskew_fcbFlowFrame.R` | Pipeline step 1 entry point |
| `R/cluster_fcbFlowFrame.R` | Pipeline step 2; contains `compute_histogram_probs()` |
| `R/assign_fcbFlowFrame.R` | Pipeline step 3; also contains `calculate.ambiguity()` / `calculate.likelihood()` |
| `R/em_optimize.R` | Optional multivariate EM refinement |
| `R/split_fcbFlowFrame.R` | Split assigned data; contains `split_by_assignments()` |
| `R/getAssignments.R` | Extract discrete assignments from barcodes slot |
| `R/apply_platemap.R` | Map level combinations to well names, rename flowFrames |
| `R/utils-barcode-slots.R` | `get_barcode_data()`, `set_barcode_data()` |
| `R/utils-validation.R` | `resolve_channel()`, `assert_fcbFlowFrame()`, `coerce_to_flowFrame()` |
| `R/fcbFlowFrame.R` | S4 class definition, constructor, `show()` method |
| `R/fcbFlowSet.R` | S4 class definition and constructor |
| `R/doRegressContrained.R` | Knijnenburg constrained regression (internal) |
| `R/selectDenseScatterArea.R` | Knijnenburg dense scatter area **(has the bug above)** |
| `R/morphology_corr_knignenburg.R` | Knijnenburg entry point wrapper |
| `vignettes/debarcoder-tutorial.Rmd` | Full pipeline tutorial (eval = FALSE; run interactively) |
| `tests/testthat/` | 11 test files + `setup.R` |
| `PLAN.md` | Full phased modernization plan |
| `plan_knijnenburg.md` | Specific bug fix plan for Knijnenburg method |

## Convention

After every implementation step:
1. `devtools::test()` — all tests pass
2. `rcmdcheck::rcmdcheck(".", args = "--no-manual")` — no new errors or warnings  
   *(Note: `devtools::check()` hits a sandbox restriction in the RStudio AI assistant environment; use `rcmdcheck` directly instead)*
3. `git commit -m "<message>"` with the message specified in the plan

## Remaining Phases

- **Knijnenburg bug fix** — `selectDenseScatterArea.R` line 43 (see `plan_knijnenburg.md` — fully planned, ready to implement)
- **Phase 5** — GatingSet support (accept `GatingSet` input, preserve gating hierarchy)
- **Phase 6** — Shiny GUI (`run_debarcoder()` function, `bslib` layout)
