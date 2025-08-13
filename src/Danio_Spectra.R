library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(zoo)

# Zebrafish Color Spectra Analysis
# This script processes spectral data from Ocean Optics spectrometer
# Reads multiple .tsv files and performs preliminary analysis

# Load configuration
if (file.exists("src/config.R")) {
  source("src/config.R")
} else if (file.exists("config.R")) {
  source("config.R")
} else {
  # Default configuration if config file doesn't exist
  DATA_DIR <- "Experimental"
  WAVELENGTH_FILE <- "Experimental/Wavelength.txt"
  MIN_WAVELENGTH <- 280
  MAX_WAVELENGTH <- 700
  SMOOTHING_FILTER_SIZE <- 50
  FILTER_START <- 278
  FILTER_END <- 1458
  WAVELENGTH_FILTER_START <- 278
  WAVELENGTH_FILTER_END <- 2056
  REQUIRED_MIN_ROWS <- 1458
  SKIP_ROWS <- 9
  PROCESSED_DATA_FILE <- "processed_spectral_data.csv"
}

# Function to safely read files with error handling
safe_read_files <- function(directory, pattern = "\\.tsv$") {
  if (!dir.exists(directory)) {
    stop("Directory does not exist: ", directory)
  }
  
  filenames <- list.files(directory, pattern = TSV_PATTERN, full.names = TRUE)
  if (length(filenames) == 0) {
    stop("No .tsv files found in directory: ", directory)
  }
  
  return(filenames)
}

# Function to remove extra columns from data frames
remove_extra_column <- function(data) {
  if (ncol(data) > 0) {
    return(data[, -ncol(data), drop = FALSE])
  }
  return(data)
}

# Function to clean column names and select transmission columns
clean_and_select_columns <- function(data_list, header_list) {
  result <- vector("list", length(data_list))
  names(result) <- names(data_list)
  
  for (i in seq_along(data_list)) {
    # Set column names from header
    colnames(data_list[[i]]) <- colnames(header_list[[i]])
    
    # Select only transmission columns
    transmission_cols <- grep("Transmission", colnames(data_list[[i]]), value = TRUE)
    if (length(transmission_cols) > 0) {
      result[[i]] <- data_list[[i]][, transmission_cols, drop = FALSE]
    } else {
      warning("No transmission columns found in ", names(data_list)[i])
      result[[i]] <- data_list[[i]]
    }
  }
  
  return(result)
}

# Main processing function
process_spectral_data <- function() {
  # Get file names
  filenames <- safe_read_files(DATA_DIR)
  
  # Read headers for column names
  cat("Reading file headers...\n")
  header_list <- lapply(filenames, function(f) {
    tryCatch({
      read.csv(f, sep = "\t", nrows = 1, header = TRUE)
    }, error = function(e) {
      warning("Error reading header from ", f, ": ", e$message)
      return(NULL)
    })
  })
  
  # Remove NULL entries
  header_list <- header_list[!sapply(header_list, is.null)]
  filenames <- filenames[!sapply(header_list, is.null)]
  
  # Clean header names
  names(header_list) <- basename(filenames)
  names(header_list) <- sub("\\.tsv$", "", names(header_list))
  
  # Remove extra columns from headers
  header_list <- lapply(header_list, remove_extra_column)
  
  # Read spectral data (skip rows as configured)
  cat("Reading spectral data...\n")
  data_list <- lapply(filenames, function(f) {
    tryCatch({
      read.csv(f, sep = "\t", header = FALSE, skip = SKIP_ROWS)
    }, error = function(e) {
      warning("Error reading data from ", f, ": ", e$message)
      return(NULL)
    })
  })
  
  # Remove NULL entries
  data_list <- data_list[!sapply(data_list, is.null)]
  
  # Clean data names
  names(data_list) <- basename(filenames[!sapply(data_list, is.null)])
  names(data_list) <- sub("\\.tsv$", "", names(data_list))
  
  # Filter wavelength range (configurable)
  cat("Filtering wavelength range...\n")
  data_list <- lapply(data_list, function(x) {
    if (nrow(x) >= REQUIRED_MIN_ROWS) {
      x[c(-FILTER_START:-1, -FILTER_END:-nrow(x)), , drop = FALSE]
    } else {
      warning("Data has insufficient rows for wavelength filtering")
      x
    }
  })
  
  # Read wavelength reference
  if (file.exists(WAVELENGTH_FILE)) {
    wavelength <- read.table(WAVELENGTH_FILE, header = TRUE)
    wavelength <- as.numeric(wavelength[c(-WAVELENGTH_FILTER_START:-1, -WAVELENGTH_FILTER_END:-nrow(wavelength)), ])
    cat("Wavelength range: ", min(wavelength), " to ", max(wavelength), " nm\n")
  } else {
    stop("Wavelength file not found: ", WAVELENGTH_FILE)
  }
  
  # Clean and select transmission columns
  cat("Processing transmission columns...\n")
  data_list <- clean_and_select_columns(data_list, header_list)
  
  # Check data structure
  measurements <- data.frame(
    ID = names(data_list),
    Counts = sapply(data_list, ncol)
  )
  cat("Measurement counts per file:\n")
  print(measurements)
  
  # Return processed data
  return(list(
    data = data_list,
    wavelength = wavelength,
    measurements = measurements
  ))
}

# Function to smooth spectra
smooth_spectra <- function(data_list, wavelength, filter_size = SMOOTHING_FILTER_SIZE) {
  result <- vector("list", length(data_list))
  names(result) <- names(data_list)
  
  for (i in seq_along(data_list)) {
    temp_data <- data.frame(NM = wavelength)
    
    for (j in seq_along(data_list[[i]])) {
      smoothed <- rollmean(data_list[[i]][[j]], filter_size, align = "center", fill = "extend")
      temp_data[[paste0("Col_", j)]] <- smoothed
    }
    
    # Add ID column
    temp_data$ID <- names(data_list)[i]
    result[[i]] <- temp_data
  }
  
  return(result)
}

# Function to calculate averages
calculate_averages <- function(smoothed_data) {
  # Combine all data
  combined_data <- bind_rows(smoothed_data, .id = "ID")
  
  # Pivot to long format
  long_data <- combined_data %>%
    pivot_longer(!c(ID, NM), names_to = "BodyPart", values_to = "Reflectance")
  
  # Extract body part information (assuming naming convention)
  long_data$Body <- substr(long_data$BodyPart, 1, nchar(long_data$BodyPart) - 1)
  
  # Round wavelength to nearest nm
  long_data$NM_rounded <- round(long_data$NM, 0)
  
  # Calculate averages by ID, Body, and wavelength
  averages <- long_data %>%
    group_by(ID, Body, NM_rounded) %>%
    summarise(Reflectance = mean(Reflectance, na.rm = TRUE), .groups = "drop")
  
  return(averages)
}

# Main execution
if (interactive()) {
  cat("Starting spectral data processing...\n")
  
  # Process data
  processed_data <- process_spectral_data()
  
  # Smooth spectra
  cat("Smoothing spectra...\n")
  smoothed_data <- smooth_spectra(processed_data$data, processed_data$wavelength)
  
  # Calculate averages
  cat("Calculating averages...\n")
  averages <- calculate_averages(smoothed_data)
  
  # Filter to useful wavelength range (configurable)
  averages_filtered <- averages %>%
    filter(NM_rounded >= MIN_WAVELENGTH, NM_rounded <= MAX_WAVELENGTH)
  
  cat("Processing complete!\n")
  cat("Final dataset dimensions: ", nrow(averages_filtered), " rows\n")
  
  # Display summary
  print(head(averages_filtered))
  
  # Save processed data
  write.csv(averages_filtered, PROCESSED_DATA_FILE, row.names = FALSE)
  cat("Data saved to '", PROCESSED_DATA_FILE, "'\n")
}

