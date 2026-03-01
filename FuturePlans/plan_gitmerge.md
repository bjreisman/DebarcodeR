# Plan: Merge `devel-2026` into `cytolab/DebarcodeR:master`

## Situation

`devel-2026` is 134 commits ahead and 90 commits behind `cytolab/DebarcodeR:master`. The branches diverged at commit `82c1467` ("updating documentation") and have evolved independently since ~2020.

### What upstream has that we don't

The 90 "behind" commits are mostly **noise** — protocol file churn (create/delete Protocols folder, create/delete protocol.html) and README image uploads. The two substantive changes are:

1. **`manual.breaks` clustering option** (commit `3779536`) — already in `devel-2026`
2. **`em_optimize` divide-by-zero fix** (commit `7cb9cf2`) — already in `devel-2026`
3. **`Protocols/` folder** with PDF + Excel template + RMarkdown template — these are on upstream/master but could be added to `devel-2026` if desired

So there is **no functional code on upstream that is missing from `devel-2026`**. The 90-commit deficit is entirely protocol file churn, README edits, and changes that were independently re-implemented (and improved) in `devel-2026`.

### What `devel-2026` has that upstream doesn't

Everything documented in the v1.1.0 update summary: Shiny GUI, cytoframe/cytoset support, Bioconductor compliance, vignette, test suite, code quality overhaul, etc.

## Options

### Option A: Merge `upstream/master` into `devel-2026`, then PR back (recommended)

1. `git merge upstream/master` into `devel-2026`
2. Resolve conflicts (there will be many, since nearly every R source file has diverged — but in every case `devel-2026` has the correct version, so resolution is straightforward: keep ours)
3. Decide whether to keep `Protocols/` folder (the PDF, Excel template, and RMarkdown template)
4. Verify: `devtools::test()`, `rcmdcheck::rcmdcheck()`
5. Push merged `devel-2026` to `origin`
6. Open a PR from `bjreisman/DebarcodeR:devel-2026` → `cytolab/DebarcodeR:master`

**Pros:** Clean merge commit, preserves full history from both sides, standard GitHub workflow.
**Cons:** The merge will have many conflict markers to resolve (though all in one direction). The resulting PR will be very large.

### Option B: Force push `devel-2026` as the new `master` on cytolab

1. Open an issue or coordinate with cytolab collaborators
2. Reset `cytolab/master` to `devel-2026`

**Pros:** Clean history, no merge noise.
**Cons:** Destructive to upstream history. Only appropriate if you have admin access to cytolab/DebarcodeR and all collaborators agree.

### Option C: Open a PR without merging upstream first

1. Open PR from `bjreisman/DebarcodeR:devel-2026` → `cytolab/DebarcodeR:master` directly
2. GitHub will show conflicts; resolve in the PR

**Pros:** Simplest to start.
**Cons:** GitHub's conflict resolution UI is painful for this many files. Better to resolve locally first (Option A).

## Recommendation

**Option A** is the standard approach. The key step is the merge conflict resolution, which should be straightforward since `devel-2026` supersedes upstream on every file. The workflow would be:

```bash
git checkout devel-2026
git merge upstream/master
# For each conflict: accept "ours" (devel-2026 version)
# Exception: review Protocols/ folder — keep if desired
git add .
git commit -m "Merge upstream/master into devel-2026"

# Verify
Rscript -e 'devtools::test()'
Rscript -e 'rcmdcheck::rcmdcheck(".", args = "--no-manual")'

# Push and open PR
git push origin devel-2026
# Then open PR on GitHub: bjreisman/DebarcodeR:devel-2026 → cytolab/DebarcodeR:master
```

### Conflict resolution strategy

Since every R source file has been rewritten in `devel-2026`, the merge strategy is:

- **R/, man/, tests/, vignettes/**: keep `devel-2026` (ours) for all conflicts
- **DESCRIPTION, NAMESPACE, NEWS.md, README.md**: keep `devel-2026`
- **data/**: keep `devel-2026` (subsampled jurkatFCB + new jurkatFCB_std)
- **Protocols/**: keep from upstream if you want to preserve the protocol docs; otherwise drop
- **README_files/, README.html**: drop (we cleaned these up)

A bulk conflict resolution using `git checkout --ours` on the conflicted files would handle most of it.

## Decision needed before implementing

1. Do you want to keep the `Protocols/` folder (PDF, Excel platemap template, RMarkdown template) from upstream?
2. Do you have push access to `cytolab/DebarcodeR`, or will this go through a PR?
