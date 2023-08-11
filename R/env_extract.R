#' Environmental data extraction for points of species occurrence
#'
#' This function reads in a folder of monthly environmental data (in .tif format)
#' from the Basin Characterization Model version 8 (BCMv8), then filters
#' species occurrence data for that specific month, and then extracts 
#' raster values for each point. The resulting dataframe is in a
#' Samples with Data (SWD) format for performing a species distribution model (SDM)
#' with Maxent. 
#' Note: This code was written to be compatible with the specific naming 
#' convention of BCMv8 data. 
#' 
#' @author Nick McManus
#' @param startYear first water year in dataset
#' @param endYear last water year in dataset
#' @param filepath path to directory with env data rasters
#' @param sppOcc dataframe with species occurrences for extraction
#' @param lon column name for longitude values in spp occurrence dataframe (as character; default = "decimallongitude")
#' @param lat column name for the latitude values in spp occurrence dataframe (as character; default = "decimallatitude")
#' @param crs The coordinate reference system of the spp occurrence data (as character; default = "WGS84")
#' @return dataframe with environmental values at point of species observation


env_extract <- function(startYear, endYear, filepath, sppOcc,
                       lon = "decimallongitude", lat = "decimallatitude", crs = "WGS84") {
  
  ## Create df for range of dates -----------------------------------------
  dates_df <- data.frame(year = rep(startYear:endYear, each = 12), 
                         ### Repeat each yr 12 times to create a row 
                         ### for each mo/yr
                         mon = c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
                                 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'),
                         mon_num = seq(1, 12, 1))
 
  ## Rearrange to water year format
  ## Put Oct-Dec at start, then adjust calendar year
  dates_df <- rbind(tail(dates_df, 3), head(dates_df, -3))
  dates_df[1:3, 1] = (dates_df[4,1] - 1)
  
  
  ## empty df to store loop results -------------------------------------------
  extract_df <- data.frame()
  
  ## Extract loop -------------------------------------------------------------
  for (i in 1:nrow(dates_df)) {
    ## Read in list of raster files w/in directory
    files <- list.files(path = filepath, 
                        ## only list those with matching yr/mo in name
                        pattern= paste0(dates_df[i, 1], dates_df[i, 2]), 
                        full=TRUE)
  
    ## Stack all rasters
    env_stack <- terra::rast(c(files))
    
    ## Filter obs to yr/mo
    sppOcc_filter <- sppOcc %>% 
      filter(year == dates_df[i,1],
             month == dates_df[i,3])
    
    ## If filtered df has obs, then vectorize and extract.
    if(nrow(sppOcc_filter) > 0) {
        ## vectorize and reproj to env data crs
        sppOcc_vect <- sppOcc_filter %>%
          terra::vect(geom = c(lon, lat), crs = crs) %>%
          terra::project(y = crs(env_stack))
        
        ## extract and tidy df
        sppExtract <- extract(env_stack, sppOcc_vect, method = "simple") %>%
          ## only keep first 3 chars of each column name
          ## (e.g. "cwd2021jan" becomes "cwd")
          rename_with(~substr(., 1, 3)) %>%
          ## merge occ data w/extract data
          cbind(sppOcc_filter, .) %>%
          dplyr::select(-ID)
        
        ## append results to df
        extract_df <- rbind(extract_df, sppExtract)
      
    } else {
      ## If no obs for a yr/mo, skip
      next
    } ### end if/else statement
    
  } ### end for loop

  return(extract_df)
  
} ### end fxn