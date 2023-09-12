#' Quarterly climate layers
#'
#' This function reads in a folder of monthly environmental data (in .tif format)
#' from the Basin Characterization Model version 8 (BCMv8), then generates a raster
#' (either mean or cumulative values) for the specified quarter for each water year. 
#' The output raster(s) match the extent, resolution, and crs of the input files. 
#' Note: This code was written to be compatible with the specific naming 
#' convention of BCMv8 data. 
#' 
#' @author Nick McManus
#' @param var character. Variable to be averaged (e.g. ppt, tmx, tmn)
#' @param quarter character. Which quarter to evaluate the variable over. `winter`: Dec, Jan, Feb. `summer`: Jun, Jul, Aug
#' @param method character. `mean`: average the variables over the quarter. `sum`: find the cumulative value for the variable over the quarter.  
#' @param startYear numeric or character. The first water year in dataset
#' @param endYear numeric or character. The last water year in dataset
#' @param pathIn character. Path to input directory of env data rasters
#' @param pathOut character. Path to output directory where new rasters will be saved
#' @return TIFs of the average or cumulative quarterly data for each water year in the date range provided.


quarter_rast <- function(var, quarter, method, startYear, endYear, pathIn, pathOut) {
  ## Checks 
  if (!(quarter %in% c("winter", "summer")))
    stop("Incorrect input for quarter. Please enter either 'summer' or 'winter'.")
  if (!(method %in% c("mean", "sum")))
    stop("Incorrect method provided. Please enter either 'mean' or 'sum'.")
  if (var != "ppt" & method == "sum")
    warning("You are finding cumulative data for a variable other than precipitation. Be advised.")

    
  ## Create df for variables to avg  -----------------------------------------
  dates_df <- data.frame(variable = rep(var, each = 12),
                     month = c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
                               'jul', 'aug', 'sep', 'oct', 'nov', 'dec'),
                     year = rep(startYear:endYear, each = 12))
  
  ## Rearrange to water year format
  ## Put Oct-Dec at start, then adjust calendar year
  dates_df <- rbind(tail(dates_df, 3), head(dates_df, -3))
  dates_df[1:3, 3] = (dates_df[4,3] - 1)
  dates_df <- mutate(dates_df,
                     wy = rep(startYear:endYear, each = 12))
  
  ## Filter by quarter -------------------------------------------------------
  if (quarter == "winter") {
    dates_filtered <- dates_df %>% 
      filter(month %in% c('dec', 'jan', 'feb')) %>% 
      mutate(file = paste0(variable, year, month, ".tif"))
  } else if (quarter == "summer") {
    dates_filtered <- dates_df %>% 
      filter(month %in% c('jun', 'jul', 'aug')) %>% 
      mutate(file = paste0(variable, year, month, ".tif"))
  } 
  
  ## Progress bar ------------------------------------------------------------
  runLength <- length(startYear:endYear)
  pb <- txtProgressBar(min = 0,
                       max = runLength,
                       style = 3,
                       width = runLength,
                       char = "=")
  
  ## Generate rasters -------------------------------------------------------
  for (i in startYear:endYear) {
    ## filter data by water year
    quarter_wy <- dates_filtered %>% 
      filter(group == i)
    
    ## stack rasters for the quarter
    stack <- terra::rast(c(paste0(pathIn, quarter_wy$file[1]),
                           paste0(pathIn, quarter_wy$file[2]),
                           paste0(pathIn, quarter_wy$file[3])))
    
    ## create one rast based on method(mean/sum)
    quarterRast <- terra::app(stack, fun = method)
    ## specific rast name for easier extraction later
    names(quarterRast) <- paste0(var, quarter_wy$year[3], quarter)
    
    ## export raster
    writeRaster(quarterRast,
                paste0(pathOut, var, quarter_wy$year[3], quarter, ".tif"),
                overwrite = TRUE)
    
    ## update progress bar
    setTxtProgressBar(pb, i)
  }## END for-loop
  
  
} ### END FXN