# Shared test fixtures
# Load the jurkat dataset and create a small subsample for fast tests
library(flowCore)

data(jurkatFCB, package = "DebarcodeR")

# Small reproducible subsample for tests
set.seed(7392)
test_idx <- sample(nrow(jurkatFCB), 5000)
test_ff <- jurkatFCB[test_idx, ]
