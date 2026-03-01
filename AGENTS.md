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
| `FuturePlans/` | Plans for features not yet implemented |
| `DebarcodeR_v1.1.0_update_summary.md` | Collaborator-facing summary of all v1.1.0 changes |

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
-   **Git:** `devel-2026` is 134 commits ahead of `cytolab/DebarcodeR:master`. All substantive upstream changes are already incorporated. Merge plan in `FuturePlans/plan_gitmerge.md`.
-   **Force push still needed:** After `git filter-repo` rewrote history to remove `.positai/` and `..Rcheck/`, a `git push --force origin devel-2026` is required to sync with GitHub.

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

## Channel Name Handling (Important)

All pipeline functions use **original FCS channel names** (e.g. `"Pacific Blue-A"`). Cleaned/janitor-style names (e.g. `"pacific_blue_a"`) are accepted as **input** with a deprecation warning via `resolve_channel()`, but results are **stored** under the original name. This means:

- `deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a", ...)` — works, emits warning
- `get_barcode_data(fcb, "pacific_blue_a", ...)` — returns `NULL` (key is `"Pacific Blue-A"`)
- `getAssignments(fcb)[["pacific_blue_a"]]` — returns `NULL` (key is `"Pacific Blue-A"`)

**Always use original FCS names for retrieval.**

The `_flow_helpers.R` wrappers (`debarcode_sample()`, `split_by_assignments()`) and `_params.R` in the notebook directory have been updated to use original FCS names.

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
- All 21 exported man pages have runnable examples (100%)
- Fixed `plot.fcbflowframe` → `plot.fcbFlowFrame` S3 dispatch case mismatch

### Code Style Cleanup

- Fixed all `1:n` → `seq_len(n)` in `doRegressContrained.R`
- Fixed `=` → `<-` assignment in `doRegressContrained.R`
- Fixed MATLAB-style indexing `b(noc+1)` → `b[noc + 1, 1]` in `doRegressContrained.R`
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

### Session: 2026-03-01

-   **`_flow_helpers.R` updated:** `debarcode_sample()` and `split_by_assignments()` now use original FCS channel names (`"Pacific Blue-A"`, `"FSC-A"`, etc.) and the explicit `fcbFlowFrame()` constructor. Located at `Notebook/2026/02_2026/_flow_helpers.R`.
-   **`_params.R` updated:** `debarcode_channel` and `debarcode_predictors` updated to original FCS names. Located at `Notebook/2026/02_2026/20260219_BAXBAKKO_Timecourse_Conv/_params.R`.
-   **`20260219_FlowCytAnalysis_v2.qmd` created:** Updated analysis script using `get_barcode_data()` and `exprs()` accessors instead of direct `@barcodes`/`@exprs` slot access, and correct channel names.
-   **`NEWS.md` rewritten:** Structured changelog with New Features, API Changes, Bioconductor Compliance, Bug Fixes, Known Issues sections.
-   **`DebarcodeR_v1.1.0_update_summary.md` created:** Collaborator-facing prose summary of all v1.1.0 changes.
-   **Git history cleaned:** `git filter-repo` removed `.positai/` and `..Rcheck/` (which contained absolute filesystem paths) from all historical commits. **Force push still needed.**
-   **`.gitignore` updated:** Added `..Rcheck/` and `.positai/` patterns.
-   **`FuturePlans/` created:** Added to `.Rbuildignore`. Contains:
    -   `plan_debarcode_wrapper.md` — plan for a `debarcode()` convenience function
    -   `plan_gitmerge.md` — plan for merging `devel-2026` into `cytolab/DebarcodeR:master`

### Project Cleanup

-   Removed completed plan/handoff files from project root: `PLAN.md`, `plan_bioconductor`, `plan_bioc_deexport.md`, `handoff.md`, `handoff_bioc.md`, `README.html`, `README_files/`
-   Updated `.gitignore`: added `*.tar.gz`, `*.Rcheck/`, `*.BiocCheck/`, `..Rcheck/`, `.positai/`, `test_fcs/`
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

Two bugs on one line: `$objective` → `$minimum`; search interval `c(0, 1e-4)` → `c(0, max(z_d))`. Only affects the Knijnenburg deskewing method — earth/lm methods are unaffected.

### S3 dispatch for `plot()`

`plot(fcbFlowFrame_object)` dispatches to flowCore's S4 `plot,flowFrame-method` instead of `plot.fcbFlowFrame`. Workaround: call `plot.fcbFlowFrame()` explicitly.

------------------------------------------------------------------------

## Remaining Work (Ordered)

1.  **Force push to GitHub** — `git push --force origin devel-2026` (after filter-repo history rewrite)
2.  **Knijnenburg bug fix** — `selectDenseScatterArea.R` line 43 (`plan_knijnenburg.md`)
3.  **`debarcode()` convenience wrapper** — single-call deskew → cluster → assign function (`FuturePlans/plan_debarcode_wrapper.md`)
4.  **Merge to cytolab/master** — PR from `devel-2026` → `cytolab/DebarcodeR:master` (`FuturePlans/plan_gitmerge.md`)
5.  **Phase 5** — GatingSet support
6.  **Shiny GUI enhancements:**
    -   EM optimize step (optional accordion panel between Assign and Export)
    -   Platemap upload + `apply_platemap()` in Export panel
    -   Batch mode (multiple FCS files / flowSet)
    -   Smoke tests for app construction

------------------------------------------------------------------------

## Convention

After every implementation step: 1. `devtools::test()` — all tests pass 2. `rcmdcheck::rcmdcheck(".", args = "--no-manual")` — no new errors/warnings *(Note: `devtools::check()` hits a sandbox restriction in the AI assistant; use `rcmdcheck` directly)* 3. `git commit -m "<message>"`

For BiocCheck: `Rscript -e 'BiocCheck::BiocCheck("DebarcodeR_1.1.0.tar.gz")'` from the project root (after `R CMD build .`).
