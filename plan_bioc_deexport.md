# BiocCheck: Reduce Exports + Add Runnable Examples

## Context

BiocCheck requires **80% of man pages for exported objects** to have runnable examples. Currently: 28 exported man pages, 6 with runnable examples = 21%.

## Strategy

De-export internal/redundant functions, then add runnable examples for those that remain.

------------------------------------------------------------------------

## Part A: Functions to de-export (9 total)

### Internal dispatch (4 pages)

| Function | File | Reason |
|----|----|----|
| `morphology_corr` | `R/morphology_corr_master.R` | Internal dispatcher; users call `deskew_fcbFlowFrame(method = ...)` |
| `morphology_corr.earth` | `R/morphology_corr_earth.R` | Internal method |
| `morphology_corr.knijnenburg` | `R/morphology_corr_knignenburg.R` | Internal method |
| `morphology_corr.lm` | `R/morphology_corr_lm.R` | Internal method |

**Action:** Replace `@export` with `@keywords internal`.

### Redundant conversion wrappers (3 pages)

| Function | File | Reason |
|----|----|----|
| `as.flowFrame` | `R/as_flowFrame.R` | Just `as(x, "flowFrame")` — S4 inheritance handles this. Defines a new generic (Bioc discourages). |
| `as.cytoframe` | `R/as_cytoframe.R` | Thin wrapper around `flowWorkspace::flowFrame_to_cytoframe()`. Defines new generic. |
| `as.cytoset` | `R/as_cytoframe.R` | Thin wrapper around `flowWorkspace::flowSet_to_cytoset()`. Defines new generic. |

**Action:** Remove `@export`, remove generic definitions, add `@keywords internal`. Remove from NAMESPACE. Update cross-references in other roxygen docs. Update `test-cytoframe.R` to use the underlying functions directly (or skip if flowWorkspace not available).

### Trivial utilities (2 pages)

| Function | File | Reason |
|----|----|----|
| `calculate.ambiguity` | `R/assign_fcbFlowFrame.R` | 3-line matrix normalization; internal to `assign_fcbFlowFrame` |
| `calculate.likelihood` | `R/assign_fcbFlowFrame.R` | 3-line matrix normalization; internal to `assign_fcbFlowFrame` |

**Action:** Replace `@export` with `@keywords internal`.

**Exported pages after de-export: 28 − 9 = 19**

------------------------------------------------------------------------

## Part B: Functions kept exported

| Function                  | Type                    |
|---------------------------|-------------------------|
| `fcbFlowFrame`            | Constructor             |
| `fcbFlowSet`              | Constructor             |
| `deskew_fcbFlowFrame`     | Pipeline step 1         |
| `deskew_fcbFlowSet`       | Pipeline step 1 (batch) |
| `cluster_fcbFlowFrame`    | Pipeline step 2         |
| `cluster_fcbFlowSet`      | Pipeline step 2 (batch) |
| `assign_fcbFlowFrame`     | Pipeline step 3         |
| `assign_fcbFlowSet`       | Pipeline step 3 (batch) |
| `em_optimize`             | Pipeline step 4         |
| `getAssignments`          | Result extraction       |
| `split` methods (3 pages) | Convert to flowSet      |
| `apply_platemap`          | Post-processing         |
| `plot.fcbflowframe`       | Visualization           |
| `show` method             | S4 display              |
| `jurkatFCB`               | Dataset                 |
| `jurkatFCB_std`           | Dataset                 |

Plus **newly export** `get_barcode_data()` as a proper read-only accessor (replaces `@barcodes` slot access per Bioc guidelines).

**Final exported count: 19 + 1 = 20 pages. Need 80% = 16 runnable.**

------------------------------------------------------------------------

## Part C: Add/fix runnable examples

| Page | Current status | Action |
|----|----|----|
| jurkatFCB | ✓ Runnable | None |
| jurkatFCB_std | ✓ Runnable | None |
| fcbFlowFrame-class | ✓ Runnable | None |
| get_barcode_data | New export | Add simple example |
| deskew_fcbFlowFrame | `\donttest` | Unwrap (self-contained, fast on 24k data) |
| deskew_fcbFlowSet | `\donttest` | Unwrap |
| cluster_fcbFlowFrame | `\donttest` | Unwrap + add deskew setup |
| cluster_fcbFlowSet | No examples | Add with deskew setup |
| assign_fcbFlowFrame | `\donttest` | Unwrap + add deskew/cluster setup |
| assign_fcbFlowSet | No examples | Add with deskew/cluster setup |
| em_optimize | `\donttest` | Unwrap + add full pipeline setup |
| getAssignments | `\donttest` | Unwrap + add full pipeline setup |
| split-fcbFlowFrame | `\donttest` | Unwrap + add full pipeline setup |
| apply_platemap | `\donttest` | Unwrap + add full pipeline setup |
| fcbFlowSet | `\donttest` | Unwrap (just constructor) |
| fcbFlowSet-class | No examples | Add one-liner |
| show-fcbFlowFrame-method | No examples | Add one-liner |
| plot.fcbflowframe | No examples | Add with pipeline setup |
| split-fcbFlowSet-list-method | No examples | Add |
| split-flowFrame-list-method | No examples | Add |

**Projected: 20/20 = 100% runnable.**

Each pipeline example will be self-contained (R CMD check runs examples independently) using the small 24k-cell dataset. Later pipeline steps include preceding steps as setup. Individual examples should complete in 1-3 seconds.

------------------------------------------------------------------------

## Part D: Other BiocCheck fixes

1.  **`@` slot access in vignette** → replace with `get_barcode_data()`
2.  **`1:n` → `seq_len()`** in `doRegressContrained.R` (2 remaining instances)
3.  **`=` → `<-`** for assignment in `doRegressContrained.R`

------------------------------------------------------------------------

## Implementation order

1.  De-export 9 functions (add `@keywords internal`, remove `@export`/generics)
2.  Update/fix affected tests (`test-cytoframe.R`)
3.  Export `get_barcode_data()` with example
4.  Update vignette: `get_barcode_data()` instead of `@`
5.  Unwrap `\donttest` from 9 existing examples, make self-contained
6.  Add examples to 8 man pages that lack them
7.  Fix `1:n` and `=` notes in `doRegressContrained.R`
8.  `devtools::document()` → `devtools::test()` → `rcmdcheck`
9.  Rebuild tarball → `BiocCheck`
10. Commit: `bioc: reduce exported API, add runnable examples, fix slot access`

------------------------------------------------------------------------

## Expected outcome

| Metric                                | Before  | After     |
|---------------------------------------|---------|-----------|
| Exported man pages                    | 28      | 20        |
| Runnable examples                     | 6 (21%) | 20 (100%) |
| BiocCheck example ERROR               | Yes     | No        |
| Custom generics (namespace pollution) | 3       | 0         |
| `\donttest` pages                     | 11      | 0         |
