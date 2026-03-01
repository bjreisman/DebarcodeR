# DebarcodeR 1.1.0

## New Features

-   **Interactive Shiny GUI:** `run_debarcoder()` launches a
    wizard-style app (built with `bslib`) for the full debarcoding
    pipeline. Supports FCS file upload or passing R objects directly
    from the console. Includes diagnostic visualizations at each step
    and generates a reproducible R script as the user tunes parameters.
-   **Cytoframe/cytoset support:** `fcbFlowFrame()`, `fcbFlowSet()`,
    `deskew_fcbFlowFrame()`, and `deskew_fcbFlowSet()` now accept
    `cytoframe`/`cytoset` input, with automatic coercion.
-   **Public barcode data accessor:** `get_barcode_data()` provides
    read-only access to the `@barcodes` slot, replacing direct
    `@barcodes` access.
-   **Assignment visualization:** `plot.fcbFlowFrame()` S3 method
    produces diagnostic scatter plots colored by barcode assignment.
-   **Tutorial vignette:** Fully executable vignette
    (`vignettes/debarcoder-tutorial.Rmd`) walks through the complete
    pipeline on the bundled `jurkatFCB` dataset.
-   **External standard dataset:** `jurkatFCB_std` included for use in
    examples and the vignette.
-   Added `show()` S4 method for `fcbFlowFrame`.

## API Changes

-   **Channel name handling (soft deprecation):** Pipeline functions now
    use original FCS channel names (e.g. `"Pacific Blue-A"`) internally.
    Cleaned/janitor-style names (e.g. `"pacific_blue_a"`) are still
    accepted as input with a deprecation warning via
    `resolve_channel()`. Note that results are stored under the original
    name, so code that indexes into `getAssignments()` or
    `get_barcode_data()` output by cleaned name should be updated.
-   **Removed:** `as.flowFrame()`, `as.cytoframe()`, `as.cytoset()`
    conversion wrappers deleted to avoid method dispatch conflicts with
    flowCore. Use `as(x, "flowFrame")` or
    `flowWorkspace::flowFrame_to_cytoframe()` instead.
-   **De-exported:** `morphology_corr.*()`, `calculate.ambiguity()`,
    `calculate.likelihood()`, and Knijnenburg helper functions are now
    internal (`@keywords internal`).
-   **New exports:** `get_barcode_data()`, `plot.fcbFlowFrame()`,
    `run_debarcoder()`, `show(fcbFlowFrame)`.

## Bioconductor Compliance

-   `jurkatFCB` subsampled to 24,000 cells (500/well × 48 wells), xz
    compressed; tarball \~2.4 MB (under the 5 MB Bioc limit).
-   All 21 exported man pages have runnable `@examples`.
-   `R CMD check`: 0 errors, 0 warnings, 0 notes.
-   Code style: `styler::style_pkg()` applied package-wide; `1:n`
    replaced with `seq_len(n)`; `class(x) == "y"` replaced with
    `inherits(x, "y")`; `cat()` replaced with `message()`.
-   Added `inst/CITATION` with the Cytometry A reference.

## Bug Fixes

-   Fixed `doRegressContrained.R`: MATLAB-style indexing `b(noc+1)`
    corrected to `b[noc + 1, 1]`.
-   Fixed `apply_platemap()`: `pData` column names now cleaned before
    joining with platemap to prevent mismatches.
-   Fixed `plot.fcbflowframe` → `plot.fcbFlowFrame` case mismatch that
    prevented S3 dispatch.
-   Extracted and consolidated barcode slot helpers and input validation
    into `utils-barcode-slots.R` and `utils-validation.R`.
-   Added `@seealso` cross-references across all pipeline steps.
-   Fixed typos in parameter documentation.

## Known Issues

-   `selectDenseScatterArea.R` line 43: two bugs in the Knijnenburg
    method (`$objective` → `$minimum`; search interval too narrow). The
    default earth/lm methods are unaffected.
-   `plot(fcbFlowFrame_object)` dispatches to flowCore's S4 method
    instead of `plot.fcbFlowFrame`. Workaround: call
    `plot.fcbFlowFrame()` explicitly.

# DebarcodeR 1.0.0

-   Initial release
