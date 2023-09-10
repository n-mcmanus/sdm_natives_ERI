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
#' @param pathMonth path to directory with monthly rasters
#' @param pathQuarter path to directory with quarterly data
#' @param sppOcc data frame with species occurrences (or background points) for extraction
#' @param lon column name for longitude values in sppOcc dataframe (as character; default = "decimallongitude")
#' @param lat column name for the latitude values in sppOcc dataframe (as character; default = "decimallatitude")
#' @param crs The coordinate reference system of the spp occurrence data (as character; default = "WGS84")
#' @return data frame with environmental values at point of species observation


env_extract <- function(startYear, endYear, pathMonth, pathQuarter, sppOcc,
                       lon = "decimallongitude", lat = "decimallatitude", crs = "WGS84") {
  
  ## Warnings
  if (startYear < 2000)
    warning("This function was built with a dataset starting in water year 2000. \nEnsure your start year matches with available data.")
  if (endYear >2022)
    warning("This function was built with a dataset ending at water year 2022.\nEnsure your end year matches with available data.")

  
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
  dates_df <- mutate(dates_df,
                     wy = rep(startYear:endYear, each = 12))
  
  ## Progress bar (fxn can take long time to run) -------------------------
  runLength <- nrow(dates_df)
  pb <- txtProgressBar(min = 0,
                       max = runLength,
                       style = 3,
                       width = runLength,
                       char = "=")

  
  ## Monthly extract loop --------------------------------------------------
  
  ## empty df to store loop results
  extract_df <- data.frame()
  
  ## LOOP START
  for (i in 1:nrow(dates_df)) {
    ## List of monthly raster files
    files <- list.files(path = pathMonth, 
                        ## only list those with matching yr/mo in name
                        pattern= paste0(dates_df$year[i], dates_df$mon[i]), 
                        full=TRUE)
    
    ## List of quarterly raster files
    filesQuarter <- list.files(path = pathQuarter,
                               pattern = paste0(dates_df$wy[i]),
                               full = TRUE)
    
    ## Stack all rasters
    env_stack <- terra::rast(c(files, filesQuarter))
    
    ## Filter obs to yr/mo
    sppOcc_filter <- sppOcc %>% 
      filter(year == dates_df$year[i],
             month == dates_df$mon_num[i])
    
    ## If filtered df has obs, then vectorize and extract.
    if(nrow(sppOcc_filter) > 0) {
        ## vectorize and reproj to env data crs
        sppOcc_vect <- sppOcc_filter %>%
          terra::vect(geom = c(lon, lat), crs = crs) %>%
          terra::project(y = crs(env_stack))
        
        ## extract and tidy df
        sppExtract <- extract(env_stack, sppOcc_vect, method = "simple") %>%
          dplyr::select(-ID) %>% 
          ## only keep first 3 chars of monthly columns
          ## (e.g. "cwd2021jan" becomes "cwd")
          rename_with(.fn= ~substr(., 1, 3), 
                      .cols = 1:(nlyr(env_stack)-2)) %>% 
          ## rename last two rows (quarterly avgs)
          ## (e.g. "ppt2021winter" becomes "ppt_winter")
          rename_with(.fn= ~paste0(substr(.,1,3), "_", substr(.,8,13)), 
                      .cols = (ncol(.)-1):(ncol(.))) %>% 
          ## merge occ data w/extract data
          cbind(sppOcc_filter, .)
        
        ## append results to df
        extract_df <- rbind(extract_df, sppExtract)
      
    } else {
      ## If no obs for a yr/mo, skip
      next
    } ### END if/else statement
    
    setTxtProgressBar(pb, i)
    
  } ### END LOOP
  
  return(extract_df)
  
  # 
  # 
  # ## Quarterly extract loop ----------------------------------------------------
  # 
  # ### Winter ppt ------------------------------------------
  # ngroups <- nrow(dates_df)/12
  # winter_df <- dates_df %>%  
  #   mutate(wy = rep(startYear:endYear, each = 12))
  # 
  # #### for-loop 1
  # for (i in 1:length(unique(winter_df$group))) {
  #   quarter_df <- winter_df %>% 
  #     filter(group == i)
  #   
  #   ## Read in raster
  #   winter_rast <- terra::rast(paste0(pathQuarter, 
  #                                     "ppt", 
  #                                     quarter_df$year[2],
  #                                     "winter.tif"))
  #   ## Rename rast (will become var name in extract df)
  #   names(winter_rast) <- "ppt_winter"
  #   
  #   #### for-loop 2
  #   for (j in 1:nrow(quarter_df)) {
  #     ## Filter obs to yr/mo
  #     sppOcc_winter <- sppOcc %>% 
  #       filter(year == quarter_df[j,1],
  #              month == quarter_df[j,3])
  #     
  #     
  #     ## If filtered df has obs, then vectorize and extract
  #     if(nrow(sppOcc_winter) > 0) {
  #       ## vectorize and reproj to env data crs
  #       sppOcc_winter_vect <- sppOcc_winter %>%
  #         terra::vect(geom = c(lon, lat), crs = crs) %>%
  #         terra::project(y = crs(winter_rast))
  #       
  #       ## extract and tidy df
  #       sppExtract_winter <- extract(winter_rast, 
  #                                    sppOcc_winter_vect, 
  #                                    method = "simple") %>%
  #         ## merge occ data w/extract data
  #         cbind(sppOcc_winter, .) %>%
  #         dplyr::select(-ID)
  #       
  #       ## append results to df
  #       extractWinter_df <- rbind(extractWinter_df, sppExtract_winter)
  #       
  #     } else {
  #       ## If no obs for a yr/mo, skip
  #       next
  #     } ### END if/else statement
  #   }### END for-loop 2
  #   
  # }### END for-loop 1
  # 
  # 
  # ## Join winter and monthly
  # extract_df <- left_join(x=extractMonth_df, y=extractWinter_df)
  # 
  # 
  # ### Summer tmax ------------------------------------------------
  # summer_df <- dates_df %>% 
  #   filter(mon %in% c('jun', 'jul', 'aug')) %>% 
  #   mutate(group = rep(1:(nrow(.)/3), each = 3))
  # 
  # #### for-loop 1
  # for (i in 1:length(unique(summer_df$group))) {
  #   quarter_df <- summer_df %>% 
  #     filter(group == i)
  #   
  #   ## Read in raster
  #   summer_rast <- terra::rast(paste0(pathQuarter, 
  #                                     "tmx", 
  #                                     quarter_df$year[2],
  #                                     "summer.tif"))
  #   names(summer_rast) <- "tmx_summer"
  #   
  #   #### for-loop 2
  #   for (j in 1:nrow(quarter_df)) {
  #     ## Filter obs to yr/mo
  #     sppOcc_summer <- sppOcc %>% 
  #       filter(year == quarter_df[j,1],
  #              month == quarter_df[j,3])
  #     
  #     
  #     ## If filtered df has obs, then vectorize and extract
  #     if(nrow(sppOcc_summer) > 0) {
  #       ## vectorize and reproj to env data crs
  #       sppOcc_summer_vect <- sppOcc_summer %>%
  #         terra::vect(geom = c(lon, lat), crs = crs) %>%
  #         terra::project(y = crs(summer_rast))
  #       
  #       ## extract and tidy df
  #       sppExtract_summer <- extract(summer_rast, 
  #                                    sppOcc_summer_vect, 
  #                                    method = "simple") %>%
  #         ## merge occ data w/extract data
  #         cbind(sppOcc_summer, .) %>%
  #         dplyr::select(-ID)
  #       
  #       ## append results to df
  #       extractSummer_df <- rbind(extractSummer_df, sppExtract_summer)
  #       
  #     } else {
  #       ## If no obs for a yr/mo, skip
  #       next
  #     } ### END if/else statement
  #   }### END for-loop 2
  #   
  # }### END for-loop 1
  # 
  # 
  # ## Join summer and monthly
  # extractAll_df <- left_join(x=extract_df, y=extractSummer_df)
  # 
  # 
  # 
  # 
  # return(extractAll_df)
  
  
} ### end fxn