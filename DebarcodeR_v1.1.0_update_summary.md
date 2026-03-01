---
---
---

# DebarcodeR v1.1.0 — Update Summary

**Date:** February 28, 2026 **Branch:** `devel-2026` (from `master` / v1.0.0) **Scope:** 51 commits, 109 files changed, \~6,000 lines added / \~3,000 removed

------------------------------------------------------------------------

## Overview

This release modernizes DebarcodeR for Bioconductor submission and adds several user-facing features. The core debarcoding algorithm is unchanged — most of the work went into improving the API surface, adding documentation, ensuring compatibility with the Cytoverse ecosystem (cytoframe/cytoset), and building an interactive Shiny GUI. The package passes `R CMD check` with 0 errors, 0 warnings, and 0 notes.

------------------------------------------------------------------------

## New Features

### Interactive Shiny GUI

`run_debarcoder()` launches a wizard-style Shiny app (built with `bslib`) that walks users through the full debarcoding pipeline:

-   **Two input modes:** upload FCS files, or pass R objects directly from the console (`run_debarcoder(data = my_ff, uptake = my_std)`)
-   **Diagnostic visualizations** at each step: scatter plots (raw → deskewed → assignment-colored), histograms with cluster-level coloring, summary table with cell counts per well
-   **Reproducible code generation:** a "Generated Code" tab builds a copy-paste-ready R script as the user tunes parameters, using the caller's actual variable names
-   **Progressive disclosure:** accordion panels unlock sequentially (Load Data → Configure Channels → Deskew → Cluster → Assign → Export)

### Cytoframe / Cytoset Support

The constructors `fcbFlowFrame()` and `fcbFlowSet()`, along with `deskew_fcbFlowFrame()` and `deskew_fcbFlowSet()`, now accept `cytoframe` and `cytoset` objects in addition to `flowFrame` and `flowSet`. Input is automatically coerced as needed, so the package integrates cleanly into `flowWorkspace`-based pipelines.

### Tutorial Vignette

A full pipeline tutorial (`vignettes/debarcoder-tutorial.Rmd`) now ships with the package. All code chunks run live (`eval = TRUE`) on the bundled `jurkatFCB` dataset — no pre-computed data. The vignette walks through deskewing, clustering, EM optimization, assignment, splitting, and platemap application.

### External Standard Dataset

`jurkatFCB_std` — a single-well subset of `jurkatFCB` (row 1, column 1) — is now included as a package dataset for use as the uptake standard in examples and the vignette.

### Public Barcode Data Accessor

`get_barcode_data(fcbFF, channel, step, field)` is the new exported accessor for reading pipeline results from the `@barcodes` slot. This replaces direct `@barcodes` slot access, which is still possible but no longer recommended.

### Assignment Visualization

`plot.fcbFlowFrame()` is a new S3 method that produces diagnostic scatter plots colored by barcode assignment, with before/after deskewing panels.

------------------------------------------------------------------------

## API Changes

### Channel name handling

All pipeline functions now use **original FCS channel names** (e.g. `"Pacific Blue-A"`) internally. Cleaned/janitor-style names (e.g. `"pacific_blue_a"`) are still accepted as **input** to pipeline functions via a soft deprecation in `resolve_channel()` — the cleaned name is resolved to the original with a warning, so existing deskew/cluster/assign calls continue to work.

However, results are **stored** under the original name. This means code that indexes into `getAssignments()` output or `get_barcode_data()` by cleaned name (e.g. `getAssignments(fcb)[["pacific_blue_a"]]`) will silently return `NULL`. These retrieval calls need to be updated to use the original FCS name (e.g. `"Pacific Blue-A"`).

### Removed exports

| Function         | Replacement                               |
|------------------|-------------------------------------------|
| `as.flowFrame()` | `as(x, "flowFrame")`                      |
| `as.cytoframe()` | `flowWorkspace::flowFrame_to_cytoframe()` |
| `as.cytoset()`   | `flowWorkspace::flowSet_to_cytoset()`     |

These conversion wrappers were deleted entirely to avoid method dispatch conflicts with flowCore.

### De-exported (now internal)

The following functions are still in the package but no longer part of the public API:

-   `morphology_corr.earth()`, `morphology_corr.lm()`, `morphology_corr.knijnenburg()`, `morphology_corr.master()`
-   `calculate.ambiguity()`, `calculate.likelihood()`
-   5 Knijnenburg helper functions in `selectDenseScatterArea.R`

### New exports

| Function              | Purpose                                 |
|-----------------------|-----------------------------------------|
| `get_barcode_data()`  | Read-only accessor for `@barcodes` slot |
| `plot.fcbFlowFrame()` | Assignment visualization                |
| `run_debarcoder()`    | Interactive Shiny GUI                   |
| `show(fcbFlowFrame)`  | S4 display method                       |

------------------------------------------------------------------------

## Code Quality & Bioconductor Compliance

-   **Data subsampled:** `jurkatFCB` reduced from 191k cells to 24k (500 cells/well × 48 wells), xz compressed. Tarball size is \~2.4 MB (under the 5 MB Bioc limit).
-   **All 21 exported man pages** have runnable `@examples` sections.
-   **`R CMD check`:** 0 errors, 0 warnings, 0 notes.
-   **`BiocCheck`:** 1 ERROR (support site registration — account issue, not code), 1 WARNING (odd version number — expected for devel), 6 cosmetic NOTEs (function lengths, line lengths, indentation, etc.).
-   **Style cleanup:** `styler::style_pkg()` applied package-wide with 4-space indent; `1:n` → `seq_len(n)`; `class(x) == "y"` → `inherits(x, "y")`; `cat()` → `message()`.
-   **Test suite:** 11 test files covering the full pipeline, including cytoframe/cytoset paths.
-   **`inst/CITATION`** added with the Cytometry A reference.

------------------------------------------------------------------------

## Bug Fixes

| Bug | Fix |
|------------------------------------|------------------------------------|
| `doRegressContrained.R`: MATLAB-style indexing `b(noc+1)` | Corrected to `b[noc + 1, 1]` |
| `apply_platemap`: `pData` column name mismatch when joining with platemap | Column names now cleaned with `janitor::make_clean_names()` before join |
| `plot.fcbflowframe` (lowercase) not dispatching as S3 method | Renamed to `plot.fcbFlowFrame` to match class name |

------------------------------------------------------------------------

## Known Issues

1.  **`selectDenseScatterArea.R` line 43** — Two bugs on one line in the Knijnenburg method: `$objective` should be `$minimum`, and the search interval `c(0, 1e-4)` should be `c(0, max(z_d))`. Documented in `plan_knijnenburg.md`; the earth/lm methods are unaffected.

2.  **S3 dispatch for `plot()`** — Calling `plot(fcbFlowFrame_object)` dispatches to flowCore's S4 `plot,flowFrame-method` instead of `plot.fcbFlowFrame`. Workaround: call `plot.fcbFlowFrame()` explicitly. The Shiny app does this internally.

------------------------------------------------------------------------

## What's Next

1.  **Knijnenburg bug fix** — `selectDenseScatterArea.R` line 43
2.  **GatingSet support** — Accept and return GatingSet objects in the pipeline
3.  **`debarcode()` convenience wrapper** — Single-call function for the common deskew → cluster → assign pipeline (plan drafted in `FuturePlans/`)
4.  **Shiny GUI enhancements** — EM optimize step, platemap upload, batch mode, smoke tests
