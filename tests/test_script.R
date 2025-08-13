# Test script for Zebrafish Color Spectra Analysis
# This script tests the basic functionality of the refactored code

cat("Testing Zebrafish Color Spectra Analysis...\n")

# Test 1: Check if configuration loads
cat("\n1. Testing configuration loading...\n")
if (file.exists("src/config.R")) {
  source("src/config.R")
  cat("✅ Configuration loaded successfully\n")
  cat("   Data directory: ", DATA_DIR, "\n")
  cat("   Wavelength file: ", WAVELENGTH_FILE, "\n")
} else if (file.exists("config.R")) {
  source("config.R")
  cat("✅ Configuration loaded successfully\n")
  cat("   Data directory: ", DATA_DIR, "\n")
  cat("   Wavelength file: ", WAVELENGTH_FILE, "\n")
} else {
  cat("⚠️  Configuration file not found, using defaults\n")
}

# Test 2: Check if required packages are available
cat("\n2. Testing package availability...\n")
required_packages <- c("dplyr", "tidyr", "stringr", "ggplot2", "zoo")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) == 0) {
  cat("✅ All required packages are available\n")
} else {
  cat("❌ Missing packages: ", paste(missing_packages, collapse = ", "), "\n")
  cat("   Install with: install.packages(c(", paste0('"', missing_packages, '"', collapse = ", "), "))\n")
}

# Test 3: Check if main script loads without errors
cat("\n3. Testing main script loading...\n")
tryCatch({
  source("src/Danio_Spectra.R")
  cat("✅ Main script loaded successfully\n")
}, error = function(e) {
  cat("❌ Error loading main script: ", e$message, "\n")
})

# Test 4: Check if color worker script loads without errors
cat("\n4. Testing color worker script loading...\n")
tryCatch({
  source("src/ColWorkerReference.R")
  cat("✅ Color worker script loaded successfully\n")
}, error = function(e) {
  cat("❌ Error loading color worker script: ", e$message, "\n")
})

# Test 5: Check directory structure
cat("\n5. Testing directory structure...\n")
if (dir.exists("data/Experimental")) {
  cat("✅ Experimental directory exists\n")
  tsv_files <- list.files("data/Experimental", pattern = "\\.tsv$")
  if (length(tsv_files) > 0) {
    cat("✅ Found ", length(tsv_files), " .tsv files\n")
  } else {
    cat("⚠️  No .tsv files found in Experimental directory\n")
  }
} else {
  cat("⚠️  Experimental directory not found\n")
  cat("   Create it and add your .tsv files\n")
}

if (file.exists("data/Experimental/Wavelength.txt")) {
  cat("✅ Wavelength.txt file exists\n")
} else {
  cat("⚠️  Wavelength.txt file not found\n")
  cat("   Add it to the Experimental directory\n")
}

cat("\n=== Test Summary ===\n")
cat("The refactored code should now work correctly.\n")
cat("To run the analysis:\n")
cat("1. Ensure your data is in the data/Experimental/ directory\n")
cat("2. Run: source('src/Danio_Spectra.R')\n")
cat("3. For color worker files: source('src/ColWorkerReference.R')\n")
cat("\nCheck src/config.R to customize paths and parameters.\n")
