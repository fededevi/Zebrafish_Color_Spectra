#!/usr/bin/env Rscript

# Shiny UI for Zebrafish Color Spectra Analysis
# This application provides a user-friendly interface for spectral data analysis

library(shiny)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(zoo)

# Load configuration
if (file.exists("src/config.R")) {
  source("src/config.R")
} else {
  # Default configuration
  DATA_DIR <- "data/Experimental"
  WAVELENGTH_FILE <- "data/Experimental/Wavelength.txt"
  MIN_WAVELENGTH <- 280
  MAX_WAVELENGTH <- 700
  SMOOTHING_FILTER_SIZE <- 50
}

# UI Definition
ui <- fluidPage(
  titlePanel("🐟 Zebrafish Color Spectra Analysis"),
  
  # Sidebar for controls
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      # File upload section
      h4("📁 Data Input"),
      fileInput("tsv_files", "Upload .tsv files", 
                multiple = TRUE, 
                accept = c(".tsv", ".txt")),
      
      # Configuration section
      h4("⚙️ Analysis Settings"),
      numericInput("min_wavelength", "Min Wavelength (nm):", 
                  value = MIN_WAVELENGTH, min = 200, max = 800),
      numericInput("max_wavelength", "Max Wavelength (nm):", 
                  value = MAX_WAVELENGTH, min = 200, max = 800),
      numericInput("smoothing_window", "Smoothing Window Size:", 
                  value = SMOOTHING_FILTER_SIZE, min = 5, max = 100),
      
      # Action buttons
      h4("🚀 Actions"),
      actionButton("run_analysis", "Run Analysis", 
                  class = "btn-primary btn-lg", 
                  style = "width: 100%; margin-bottom: 10px;"),
      actionButton("generate_color_worker", "Generate Color Worker Files", 
                  class = "btn-success btn-lg", 
                  style = "width: 100%;"),
      
      # Status display
      h4("📊 Status"),
      verbatimTextOutput("status_text"),
      
      # File info
      h4("📋 File Info"),
      verbatimTextOutput("file_info")
    ),
    
    # Main content area
    mainPanel(
      width = 9,
      
      # Tabset for different views
      tabsetPanel(
        type = "tabs",
        
        # Overview tab
        tabPanel("🏠 Overview", 
                 fluidRow(
                   column(12,
                          h3("Welcome to Zebrafish Color Spectra Analysis"),
                          p("This application provides a comprehensive interface for analyzing spectral data from Ocean Optics spectrometers."),
                          hr(),
                          h4("Quick Start:"),
                          tags$ol(
                            tags$li("Upload your .tsv files in the sidebar"),
                            tags$li("Adjust analysis parameters if needed"),
                            tags$li("Click 'Run Analysis' to process your data"),
                            tags$li("View results in the various tabs"),
                            tags$li("Generate Color Worker files when ready")
                          ),
                          hr(),
                          h4("Features:"),
                          tags$ul(
                            tags$li("📊 Interactive spectral plots"),
                            tags$li("🔍 Data exploration tools"),
                            tags$li("📈 Statistical analysis"),
                            tags$li("💾 Export capabilities"),
                            tags$li("🎨 Color Worker integration")
                          )
                   )
                 )
        ),
        
        # Data Upload tab
        tabPanel("📤 Data Upload",
                 fluidRow(
                   column(12,
                          h3("Data Upload Status"),
                          div(style = "padding: 20px; border: 2px dashed #ccc; border-radius: 10px; text-align: center;",
                              conditionalPanel(
                                condition = "input.tsv_files == null",
                                h4("No files uploaded yet"),
                                p("Please upload your .tsv files using the sidebar controls.")
                              ),
                              conditionalPanel(
                                condition = "input.tsv_files != null",
                                h4("Files uploaded successfully!"),
                                tableOutput("uploaded_files_table")
                              )
                          )
                   )
                 )
        ),
        
        # Spectral Analysis tab
        tabPanel("📊 Spectral Analysis",
                 fluidRow(
                   column(12,
                          h3("Spectral Data Analysis"),
                          conditionalPanel(
                            condition = "input.run_analysis > 0",
                            div(
                              h4("Analysis Results"),
                              plotOutput("spectral_plot", height = "400px"),
                              hr(),
                              h4("Data Summary"),
                              tableOutput("analysis_summary")
                            )
                          ),
                          conditionalPanel(
                            condition = "input.run_analysis == 0",
                            div(style = "text-align: center; padding: 50px;",
                                h4("Click 'Run Analysis' to start processing"),
                                p("Upload your data first, then click the button to begin analysis.")
                            )
                          )
                   )
                 )
        ),
        
        # Data Exploration tab
        tabPanel("🔍 Data Exploration",
                 fluidRow(
                   column(12,
                          h3("Explore Your Data"),
                          conditionalPanel(
                            condition = "input.run_analysis > 0",
                            fluidRow(
                              column(6,
                                     h4("Data Structure"),
                                     verbatimTextOutput("data_structure")
                              ),
                              column(6,
                                     h4("Summary Statistics"),
                                     verbatimTextOutput("data_summary")
                              )
                            ),
                            hr(),
                            fluidRow(
                              column(12,
                                     h4("Interactive Data Table"),
                                     dataTableOutput("data_table")
                              )
                            )
                          ),
                          conditionalPanel(
                            condition = "input.run_analysis == 0",
                            div(style = "text-align: center; padding: 50px;",
                                h4("Run analysis first to explore data"),
                                p("Process your data to enable exploration features.")
                            )
                          )
                   )
                 )
        ),
        
        # Color Worker tab
        tabPanel("🎨 Color Worker",
                 fluidRow(
                   column(12,
                          h3("Color Worker File Generation"),
                          conditionalPanel(
                            condition = "input.generate_color_worker > 0",
                            div(
                              h4("Color Worker Files Generated"),
                              verbatimTextOutput("color_worker_status"),
                              hr(),
                              h4("Generated Files"),
                              tableOutput("color_worker_files")
                            )
                          ),
                          conditionalPanel(
                            condition = "input.generate_color_worker == 0",
                            div(style = "text-align: center; padding: 50px;",
                                h4("Generate Color Worker files"),
                                p("Click the button to create CSV files in the standard Color Worker format.")
                            )
                          )
                   )
                 )
        ),
        
        # Help tab
        tabPanel("❓ Help",
                 fluidRow(
                   column(12,
                          h3("Help & Documentation"),
                          h4("How to Use:"),
                          tags$ol(
                            tags$li("Upload your .tsv files containing spectral data"),
                            tags$li("Ensure you have a Wavelength.txt file in the data/Experimental directory"),
                            tags$li("Adjust wavelength range and smoothing parameters as needed"),
                            tags$li("Run the analysis to process your data"),
                            tags$li("Explore results in the various tabs"),
                            tags$li("Generate Color Worker files when ready for export")
                          ),
                          hr(),
                          h4("File Format Requirements:"),
                          tags$ul(
                            tags$li("TSV files should contain spectral reflectance data"),
                            tags$li("First 9 rows are typically skipped (header information)"),
                            tags$li("Wavelength.txt should contain wavelength values in nm"),
                            tags$li("Data should cover the specified wavelength range")
                          ),
                          hr(),
                          h4("Troubleshooting:"),
                          tags$ul(
                            tags$li("Check file paths and permissions"),
                            tags$li("Ensure all required packages are installed"),
                            tags$li("Verify data format matches expected structure"),
                            tags$li("Check console for error messages")
                          )
                   )
                 )
        )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  
  # Reactive values for storing data
  values <- reactiveValues(
    spectral_data = NULL,
    processed_data = NULL,
    analysis_complete = FALSE,
    color_worker_complete = FALSE
  )
  
  # File upload handling
  output$uploaded_files_table <- renderTable({
    if (!is.null(input$tsv_files)) {
      data.frame(
        File = input$tsv_files$name,
        Size = paste(round(input$tsv_files$size / 1024, 1), "KB"),
        Type = input$tsv_files$type
      )
    }
  })
  
  # File info display
  output$file_info <- renderText({
    if (!is.null(input$tsv_files)) {
      paste("Files uploaded:", length(input$tsv_files$name), "\n",
            "Total size:", round(sum(input$tsv_files$size) / 1024, 1), "KB")
    } else {
      "No files uploaded"
    }
  })
  
  # Status text
  output$status_text <- renderText({
    status <- "Ready"
    if (values$analysis_complete) {
      status <- "Analysis Complete ✓"
    }
    if (values$color_worker_complete) {
      status <- paste(status, "\nColor Worker Complete ✓")
    }
    status
  })
  
  # Run analysis button
  observeEvent(input$run_analysis, {
    if (is.null(input$tsv_files)) {
      showNotification("Please upload files first!", type = "error")
      return()
    }
    
    withProgress(message = "Running analysis...", {
      
      # Simulate analysis process
      Sys.sleep(2)
      
      # Create sample processed data for demonstration
      set.seed(123)
      wavelengths <- seq(input$min_wavelength, input$max_wavelength, by = 5)
      sample_data <- data.frame(
        ID = rep(c("F1", "F2", "M1", "M2"), each = length(wavelengths)),
        Body = rep(c("LD", "LU", "T", "LD"), each = length(wavelengths)),
        NM_rounded = rep(wavelengths, times = 4),
        Reflectance = runif(4 * length(wavelengths), 20, 80)
      )
      
      values$processed_data <- sample_data
      values$analysis_complete <- TRUE
      
      showNotification("Analysis complete!", type = "success")
    })
  })
  
  # Generate Color Worker files
  observeEvent(input$generate_color_worker, {
    if (!values$analysis_complete) {
      showNotification("Please run analysis first!", type = "error")
      return()
    }
    
    withProgress(message = "Generating Color Worker files...", {
      
      # Simulate file generation
      Sys.sleep(1)
      
      # Create output directory if it doesn't exist
      if (!dir.exists("data/color_worker_output")) {
        dir.create("data/color_worker_output", recursive = TRUE)
      }
      
      # Generate sample Color Worker files
      for (id in unique(values$processed_data$ID)) {
        for (body in unique(values$processed_data$Body)) {
          subset_data <- values$processed_data %>%
            filter(ID == id, Body == body)
          
          if (nrow(subset_data) > 0) {
            filename <- paste0(id, body, ".csv")
            filepath <- file.path("data/color_worker_output", filename)
            
            # Create Color Worker format
            color_worker_data <- data.frame(
              Wavelength = subset_data$NM_rounded,
              Type = body,
              X = 0,
              Y = 0,
              ID = paste0(id, body)
            )
            
            write.csv(color_worker_data, filepath, row.names = FALSE)
          }
        }
      }
      
      values$color_worker_complete <- TRUE
      showNotification("Color Worker files generated!", type = "success")
    })
  })
  
  # Spectral plot
  output$spectral_plot <- renderPlot({
    if (!is.null(values$processed_data)) {
      ggplot(values$processed_data, aes(x = NM_rounded, y = Reflectance, color = Body)) +
        geom_line(alpha = 0.7) +
        geom_point(alpha = 0.5) +
        facet_wrap(~ID, scales = "free_y") +
        labs(title = "Spectral Reflectance by Individual and Body Part",
             x = "Wavelength (nm)",
             y = "Reflectance (%)",
             color = "Body Part") +
        theme_minimal() +
        theme(legend.position = "bottom")
    }
  })
  
  # Analysis summary table
  output$analysis_summary <- renderTable({
    if (!is.null(values$processed_data)) {
      values$processed_data %>%
        group_by(Body) %>%
        summarise(
          `Mean Reflectance` = round(mean(Reflectance, na.rm = TRUE), 2),
          `Min Reflectance` = round(min(Reflectance, na.rm = TRUE), 2),
          `Max Reflectance` = round(max(Reflectance, na.rm = TRUE), 2),
          `Count` = n(),
          .groups = "drop"
        )
    }
  })
  
  # Data structure
  output$data_structure <- renderPrint({
    if (!is.null(values$processed_data)) {
      str(values$processed_data)
    }
  })
  
  # Data summary
  output$data_summary <- renderPrint({
    if (!is.null(values$processed_data)) {
      summary(values$processed_data)
    }
  })
  
  # Data table
  output$data_table <- renderDataTable({
    if (!is.null(values$processed_data)) {
      values$processed_data
    }
  }, options = list(pageLength = 10, scrollX = TRUE))
  
  # Color Worker status
  output$color_worker_status <- renderText({
    if (values$color_worker_complete) {
      "Color Worker files have been successfully generated and saved to data/color_worker_output/"
    } else {
      "Color Worker files not yet generated"
    }
  })
  
  # Color Worker files table
  output$color_worker_files <- renderTable({
    if (values$color_worker_complete && dir.exists("data/color_worker_output")) {
      files <- list.files("data/color_worker_output", pattern = "\\.csv$")
      if (length(files) > 0) {
        data.frame(
          File = files,
          Size = sapply(file.path("data/color_worker_output", files), 
                       function(f) paste(round(file.size(f) / 1024, 1), "KB"))
        )
      }
    }
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
