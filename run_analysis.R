#!/usr/bin/env Rscript

# Main runner script for Zebrafish Color Spectra Analysis
# This script runs the main analysis from the project root

cat("=== Zebrafish Color Spectra Analysis ===\n")
cat("Starting analysis...\n\n")

# Check if we're in the right directory
if (!file.exists("src/Danio_Spectra.R")) {
  stop("Error: Please run this script from the project root directory")
}

# Source the main analysis script
cat("Loading main analysis script...\n")
source("src/Danio_Spectra.R")

cat("\nAnalysis complete!\n")
cat("Check the data/ directory for output files.\n")
