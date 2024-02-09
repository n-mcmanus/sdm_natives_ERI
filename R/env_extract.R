#' Environmental data extraction for points of species occurrence
#'
#' This function reads in a folder of monthly environmental data (in .tif format)
#' from the Basin Characterization Model version 8 (BCMv8) and NATSGO soil data,
#' then filters species occurrence data for that specific month, and then extracts 
#' raster values for each point. The resulting data frame is in a
#' Samples with Data (SWD) format for performing a species distribution model (SDM)
#' with Maxent. 
#' Note: This code was written to be compatible with the specific naming 
#' convention of BCMv8 data. 
#' 
#' @author Nick McManus
#' @param startYear character or numeric. The first water year in dataset.
#' @param endYear character or numeric. The last water year in dataset.
#' @param pathMonth character. File path to directory with monthly rasters.
#' @param pathQuarter character. File path to directory with quarterly data (generated from `quarterly_rast()` function).
#' @param pathSoil character. File path to directory with NATSGO soil rasters.
#' @param occ data frame. Contains species occurrence or background points data for extraction.
#' @param lon character. Variable name for longitude values in occ df (default = "lon")
#' @param lat character. Variable name for the latitude values in occ df (default = "lat")
#' @param crs character. The coordinate reference system of the spp occurrence data (default = "WGS84")
#' @return data frame with environmental values at point of species observation


env_extract <- function(startYear, endYear, pathMonth, pathQuarter, pathSoil,
                        occ, lon = "lon", lat = "lat", crs = "WGS84") {
  
  ## Warnings
  if (startYear < 2000)
    warning("This function was built with a dataset starting in water year 2000. \nEnsure your start year matches with available data.")
  if (endYear >2022)
    warning("This function was built with a dataset ending at water year 2022.\nEnsure your end year matches with available data.")

  
  ## Create df for range of dates -----------------------------------------
  dates_df <- data.frame(wy = rep(startYear:endYear, each = 12), 
                         ### Repeat each yr 12 times to create a row 
                         ### for each mo/yr
                         mon = c('oct', 'nov', 'dec', 'jan', 'feb', 'mar', 
                                 'apr', 'may', 'jun', 'jul', 'aug', 'sep'),
                         mon_num = rep(c(10:12, 1:9), each=1)) %>% 
    ## generate calendar year from wy 
    mutate(year = case_when(mon_num %in% c(10, 11, 12) ~(.$wy-1),
                            .default = .$wy))
  
  ## Progress bar (fxn can take long time to run) -------------------------
  runLength <- nrow(dates_df)
  pb <- txtProgressBar(min = 0,
                       max = runLength,
                       style = 3,
                       width = runLength,
                       char = "=")

  
  ## Extract loop --------------------------------------------------
  ## empty df to store loop results
  extract_df <- data.frame()
    
    ## LOOP START 
    ## run through every month of time period
    for (i in 1:nrow(dates_df)) {
      
      ## Filter obs to mo/yr
      occ_filter <- occ %>% 
        filter(year == dates_df$year[i],
               month == dates_df$mon_num[i])
      
      ## If filtered df has obs for that month, 
      ## then read in env data, vectorize occ data, and extract.
      if(nrow(occ_filter) > 0) {
          ## List of monthly raster files
          filesMonth <- list.files(
            path = pathMonth,
            ## only list those with matching yr/mo in name
            pattern = paste0(dates_df$year[i], dates_df$mon[i]),
            full.names = TRUE
          )
          ## List of quarterly raster files
          filesQuarter <- list.files(
            path = pathQuarter,
            pattern = paste0(dates_df$wy[i]),
            full.names = TRUE
          )
          ## Soil properties
          filesSoil <- list.files(
            path = pathSoil,
            pattern = paste0("natsgo_", ".+", ".tif"),
            full.names = TRUE
          )
          ## Stack all rasters
          env_stack <-
            terra::rast(c(filesMonth, filesQuarter, filesSoil))
        
          ## vectorize and reproject to env data crs
          occ_vect <- occ_filter %>%
            terra::vect(geom = c(lon, lat), crs = crs) %>%
            terra::project(., y = crs(env_stack))
          
          ## extract and tidy df
          sppExtract <- extract(env_stack, occ_vect, 
                                method = "simple", ID = FALSE) %>% 
              ## only keep first 3 chars of monthly columns
              ## (e.g. "cwd2021jan" becomes "cwd")
              rename_with(.fn= ~substr(., 1, 3), 
                          ## only for columns of monthly variables
                          .cols = 1:length(filesMonth)) %>% 
              ## rename quarterly rasts; replace wy with _
              ## (e.g. "ppt2021winter_mean" becomes "ppt_winter_mean")
              rename_with(.fn= ~gsub(dates_df$wy[i], "_", x=.), 
                          ## only for columns of quarterly variables
                          .cols = (length(filesMonth)+1):(ncol(.)-length(filesSoil))) %>% 
              ## merge occ data w/extract data
              cbind(occ_filter, .)
          
          ## append results to df
          extract_df <- rbind(extract_df, sppExtract)
          
      ## If no obs for a yr/mo, skip  
      } else {
        next
      } ### END if/else statement
      
      setTxtProgressBar(pb, i)
      
    } ### END LOOP

  return(extract_df)
  
} ### end fxn