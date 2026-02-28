# DebarcodeR Phase 4 Continuation Plan

## Context

DebarcodeR (Reisman et al., Cytometry A, 2021) is an R package for demultiplexing fluorescent cell barcoded (FCB) flow cytometry data. The core pipeline is:

1. **Deskew** — MARS regression (or constrained/linear) models dye uptake from morphology channels, corrects for differential uptake
2. **Cluster** — GMM (mixsmsn) or Jenks natural breaks estimates per-cell probability of belonging to each barcoding level
3. **Assign** — Ambiguity and likelihood cutoffs discretely assign cells to samples
4. **EM optimize** (optional) — Multivariate GMM refines assignments across channels

The paper emphasizes modularity ("each step can be replaced") and integration with the flowCore/Cytoverse ecosystem. All Phase 4 changes are structural refactoring — no algorithmic changes. The modular architecture is preserved and improved by these changes.

**Backwards compatibility** is a hard constraint. All changes must be additive — existing function signatures, return types, and slot structures must not change.

**Convention:** After each numbered step: 1. Run `devtools::test()` to verify tests pass, 2. Run `devtools::check()` to verify the package builds cleanly, 3. Make a git commit with the specified message.

## Completed Work

- **Phase 1** (install + tests): ✅ Complete
- **Phase 2** (cytoframe/cytoset support): ✅ Complete
- **Phase 4.1** (use original channel names, deprecate cleaned names): ✅ Complete
- **Phase 4.2** (replace custom `match.arg1` with `base::match.arg`): ✅ Complete
- **Phase 4.3** (extract barcode slot helpers `get_barcode_data`/`set_barcode_data` into `R/utils-barcode-slots.R`): ✅ Complete

## Current State

The package has 0 errors, 1 warning (missing base function imports), and 2 notes on `R CMD check`. The git HEAD is at commit `e2ea633` ("refactor: extract barcode slot helpers").

## Remaining Steps

### Step 4.4: Consolidate duplicated code in `cluster_fcbFlowFrame`

**File:** `R/cluster_fcbFlowFrame.R`

The `fisher` (lines 106–129) and `manual.breaks` (lines 132–157) branches are nearly identical — only break computation differs. The shared logic is: classify cells into levels using `findInterval()`, reverse the ordering, split the vector by classification, build per-level histograms, and assemble a probability matrix.

**Changes:**

1. Extract an unexported helper function `compute_histogram_probs(vec, breaks, levels)` that takes pre-computed breaks and the deskewed values vector, and returns the probability matrix. Place it in `R/cluster_fcbFlowFrame.R` (above the main function).
2. Refactor the `fisher` branch to: compute breaks via `classInt::classIntervals(vecss, levels, style = "fisher")`, then call `compute_histogram_probs(vec, mod.int$brks, levels)`.
3. Refactor the `manual.breaks` branch to: validate `manbreaks`, then call `compute_histogram_probs(vec, manbreaks, levels)`.
4. The clustering storage block (lines 159–163) is already clean from step 4.3 — no changes needed there.

**Commit:** `"refactor: consolidate duplicated clustering code"`

### Step 4.5: Consolidate duplicated split methods

**File:** `R/split_fcbFlowFrame.R`

The `fcbFlowFrame` split method (lines 16–43) and `flowFrame` split method (lines 110–138) contain identical logic: collapse factor list into a single factor, split the flowFrame, update pData with barcoding levels, wrap in fcbFlowSet.

**Changes:**

1. Extract an unexported helper `split_by_assignments(x, f, flowSet)` containing the shared logic (factor collapsing, `split()` call, pData update, `fcbFlowSet()` wrapping).
2. The `fcbFlowFrame` method becomes: `x <- as(x, "flowFrame"); split_by_assignments(x, f, flowSet)`.
3. The `flowFrame` method becomes: `split_by_assignments(x, f, flowSet)` (note: line 125 has `x <- as(x, "flowFrame")` which is redundant for a flowFrame input, but harmless).
4. The `fcbFlowSet` split method (lines 60–94) has different logic (per-sample splitting with `mapply`), so leave it unchanged.

**Commit:** `"refactor: consolidate split methods"`

### Step 4.6: Improve input validation

**File:** `R/utils-validation.R` (already exists with `resolve_channel`/`resolve_channels`)

Multiple functions duplicate the same validation patterns: `inherits(x, "fcbFlowFrame")` + `stop()`, checking barcodes slot is non-empty, and cytoframe-to-flowFrame conversion with `requireNamespace`.

**Changes:**

1. Add `assert_fcbFlowFrame(x, needs = NULL)` — checks `inherits(x, "fcbFlowFrame")` and optionally verifies that required pipeline steps (e.g., `"deskewing"`, `"clustering"`) exist in the barcodes slot for at least one channel. Replace inline validation blocks in:
   - `cluster_fcbFlowFrame.R` (lines 44–52)
   - `assign_fcbFlowFrame.R` (lines 20–28, plus the clustering check at line 33)
   - `em_optimize.R` (line 27–29)

2. Add `coerce_to_flowFrame(x)` — shared cytoframe → flowFrame conversion: if `x` is a cytoframe, require `flowWorkspace` and convert; if already a flowFrame, return as-is; otherwise error. Replace duplicated conversion blocks in:
   - `deskew_fcbFlowFrame.R` lines 36–40 (main input)
   - `deskew_fcbFlowFrame.R` lines 69–73 (uptake parameter)

3. Improve error messages to list available channels where applicable (partially done already in `get_barcode_data`).

**Commit:** `"refactor: centralize input validation"`

### Step 4.7: Improve console output

**Files:** `R/em_optimize.R`, `R/fcbFlowFrame.R`

**Changes:**

1. In `em_optimize.R`, replace all 5 `cat()` calls (lines 30, 113, 121, 135, 173) with `message()` so output is suppressable via `suppressMessages()`. Wrap each in the existing `if (verbose)` guard.

2. Add a `show()` S4 method for `fcbFlowFrame` in `R/fcbFlowFrame.R` that prints a concise summary of debarcoding state:
   ```
   fcbFlowFrame with 240000 cells x 16 channels
   Barcodes:
     Pacific Blue-A: deskewed -> clustered (8 levels) -> assigned
     Pacific Orange-A: deskewed -> clustered (6 levels) -> assigned
     wells: clustered (48 wells)
   ```
   This uses the `@barcodes` slot to determine which steps have been completed for each channel.

3. Keep existing `verbose` parameter and `updateProgress` callback behavior unchanged.

**Commit:** `"feat: improve console output"`

### Step 4.8: Fix R CMD check warnings and notes

**Files:** `R/` (various), `NAMESPACE`

Clean up the existing check issues that produce the warning and notes:

1. Add missing `@importFrom` directives in the relevant source files for base functions:
   - `stats::quantile` (in `cluster_fcbFlowFrame.R`)
   - `stats::lm`, `stats::optimize` (in `doRegressConstrained.R`)
   - `stats::as.formula`, `stats::median` (in `morphology_corr_earth.R`, `morphology_corr_lm.R`)
   - `graphics::hist` (in `cluster_fcbFlowFrame.R`)
   - `grDevices::chull` (in `plot-fcbFlowFrame-assignments.R`)

2. Fix the `plot.fcbflowframe` documentation in `R/plot-fcbFlowFrame-assignments.R` to use proper S3 method markup (`@method plot fcbflowframe` or `@export plot.fcbflowframe`).

3. Address `well` and `level` global variable bindings (likely ggplot `aes()` references in `plot-fcbFlowFrame-assignments.R`) — add `.data$` prefix from rlang, or use `utils::globalVariables()`.

4. Rebuild docs with `roxygen2::roxygenize()`.

**Commit:** `"fix: resolve R CMD check warnings and notes"`

## What Comes Next (not in scope for this plan)

- **Phase 3** (documentation improvements): flesh out examples, create vignette, update README
- **Phase 5** (GatingSet support): accept GatingSet input, preserve gating hierarchy
- **Phase 6** (Shiny GUI): interactive debarcoding interface

## Key Files Reference

| File | Purpose |
|------|---------|
| `R/deskew_fcbFlowFrame.R` | Step 1: morphology correction entry point |
| `R/cluster_fcbFlowFrame.R` | Step 2: GMM/Jenks clustering |
| `R/assign_fcbFlowFrame.R` | Step 3: discrete assignment with cutoffs |
| `R/em_optimize.R` | Optional: multivariate EM refinement |
| `R/split_fcbFlowFrame.R` | Split assigned data into separate flowFrames |
| `R/utils-barcode-slots.R` | Helpers: `get_barcode_data`, `set_barcode_data` |
| `R/utils-validation.R` | Helpers: `resolve_channel`, `resolve_channels` |
| `R/fcbFlowFrame.R` | S4 class definition and constructor |
| `R/fcbFlowSet.R` | S4 class definition and constructor |
| `tests/testthat/` | Test suite (11 test files + setup.R) |
