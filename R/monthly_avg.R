#' Average monthly climate layers
#'
#' This function reads in a folder of monthly environmental data (in .tif format)
#' from the Basin Characterization Model version 8 (BCMv8), then averages values
#' by month and variable across the defined water years. 
#' The output is one raster per month (12 total) for each variable, matching the
#' extent, resolution, and crs of the input files. 
#' Note: This code was written to be compatible with the specific naming 
#' convention of BCMv8 data. 
#' 
#' @author Nick McManus
#' @param var_names list of variables to be averaged (e.g. c('aet', 'tmn', 'tmx'))
#' @param pathIn path to input directory of env data rasters
#' @param pathOut path to output directory where new rasters will be saved
#' @return TIFs with average monthly data for the time period


month_avg <- function(var_names, pathIn, pathOut) {
  
  ## Create df for variables to avg  -----------------------------------------
  vars <- data.frame(variable = rep(var_names, each = 12),
                         month = c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
                                   'jul', 'aug', 'sep', 'oct', 'nov', 'dec'))
  
  
  ## Average raster function -------------------------------------------------
  var_avg <- function(variable, month, pathIn, pathOut) {
    ## Read in all files for that var/mo
    files <- list.files(path = pathIn, 
                        ## only list those with matching yr/mo in name
                        pattern = paste0(variable, ".+", month),
                        full=TRUE)
    
    env_stack <- terra::rast(c(files))
    
    ## Average all rasts in stack
    env_stack_avg <- terra::app(env_stack, fun = 'mean')
    
    ## Save
    writeRaster(env_stack_avg, 
                paste0(pathOut, variable, "_", month, "_avg.tif"), 
                overwrite = TRUE)
  }
  
  ### Iterate avg fxn over list of vars/months
  purrr::pmap(vars, var_avg, pathIn, pathOut, .progress = TRUE)
  
} ### end fxn