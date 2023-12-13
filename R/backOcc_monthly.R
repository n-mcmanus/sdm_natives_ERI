#' Background (pseudo-absence) point  generation
#'
#' This function creates background points within a buffered range of supplied 
#' occurrence data (`sppOcc`). The temporal distribution of background points 
#' (by month of year) matches that of the occurrence data.
#' 
#' @author Nick McManus
#' @param sppOcc data frame. Contains species occurrence points, with x and y as separate variables and a dates variable as a "Date" class
#' @param back_n integer. Number of background points to be generated (default = 10000)
#' @param raster SpatRaster (terra raster format). Reference raster for the spatial resolution of background points. 
#' As written, no more than one point will be generated per raster cell. Recommended that raster matches the spatial resolution of occurrence data.
#' @param buffer integer. Distance (in meters) from occurrence points to generate background points.
#' @param lon character. Variable name for longitude values in occ df (default = "lon")
#' @param lat character. Variable name for the latitude values in occ df (default = "lat")
#' @param crs character. The coordinate reference system of the spp occurrence data (default = "WGS84")
#' @return data frame with coordinates, month, and year of background points


backOcc_byMonth <- function(sppOcc, raster, buffer, back_n = 10000,
                        lon = "lon", lat = "lat", crs = "WGS84") {
  
  ## Vectorize sppOcc, find convex hull of pts, then add buffer
  sppZone <- terra::convHull(terra::vect(sppOcc, 
                                         geom = c(lon, lat),
                                         crs = crs)
                             ) %>% 
    terra::buffer(., width = buffer)
  
  ## Keep only area of reference raster w/in sppZone
  rast <- raster %>% 
    terra::project(y=crs(sppZone)) %>% 
    terra::crop(y=sppZone, mask = TRUE)
  ## Raster pkg format req for dismo pkg  
  r <- raster::raster(rast)
  
  ## Find occ ratio to apply to bkg pts
  occ_count <- sppOcc %>% 
    ## only keep occs in 2000-2022 wy
    mutate(date = lubridate::floor_date(date, unit="months")) %>% 
    dplyr::filter(date < "2022-10-01") %>% 
    ## find counts and % counts for each month
    mutate(year = lubridate::year(date),
           month = lubridate::month(date)) %>%
    group_by(year, month) %>% 
    summarize(occ_n = n()) %>% 
    mutate(occ_n_pct = occ_n/sum(.$occ_n))
  
  ## Df of every month in time range to loop through
  dates <- data.frame(month = rep(1:12, each = 1),
                      year = rep(2000:2022, each = 12))
  dates <- rbind(tail(dates, 3), head(dates, -3))
  dates[1:3, 2] = (dates[4,2] - 1)
  
  ## Start df for loop ()
  backOcc_total <- data.frame("x" = NA, "y" = NA, "month"=NA, "year"=NA)
  
  ## Loop through every mo/yr to generate bkg pts
  ## matching ratio of occs
  for (i in 1:nrow(dates)) {
    occ_filt <- occ_count %>% 
      dplyr::filter(year == dates$year[i] & month == dates$month[i])
    
    ## If occs, then generate bkg pts based on occ ratio
    if(nrow(occ_filt) != 0) {
      
      ## number pts to be generated for mo/yr
      n <- round(occ_filt$occ_n_pct * back_n, 0)
    
      backOcc <- dismo::randomPoints(mask = r, 
                                     n = n,  
                                     prob = FALSE,
                                     ## ensures two points don't occur
                                     ## in same cell
                                     p = backOcc_total,
                                     excludep = TRUE)
      ## Assign mo/yr to new bkg pts
      backOcc_dates <- cbind(backOcc, 
                             data.frame(month = dates$month[i],
                                        year = dates$year[i]))
      ## Bind loop results to ongoing df
      backOcc_total <- rbind(backOcc_total, backOcc_dates)
    
    ## if no occs in month, skip to next   
    } else {
      next
    }
    
  }##End loop
  
  ## Remove placeholder "NA" row
  backOcc_total <- backOcc_total[-1,]
  return(backOcc_total)
  
}## End fxn