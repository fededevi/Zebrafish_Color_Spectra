#!/usr/bin/env Rscript

# Color Worker runner script for Zebrafish Color Spectra Analysis
# This script generates Color Worker CSV files from the project root

cat("=== Zebrafish Color Worker Generation ===\n")
cat("Starting color worker file generation...\n\n")

# Check if we're in the right directory
if (!file.exists("src/ColWorkerReference.R")) {
  stop("Error: Please run this script from the project root directory")
}

# Source the color worker script
cat("Loading color worker script...\n")
source("src/ColWorkerReference.R")

cat("\nColor worker generation complete!\n")
cat("Check the data/color_worker_output/ directory for CSV files.\n")
