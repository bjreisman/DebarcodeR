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
| `R/utils-barcode-slots.R` | `get_barcode_data()` (exported), `set_barcode_data()` (internal) |
| `R/utils-validation.R` | `resolve_channel()`, `assert_fcbFlowFrame()`, `coerce_to_flowFrame()` |
| `R/selectDenseScatterArea.R` | Knijnenburg dense scatter (has known bug — see `plan_knijnenburg.md`) |
| `R/plot-fcbFlowFrame-assignments.R` | `plot.fcbFlowFrame()` S3 method for assignment visualization |
| `R/run_debarcoder.R` | Shiny GUI (`run_debarcoder()`) — UI, server, and code generation |
| `vignettes/debarcoder-tutorial.Rmd` | Full pipeline tutorial — runs live (`eval=TRUE`) on `jurkatFCB` |
| `tests/testthat/` | 11 test files + `setup.R` |

------------------------------------------------------------------------

## Data

| Dataset | File | Description |
|----|----|----|
| `jurkatFCB` | `data/jurkatFCB.rda` | 24,000 cells (500/well × 48 wells), 16 channels, xz compressed (~1.6 MB) |
| `jurkatFCB_std` | `data/jurkatFCB_std.rda` | 500 cells (row 1, col 1 of jurkatFCB), external standard |

**Important:** `jurkatFCB` was subsampled from the original 191k-cell dataset to 500 cells/well to meet Bioconductor's 5 MB tarball limit. The tarball is currently ~2.4 MB.

Barcoding channels: `"Pacific Blue-A"` (8 levels), `"Pacific Orange-A"` (6 levels), `"APC-H7-A"` (internal standard, 1 level). Total: 48 wells.

Loading:

``` r
data("jurkatFCB")
data("jurkatFCB_std")
```

------------------------------------------------------------------------

## Branches & Status

-   **`devel-2026`** — Main development branch (core pipeline + Shiny GUI)
-   **Version:** 1.1.0 (odd y = devel, correct for Bioc submission)
-   **R CMD check:** 0 errors, 0 warnings, 0 notes (as of last run)
-   **BiocCheck:** 1 ERROR (support site registration — account issue, not code), 1 WARNING (odd version — expected for devel), 6 NOTEs (cosmetic: function lengths, line lengths, indentation, suppressMessages, mailing list, funder role)

------------------------------------------------------------------------

## Exported API (21 man pages, all with runnable examples)

| Function | Type |
|---|---|
| `fcbFlowFrame` | Constructor |
| `fcbFlowSet` | Constructor |
| `deskew_fcbFlowFrame` / `deskew_fcbFlowSet` | Pipeline step 1 |
| `cluster_fcbFlowFrame` / `cluster_fcbFlowSet` | Pipeline step 2 |
| `assign_fcbFlowFrame` / `assign_fcbFlowSet` | Pipeline step 3 |
| `em_optimize` | Pipeline step 4 |
| `getAssignments` | Result extraction |
| `split` methods (3 signatures) | Convert to flowSet |
| `apply_platemap` | Post-processing |
| `get_barcode_data` | Read-only accessor for barcodes slot |
| `plot.fcbFlowFrame` | Visualization (S3 method) |
| `run_debarcoder` | Interactive Shiny GUI |
| `show` (fcbFlowFrame) | S4 display |
| `jurkatFCB` / `jurkatFCB_std` | Datasets |

**De-exported / deleted:**
- `as.flowFrame`, `as.cytoframe`, `as.cytoset` — **deleted entirely** (use `as(x, "flowFrame")` or `flowWorkspace::flowFrame_to_cytoframe()`)
- `morphology_corr` (×4), `calculate.ambiguity`, `calculate.likelihood` — `@keywords internal`
- 5 Knijnenburg helpers — `@keywords internal`

------------------------------------------------------------------------

## Completed Work

### Phases 1–4 (prior sessions)

-   Installable & testable; 11 test files
-   cytoframe/cytoset support in constructors and deskew
-   Code quality: channel name handling, `match.arg`, helpers extracted, `cat()` → `message()`, `show()` S4 method
-   Documentation: `@examples`, `@seealso`, vignette, README

### BiocCheck / Bioconductor Readiness

-   **Data subsampled:** `jurkatFCB` → 500 cells/well (24k total), xz compressed; `jurkatFCB_std` re-derived
-   **Vignette rewritten:** now `eval=TRUE` throughout; all plots generated live; `vignettes/data/` pre-computed data removed
-   **`apply_platemap` bug fixed:** `pData` column names now cleaned with `janitor::make_clean_names()` before joining with platemap
-   **`test-em-optimize.R` updated:** now uses full `jurkatFCB` (24k) with `subsample=10000` for clustering

### BiocCheck Example Compliance

- De-exported 6 functions, deleted 3 conversion wrappers, marked 5 Knijnenburg helpers internal
- Exported `get_barcode_data()` as public accessor; vignette uses it instead of `@barcodes`
- All 20 exported man pages have runnable examples (100%)
- Fixed `plot.fcbflowframe` → `plot.fcbFlowFrame` S3 dispatch case mismatch

### Code Style Cleanup

- Fixed all `1:n` → `seq_len(n)` in `doRegressContrained.R`
- Fixed `=` → `<-` assignment in `doRegressContrained.R`
- Ran `styler::style_pkg(".", indent_by = 4L)` — indentation NOTEs down from 29% to ~3%
- Manually wrapped long lines in `em_optimize.R`, `cluster_fcbFlowFrame.R`, `assign_fcbFlowFrame.R`, `split_fcbFlowFrame.R`, `apply_platemap.R`
- Added `DebarcodeR.BiocCheck` to `.Rbuildignore`

### Shiny GUI

-   **`run_debarcoder()`** — interactive Shiny app for the debarcoding pipeline (MVP)
-   **Wizard-style UI:** `bslib::page_sidebar()` with accordion panels that unlock progressively through 6 steps: Load Data → Configure Channels → Deskew → Cluster → Assign → Export
-   **Two input modes:**
    -   File upload: user uploads preprocessed FCS files
    -   R session: `run_debarcoder(data = my_ff, uptake = my_std)` passes objects directly, skipping file upload. Variable names captured via `deparse(substitute())` for code generation.
-   **Preprocessing requirement:** data must be compensated, transformed, and gated before entering the app. Info callout explains this in the Load Data panel.
-   **Diagnostic visualizations:** scatter plots (raw → deskewed → assignment-colored), before/after histograms with cluster-level coloring, summary table with cell counts per well
-   **Value boxes:** total cells, assigned cells, % assigned
-   **Reproducible code generation:** "Generated Code" tab builds a copy-paste-ready R script as the user tunes parameters, using the caller's actual variable names
-   **Copy-to-clipboard** button for generated code
-   **Progress feedback** via `withProgress()` wired to existing `updateProgress` callbacks
-   **Dependencies:** `shiny`, `bslib`, `bsicons` added to `Suggests`
-   **Known S3 dispatch issue:** `plot(fcb)` dispatches to flowCore's S4 `plot,flowFrame-method` instead of `plot.fcbFlowFrame`; app calls `plot.fcbFlowFrame()` explicitly as workaround

### Project Cleanup

-   Removed completed plan/handoff files from project root: `PLAN.md`, `plan_bioconductor`, `plan_bioc_deexport.md`, `handoff.md`, `handoff_bioc.md`, `README.html`, `README_files/`
-   Updated `.gitignore`: added `*.tar.gz`, `*.Rcheck/`, `*.BiocCheck/`, `test_fcs/`
-   Retained `plan_knijnenburg.md` (documents unfixed bug)

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

1.  **Knijnenburg bug fix** — `selectDenseScatterArea.R` line 43 (`plan_knijnenburg.md`)
2.  **Phase 5** — GatingSet support
3.  **Shiny GUI enhancements:**
    -   EM optimize step (optional accordion panel between Assign and Export)
    -   Platemap upload + `apply_platemap()` in Export panel
    -   Batch mode (multiple FCS files / flowSet)
    -   Smoke tests for app construction

------------------------------------------------------------------------

## Convention

After every implementation step: 1. `devtools::test()` — all tests pass 2. `rcmdcheck::rcmdcheck(".", args = "--no-manual")` — no new errors/warnings *(Note: `devtools::check()` hits a sandbox restriction in the AI assistant; use `rcmdcheck` directly)* 3. `git commit -m "<message>"`

For BiocCheck: `Rscript -e 'BiocCheck::BiocCheck("DebarcodeR_1.1.0.tar.gz")'` from the project root (after `R CMD build .`).
