# Zebrafish Color Spectra

A refactored R package for processing spectral data obtained from Ocean Optics spectrometer. The code is designed to read multiple .tsv files (OceanART format) from a directory and perform preliminary spectral analysis operations.

## Features

- **Robust File Handling**: Safe file reading with error handling and validation
- **Flexible Path Configuration**: Uses relative paths instead of hardcoded Windows paths
- **Modular Design**: Clean, well-structured functions for different processing steps
- **Data Validation**: Checks for file existence and data integrity
- **Comprehensive Logging**: Progress messages and error reporting

## Project Structure

```
Zebrafish_Color_Spectra/
├── src/                    # Source code
│   ├── Danio_Spectra.R    # Main processing script
│   ├── ColWorkerReference.R # Color worker script
│   └── config.R           # Configuration file
├── data/                   # Data and output
│   ├── Experimental/       # Input .tsv files
│   ├── color_worker_output/ # Color worker CSV files
│   └── processed_spectral_data.csv # Main output
├── tests/                  # Test scripts
│   └── test_script.R      # Test script
├── .Rprofile              # R environment setup
└── README.md              # This file
```

## Usage

### 1. Setup

1. Place your .tsv files in the `data/Experimental/` subdirectory
2. Ensure you have a `Wavelength.txt` file in the same directory
3. Update the configuration variables in `src/config.R` if needed:
   ```r
   DATA_DIR <- "data/Experimental"  # Your data directory
   WAVELENGTH_FILE <- "data/Experimental/Wavelength.txt"  # Wavelength reference
   ```

### 2. Run Main Analysis

```r
source("src/Danio_Spectra.R")
```

This will:
- Read and validate all .tsv files
- Process transmission columns
- Apply wavelength filtering (280-700 nm)
- Smooth spectra using rolling mean
- Calculate averages by individual, body part, and wavelength
- Save results to `processed_spectral_data.csv`

### 3. Generate Color Worker Files

```r
source("src/ColWorkerReference.R")
```

This creates individual CSV files in the standard Color Worker format.

## Dependencies

Required R packages:
- `dplyr` - Data manipulation
- `tidyr` - Data tidying
- `stringr` - String operations
- `ggplot2` - Plotting
- `zoo` - Time series operations

Install with:
```r
install.packages(c("dplyr", "tidyr", "stringr", "ggplot2", "zoo"))
```

## Data Structure

The processed data includes:
- **ID**: Individual identifier
- **Body**: Body part (LD, LU, T for Line Down, Line Up, Tail)
- **NM_rounded**: Wavelength in nanometers (rounded)
- **Reflectance**: Spectral reflectance values

## Improvements Made

- ✅ Removed hardcoded Windows file paths
- ✅ Added comprehensive error handling
- ✅ Fixed syntax errors and incomplete function calls
- ✅ Improved code structure and readability
- ✅ Added input validation and progress logging
- ✅ Made code portable across different systems
- ✅ Added proper documentation and comments

## Troubleshooting

- **"Directory does not exist"**: Check that your `DATA_DIR` path in `src/config.R` is correct
- **"No .tsv files found"**: Ensure your data files have .tsv extension and are in `data/Experimental/`
- **"Wavelength file not found"**: Verify `Wavelength.txt` exists in `data/Experimental/`

## Notes

- Wavelength filtering parameters (278:1, 1458:2056) are specific to your spectrometer configuration
- Adjust these values if using different equipment
- The script automatically handles missing or corrupted files with warnings
