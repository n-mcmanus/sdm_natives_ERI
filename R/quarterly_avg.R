#' Average quarterly climate layers
#'
#' This function reads in a folder of monthly environmental data (in .tif format)
#' from the Basin Characterization Model version 8 (BCMv8), then averages values
#' for rasters within the specified quarter for each water year. 
#' The output is one raster per water year matching the extent, resolution, 
#' and crs of the input files. 
#' Note: This code was written to be compatible with the specific naming 
#' convention of BCMv8 data. 
#' 
#' @author Nick McManus
#' @param var_name variable to be averaged (e.g. ppt, tmx, tmn)
#' @param quarter which quarter to avg the variable over (winter or summer)
#' @param startYear first water year in dataset
#' @param endYear last water year in dataset
#' @param pathIn path to input directory of env data rasters
#' @param pathOut path to output directory where new rasters will be saved
#' @return TIFs with average quarterly data for each water year


quarter_avg <- function(var_name, quarter, startYear, endYear, pathIn, pathOut) {
  ## Checks
  if (!(quarter %in% c("winter", "summer")))
    stop("Incorrect input for quarter. Please enter either 'summer' or 'winter'.")
  
    
  ## Create df for variables to avg  -----------------------------------------
  vars <- data.frame(variable = rep(var_name, each = 12),
                     month = c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
                               'jul', 'aug', 'sep', 'oct', 'nov', 'dec'),
                     year = rep(startYear:endYear, each = 12))
  
  ## Rearrange to water year format
  ## Put Oct-Dec at start, then adjust calendar year
  vars <- rbind(tail(vars, 3), head(vars, -3))
  vars[1:3, 3] = (vars[4,3] - 1)
  
  ## Filter by quarter -------------------------------------------------------
  if (quarter == "winter") {
    vars_filtered <- vars %>% 
      filter(month %in% c('dec', 'jan', 'feb'))
  } else if (quarter == "summer") {
    vars_filtered <- vars %>% 
      filter(month %in% c('jun', 'jul', 'aug'))
  } 
  # if (quarter == "winter") {
  #   vars_filtered <- vars %>% 
  #     filter(month %in% c('dec', 'jan', 'feb'))
  # } else if (quarter == "spring") {
  #   vars_filtered <- vars %>% 
  #     filter(month %in% c('mar', 'apr', 'may'))
  # } else if (quarter == "summer") {
  #   vars_filtered <- vars %>% 
  #     filter(month %in% c('jun', 'jul', 'aug')) 
  # } else {
  #   vars_filtered <- vars %>% 
  #     filter(month %in% c('sep', 'oct', 'nov'))
  # }
  
  ngroups <- (nrow(vars_filtered)/3)
  vars_filtered <- mutate(vars_filtered,
                          file = paste0(variable, year, month, ".tif"),
                          group = rep(1:ngroups, each = 3))

  ## Average rasters -------------------------------------------------
  
  for (i in 1:ngroups) {
    quarter_wy <- vars_filtered %>% 
      filter(group == i)
    
    stack <- terra::rast(c(paste0(pathIn, quarter_wy$file[1]),
                           paste0(pathIn, quarter_wy$file[2]),
                           paste0(pathIn, quarter_wy$file[3])))
    
    stack_avg <- terra::app(stack, fun = 'mean')
    
    writeRaster(stack_avg,
                paste0(pathOut, var_name, "_", quarter, "_", quarter_wy$year[3], ".tif"),
                overwrite = TRUE)
  }## End for-loop
  
  
} ### end fxn