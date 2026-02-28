# DebarcodeR 1.1.0

- Added cytoframe/cytoset support (`fcbFlowFrame()`, `fcbFlowSet()`, `deskew_fcbFlowFrame()`, `deskew_fcbFlowSet()` now accept `cytoframe`/`cytoset` input; `as.cytoframe()` / `as.cytoset()` conversion methods added)
- Improved channel name handling: functions now use original FCS channel names (e.g. `"Pacific Blue-A"`); cleaned/janitor-style names still accepted with a deprecation warning via `resolve_channel()`
- Extracted helper functions for barcode slot access (`get_barcode_data()`, `set_barcode_data()`) and validation (`assert_fcbFlowFrame()`, `coerce_to_flowFrame()`, `resolve_channel()`)
- Added `show()` S4 method for `fcbFlowFrame`
- Added tutorial vignette (`vignettes/debarcoder-tutorial.Rmd`) and `jurkatFCB_std` dataset
- Replaced `cat()` with `message()` in `em_optimize.R` for suppressible output
- Fixed latent bug in `doRegressContrained.R`: MATLAB-style indexing `b(noc+1)` corrected to `b[noc+1, 1]`
- Added `@examples` to all exported functions and `@seealso` cross-references across pipeline steps
- Fixed typos in parameter documentation

# DebarcodeR 1.0.0

- Initial release
