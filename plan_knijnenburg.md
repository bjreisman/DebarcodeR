# Knijnenburg Method Bug Fix Plan

## Background

The Knijnenburg morphology correction method is a port of Knijnenburg et al. (2011,
Mol. Syst. Biol.) from MATLAB. A review of the original MATLAB supplement against the
R implementation identified two bugs in `selectDenseScatterArea()`, both on the same
line, both fixable together.

All other differences from the original are intentional design choices (external standard
approach, single-dataset operation, no `FC_preprocess` step) and are not addressed here.

---

## Bugs

### Bug 1: `$objective` instead of `$minimum` (Critical)

**File:** `R/selectDenseScatterArea.R`, line 43

**Current code:**
```r
tmin <- optimize(ft, c(0, 1e-4), tol = 1e-9)$objective
```

**Problem:** `optimize()$objective` returns the *value of the objective function* at the
minimum (approximately 0, since we're minimizing `|sum(z_d[z_d > t]) - 0.95|`). We need
`$minimum` — the *value of `t`* that achieves the minimum, i.e., the density threshold
that isolates the 95% contour.

**Effect:** With `tmin ≈ 0`, `z_d < tmin` is FALSE for almost all density grid cells
(densities are positive), so `AP` becomes all zeros, `!AP` becomes all TRUE, and the
function returns *all* grid points as the "dense scatter area" rather than just the 95%
contour. The spatial filtering is completely bypassed.

**Original MATLAB equivalent:**
```matlab
t = fminsearch(@(t) abs(sum(P(P>t))-area), 1/(2^S)^2);
% t is the threshold value, not the function value
```

---

### Bug 2: Search interval `c(0, 1e-4)` is too narrow (Critical, same line)

**Current code:**
```r
tmin <- optimize(ft, c(0, 1e-4), tol = 1e-9)$objective
```

**Problem:** Unlike MATLAB's `fminsearch` (which can expand freely from an initial point),
R's `optimize()` requires a fixed bounded interval. The density values in `z_d` after
normalization (`z_d / sum(z_d)`) are of order `1/n_cells` at the average to potentially
`~0.01` or higher at the peak of a dense population. For a 256×256 KDE grid summing to 1,
the average cell value is ~1.5e-5, but peak values routinely exceed 1e-4. If the true
threshold `t` lies above 1e-4, `optimize()` returns a boundary solution instead of the
true minimum.

**Fix:** Set the upper bound of the search interval to `max(z_d)`, which guarantees the
true threshold is always within the search range. This also matches the spirit of the
MATLAB implementation, which used a small starting value and let the optimizer expand.

---

## Fix

Both bugs are resolved by changing a single line in `R/selectDenseScatterArea.R`:

```r
# Line 43 — replace:
tmin <- optimize(ft, c(0, 1e-4), tol = 1e-9)$objective

# with:
tmin <- optimize(ft, c(0, max(z_d)), tol = 1e-9)$minimum
```

---

## Tests

Add tests to `tests/testthat/test-deskew.R` (the existing knijnenburg test is already
there at line 29 — extend it):

### Test 1: `selectDenseScatterArea` filters points correctly

Call `selectDenseScatterArea` directly on the `jurkatFCB` data and assert that `Loc`
contains substantially fewer points than the full 256×256 = 65,536 grid, confirming
the density filter is actually removing points:

```r
test_that("selectDenseScatterArea filters to dense region", {
  data <- as.data.frame(flowCore::exprs(jurkatFCB))
  result <- DebarcodeR:::selectDenseScatterArea(
    data,
    fsc_ssc = c(fsc = "FSC-A", ssc = "SSC-A"),
    subsample = 5000
  )
  # Should return a subset of the 256x256 = 65536 grid points
  expect_true(nrow(result$loc) < 65536)
  # Should return meaningfully fewer points — at least 5% filtering
  expect_true(nrow(result$loc) < 65536 * 0.95)
  # Weights should all be positive
  expect_true(all(result$c > 0))
})
```

### Test 2: Knijnenburg deskew produces plausibly reduced variance

Confirm that the knijnenburg method actually reduces scatter-correlated variance (the
whole point of the algorithm). After deskewing, the correlation between the corrected
barcode channel and FSC-A should be lower than before:

```r
test_that("knijnenburg deskew reduces FSC correlation", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             method = "knijnenburg",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)

  raw <- as.data.frame(flowCore::exprs(test_ff))
  corrected <- fcb@barcodes[["Pacific Blue-A"]][["deskewing"]][["values"]]

  cor_before <- abs(cor(raw[["FSC-A"]], raw[["Pacific Blue-A"]]))
  cor_after  <- abs(cor(raw[["FSC-A"]], corrected))

  expect_lt(cor_after, cor_before)
})
```

---

## Commit Convention

1. Fix the bug and add tests
2. Run `devtools::test()` — all tests pass
3. Run `devtools::check()` — no new warnings or errors
4. Commit: `"fix: correct selectDenseScatterArea density threshold computation"`

---

## Out of Scope (Noted for Reference)

These differences from the original MATLAB were identified but are *not* addressed in
this plan — they are intentional design choices or low-priority features:

- **`val3` bounds constraint** — `morphology_corr.knijnenburg()` always passes `val3 = NULL`,
  disabling the fluorescence percentile bounding constraints from `FC_preprocess`. Could be
  added in future by computing `val3 = quantile(fcb[, channel], c(0.05, 0.95))` and
  passing it through.
- **Default transformation** — `morphology_corr.knijnenburg()` defaults to `trans = "none"`,
  while the original MATLAB example uses `opt = 'log'`. The original 'log' was designed for
  data in the 0–1023 range; modern asinh-transformed data may not need it.
- **`FC_preprocess` not ported** — time-based event removal and scatter clipping are not
  implemented; this is expected as the user handles preprocessing externally.
