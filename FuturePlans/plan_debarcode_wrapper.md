# Plan: Add `debarcode()` Convenience Wrapper to DebarcodeR

## Motivation

The deskew → cluster → assign pipeline is a fixed 3-step sequence that every user runs. Currently users must call three separate functions in order, passing the same `channel` argument each time. A convenience wrapper reduces boilerplate for the common case while keeping the modular functions available for advanced use.

Evidence this is needed: the user has already written an external `debarcode_sample()` helper, and the Shiny app's server logic reproduces the same sequence.

## Design

### Function signature

```r
debarcode <- function(x,
                      uptake = NULL,
                      channel,
                      levels,
                      predictors = c("FSC-A", "SSC-A"),
                      method = "earth",
                      cluster_method = "mixture",
                      subsample_deskew = 20000,
                      subsample_cluster = 3000,
                      likelihoodcut = 8,
                      ambiguitycut = 0.02,
                      verbose = FALSE,
                      ...) {
```

### Behavior

1. If `x` is a `flowFrame` or `cytoframe`, wrap in `fcbFlowFrame()`.
2. Call `deskew_fcbFlowFrame()` with `uptake`, `channel`, `predictors`, `method`, `subsample_deskew`.
3. Call `cluster_fcbFlowFrame()` with `channel`, `levels`, `opt = cluster_method`, `subsample = subsample_cluster`.
4. Call `assign_fcbFlowFrame()` with `channel`, `likelihoodcut`, `ambiguitycut`.
5. Return the `fcbFlowFrame`.

### Scope decisions

- **Single-channel per call.** Multi-channel users call `debarcode()` once per channel, then optionally `em_optimize()`. This matches how the modular API works and avoids a complex `channels` list-of-lists config.
- **No EM optimize.** EM is optional and only relevant for multi-channel setups. Including it would require multi-channel awareness. Users who need it call `em_optimize()` after their `debarcode()` calls.
- **No splitting.** Returns the `fcbFlowFrame`, not a split `fcbFlowSet`. Splitting requires decisions about what to split (original data vs. deskewed) and platemap handling. `split()` and `apply_platemap()` remain separate steps.
- **`...` passed to deskew.** This lets users pass through arguments like `ret.model` without cluttering the signature.

### Naming

`debarcode()` — short, verb-based, consistent with the package name. No risk of collision with other Bioc packages (checked: no existing `debarcode` generic in flowCore/flowWorkspace/openCyto).

### Documentation

- `@export` with full roxygen docs.
- `@examples` section using `jurkatFCB` / `jurkatFCB_std` (single channel, quick to run).
- `@seealso` pointing to the individual pipeline functions and `em_optimize` for multi-channel workflows.
- A brief note that for multi-channel debarcoding, call `debarcode()` once per channel, then `em_optimize()`.

### File location

`R/debarcode.R` — new file, following the package's one-function-per-file convention.

### Vignette update

Add a "Quick start" section near the top of `debarcoder-tutorial.Rmd` showing the 2-line version:

```r
fcb <- debarcode(jurkatFCB, uptake = jurkatFCB_std,
                 channel = "Pacific Blue-A", levels = 8,
                 predictors = c("FSC-A", "SSC-A", "APC-H7-A"))
```

The existing step-by-step walkthrough stays as the detailed tutorial.

### Tests

Add `tests/testthat/test-debarcode.R`:

- Single-channel round trip: `debarcode()` returns an `fcbFlowFrame` with deskewing, clustering, and assignment populated.
- Input coercion: passing a plain `flowFrame` works (auto-wraps in `fcbFlowFrame`).
- Error on missing `levels`: informative error if `levels` not supplied.
- Equivalence: result matches calling the three functions individually with the same parameters.

### NAMESPACE / man page

- Export `debarcode` in NAMESPACE (via roxygen `@export`).
- One new man page: `man/debarcode.Rd`.

## Checklist

1. [ ] Create `R/debarcode.R` with function + roxygen
2. [ ] Create `tests/testthat/test-debarcode.R`
3. [ ] Add "Quick start" section to vignette
4. [ ] `devtools::document()` → verify NAMESPACE + man page
5. [ ] `devtools::test()` → all pass
6. [ ] `rcmdcheck::rcmdcheck(".", args = "--no-manual")` → clean
7. [ ] Update AGENTS.md exported API table
