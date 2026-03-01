# DebarcodeR — Project Memory

## What This Package Does

DebarcodeR (Reisman et al., Cytometry A, 2021) demultiplexes fluorescent cell barcoded (FCB) flow cytometry data. Pipeline per channel:

1.  **Deskew** (`deskew_fcbFlowFrame`) — MARS/linear regression corrects for differential dye uptake
2.  **Cluster** (`cluster_fcbFlowFrame`) — GMM or Jenks natural breaks estimates per-cell probability per barcoding level
3.  **Assign** (`assign_fcbFlowFrame`) — ambiguity and likelihood cutoffs discretely assign cells to samples
4.  **EM optimize** (`em_optimize`, optional) — multivariate GMM refines assignments across channels

Output: `fcbFlowSet` (subclass of `flowSet`) split by well assignment.

------------------------------------------------------------------------

## Key Files

| File | Purpose |
|----|----|
| `R/deskew_fcbFlowFrame.R` | Pipeline step 1 |
| `R/cluster_fcbFlowFrame.R` | Pipeline step 2 |
| `R/assign_fcbFlowFrame.R` | Pipeline step 3 |
| `R/em_optimize.R` | Optional EM refinement |
| `R/split_fcbFlowFrame.R` | Split assigned data |
| `R/getAssignments.R` | Extract discrete assignments |
| `R/apply_platemap.R` | Map level combos to well names |
| `R/fcbFlowFrame.R` | S4 class definition + constructor |
| `R/fcbFlowSet.R` | S4 class definition + constructor |
| `R/utils-barcode-slots.R` | `get_barcode_data()`, `set_barcode_data()` |
| `R/utils-validation.R` | `resolve_channel()`, `assert_fcbFlowFrame()`, `coerce_to_flowFrame()` |
| `R/selectDenseScatterArea.R` | Knijnenburg dense scatter (has known bug — see `plan_knijnenburg.md`) |
| `vignettes/debarcoder-tutorial.Rmd` | Full pipeline tutorial — runs live (`eval=TRUE`) on `jurkatFCB` |
| `tests/testthat/` | 11 test files + `setup.R` |

------------------------------------------------------------------------

## Data

| Dataset | File | Description |
|----|----|----|
| `jurkatFCB` | `data/jurkatFCB.rda` | 24,000 cells (500/well × 48 wells), 16 channels, xz compressed (\~1.6 MB) |
| `jurkatFCB_std` | `data/jurkatFCB_std.rda` | 500 cells (row 1, col 1 of jurkatFCB), external standard |

**Important:** `jurkatFCB` was subsampled from the original 191k-cell dataset to 500 cells/well to meet Bioconductor's 5 MB tarball limit. The tarball is currently \~2.4 MB.

Barcoding channels: `"Pacific Blue-A"` (8 levels), `"Pacific Orange-A"` (6 levels), `"APC-H7-A"` (internal standard, 1 level). Total: 48 wells.

Loading:

``` r
data("jurkatFCB")
data("jurkatFCB_std")
```

------------------------------------------------------------------------

## Branch & Status

-   **Branch:** `devel-2026`
-   **Version:** 1.1.0 (odd y = devel, correct for Bioc submission)
-   **R CMD check:** 0 errors, 0 warnings, 0 notes (as of last run)

------------------------------------------------------------------------

## Completed Work

### Phases 1–4 (prior sessions)

-   Installable & testable; 11 test files
-   cytoframe/cytoset support in constructors and deskew
-   Code quality: channel name handling, `match.arg`, helpers extracted, `cat()` → `message()`, `show()` S4 method
-   Documentation: `@examples`, `@seealso`, vignette, README

### BiocCheck / Bioconductor Readiness (current session)

-   **Data subsampled:** `jurkatFCB` → 500 cells/well (24k total), xz compressed; `jurkatFCB_std` re-derived
-   **Vignette rewritten:** now `eval=TRUE` throughout; all plots generated live; `vignettes/data/` pre-computed data removed
-   **`apply_platemap` bug fixed:** `pData` column names now cleaned with `janitor::make_clean_names()` before joining with platemap (was failing silently)
-   **`test-em-optimize.R` updated:** now uses full `jurkatFCB` (24k) with `subsample=10000` for clustering to avoid GMM convergence failure with sparse data
-   **BiocCheck run:** 1 ERROR (examples), 1 WARNING (version — expected), 9 NOTES

------------------------------------------------------------------------

## In Progress: BiocCheck Example Compliance

BiocCheck requires 80% of exported man pages to have runnable examples. Currently 21%. Plan documented in `plan_bioc_deexport.md`.

### Functions to de-export (9 total)

| Group | Functions |
|----|----|
| Internal dispatch | `morphology_corr`, `morphology_corr.earth`, `morphology_corr.knijnenburg`, `morphology_corr.lm` |
| Redundant wrappers | `as.flowFrame`, `as.cytoframe`, `as.cytoset` — S4 coercion and `flowWorkspace` already provide these |
| Trivial utilities | `calculate.ambiguity`, `calculate.likelihood` — 3-line internal math |

**Rationale for conversion wrappers:** `as.flowFrame` is just `as(x, "flowFrame")` (already works via S4 inheritance); `as.cytoframe`/`as.cytoset` are thin wrappers around `flowWorkspace::flowFrame_to_cytoframe()` / `flowWorkspace::flowSet_to_cytoset()`. All three define new S4 generics (Bioc guidelines discourage this).

**Kept exported:** all `*_fcbFlowSet` batch wrappers (`deskew_fcbFlowSet`, `cluster_fcbFlowSet`, `assign_fcbFlowSet`) — user convenience for multi-file workflows.

### After de-export

-   Export `get_barcode_data()` as a proper public accessor (replaces `@barcodes` slot access in vignette)
-   Unwrap `\donttest` from 9 existing examples
-   Add examples to 8 man pages that currently lack them
-   Target: 20/20 (100%) runnable examples

------------------------------------------------------------------------

## Known Bugs (Not Yet Fixed)

### `selectDenseScatterArea.R` line 43

See `plan_knijnenburg.md` for full details.

``` r
# Current (wrong):
tmin <- optimize(ft, c(0, 1e-4), tol = 1e-9)$objective

# Correct:
tmin <- optimize(ft, c(0, max(z_d)), tol = 1e-9)$minimum
```

Two bugs on one line: `$objective` → `$minimum`; search interval `c(0, 1e-4)` → `c(0, max(z_d))`.

------------------------------------------------------------------------

## Remaining Work (Ordered)

1.  **BiocCheck example compliance** — de-export 9 functions, export `get_barcode_data()`, add/unwrap examples (`plan_bioc_deexport.md`)
2.  **Knijnenburg bug fix** — `selectDenseScatterArea.R` line 43 (`plan_knijnenburg.md`)
3.  **Phase 5** — GatingSet support
4.  **Phase 6** — Shiny GUI (`run_debarcoder()`, bslib)

------------------------------------------------------------------------

## Convention

After every implementation step: 1. `devtools::test()` — all tests pass 2. `rcmdcheck::rcmdcheck(".", args = "--no-manual")` — no new errors/warnings *(Note: `devtools::check()` hits a sandbox restriction in the AI assistant; use `rcmdcheck` directly)* 3. `git commit -m "<message>"`

For BiocCheck: `Rscript -e 'BiocCheck::BiocCheck("../DebarcodeR_1.1.0.tar.gz")'` from the project root (after `R CMD build .`).
