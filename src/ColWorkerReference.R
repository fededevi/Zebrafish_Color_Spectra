

library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(zoo)

# Color Worker Reference Script
# This script generates CSV files in the standard format required by Color Worker
# The output files have a structure with columns: Wavelength, Type, X, Y, ID

# Load configuration if available
if (file.exists("src/config.R")) {
  source("src/config.R")
} else if (file.exists("config.R")) {
  source("config.R")
}

# Function to create color worker format data
create_color_worker_format <- function(spectra_data, min_wavelength = COLOR_WORKER_MIN_WAVELENGTH, max_wavelength = COLOR_WORKER_MAX_WAVELENGTH, step = 5) {
  # Filter to visible light range and create wavelength sequence
  filtered_data <- spectra_data %>% 
    filter(NM5 >= min_wavelength, NM5 <= max_wavelength)
  
  # Create the standard color worker format
  color_worker_data <- filtered_data %>%
    mutate(
      # Add required columns for color worker format
      X = 0,  # Placeholder for X coordinate
      Y = 0,  # Placeholder for Y coordinate
      # Create ID by combining body part and individual ID
      ID = str_c(Body, ID, sep = "")
    ) %>%
    # Select and rename columns to match color worker format
    select(
      Wavelength = NM5,
      Type = Body,  # Using body part as type
      X,
      Y,
      ID
    )
  
  return(color_worker_data)
}

# Function to generate individual CSV files
generate_color_worker_files <- function(color_worker_data, output_dir = COLOR_WORKER_OUTPUT_DIR) {
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Group by ID and create separate files
  color_worker_data %>%
    group_by(ID) %>%
    group_walk(~ {
      filename <- paste0(.y$ID, ".csv")
      filepath <- file.path(output_dir, filename)
      
      # Write CSV without column names as required by color worker
      write.csv(.x, filepath, row.names = FALSE, col.names = FALSE)
      
      cat("Generated: ", filepath, "\n")
    })
}

# Main execution
if (interactive()) {
  # Check if Spectra5 exists (should be loaded from main script)
  if (!exists("Spectra5")) {
    cat("Error: Spectra5 data not found. Please run the main script first.\n")
    cat("Loading sample data structure for demonstration...\n")
    
    # Create sample data structure for demonstration
    Spectra5 <- data.frame(
      ID = rep(c("F1", "F2", "M1"), each = 3),
      Body = rep(c("LD", "LU", "T"), times = 3),
      NM5 = rep(seq(400, 700, by = 5), each = 9),
      Reflectance = runif(9 * 61, 0, 100)
    )
  }
  
  cat("Creating color worker format data...\n")
  
  # Create color worker format
  color_worker_data <- create_color_worker_format(Spectra5)
  
  # Display structure
  cat("Color worker data structure:\n")
  print(head(color_worker_data))
  cat("Total rows: ", nrow(color_worker_data), "\n")
  cat("Unique IDs: ", length(unique(color_worker_data$ID)), "\n")
  
  # Generate CSV files
  cat("Generating individual CSV files...\n")
  generate_color_worker_files(color_worker_data)
  
  cat("Color worker files generation complete!\n")
  cat("Files saved in '", COLOR_WORKER_OUTPUT_DIR, "' directory\n")
}
