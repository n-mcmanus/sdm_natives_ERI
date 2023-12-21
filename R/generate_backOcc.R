#' Background (pseudo-absence) point  generation
#'
#' This function creates background points within a buffered range of supplied 
#' occurrence data (`sppOcc`). The temporal distribution of background points 
#' by year matches that of the occurrence data.
#' 
#' @author Nick McManus
#' @param sppOcc data frame. Contains species occurrence points, with x and y as separate variables and a dates variable as a "Date" class
#' @param back_n integer. Target number of background points to be generated (default = 10000). Function will likely return slightly larger number
#' @param raster SpatRaster (terra raster format). Reference raster for the spatial resolution of background points. 
#' As written, no more than one point will be generated per raster cell. Recommended that raster matches the spatial resolution of occurrence data.
#' @param buffer integer. Distance (in meters) from occurrence points to generate background points.
#' @param lon character. Variable name for longitude values in sppOcc df (default = "lon")
#' @param lat character. Variable name for the latitude values in sppOcc df (default = "lat")
#' @param crs character. The coordinate reference system of the sppOcc occurrence data (default = "WGS84")
#' @return data frame with coordinates, month, and year of background points


backOcc <- function(sppOcc, raster, buffer, back_n = 10000,
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
    mutate(wy = lfstat::water_year(.$date, origin = 10),
           wy = as.numeric(levels(wy))[wy]) %>% 
    dplyr::filter(wy >= 2000 & wy <= 2022) %>% 
    ## find counts and % counts for each water year
    group_by(wy) %>% 
    summarize(occ_n = n()) %>% 
    mutate(occ_n_pct = occ_n/sum(.$occ_n))
  
  ## list of water years
  w_years <- rep(2000:2022, each = 1)
  
  ## Start df for loop ()
  backOcc_total <- data.frame("x" = NA, "y" = NA, 
                              "month"=NA, "year" = NA, "wy" = NA)
  
  ## Progress bar (fxn can take long time to run)
  runLength <- length(w_years)
  pb <- txtProgressBar(min = 0,
                       max = runLength,
                       style = 3,
                       width = runLength,
                       char = "=")
  
  ## Loop through every yr to generate bkg pts ----------------------------
  for (i in 1:length(w_years)) {
    occ_filt <- occ_count %>% 
      dplyr::filter(wy == w_years[i])
    
    ## If occs in wy, then generate number bkg pts based on occ ratio
    if(nrow(occ_filt) != 0) {
      ## number pts to be generated rounded up to be equal per month
      roundUp <- function(x) {12*ceiling(x/12)}
      x <- ceiling(occ_filt$occ_n_pct * back_n)
      n <- roundUp(x)
      
      ## Generate random pts
      backOcc <- as.data.frame(
        dismo::randomPoints(mask = r, 
                            n = n,  
                            prob = FALSE,
                            ## ensures two points don't occur
                            ## in same cell
                            p = backOcc_total,
                            excludep = TRUE)
        )
      
      ## Assign mo/yr to new bkg pts
      dates <- data.frame(month = rep(c(10:12, 1:9), 
                                      each = (n/12)),
                          wy = w_years[i])
      backOcc_dates <- cbind(backOcc, dates) %>% 
        ## want calendar year for later extraction
        mutate(year = case_when(month %in% c(10, 11, 12) ~(w_years[i]-1),
                                .default = w_years[i]))
      
      ## Bind loop results to ongoing df
      backOcc_total <- rbind(backOcc_total, backOcc_dates)
    
    ## if no occs in month, skip to next   
    } else {
      next
    }
    setTxtProgressBar(pb, i)
    
  }##End loop
  
  ## Remove placeholder "NA" row
  backOcc_total <- backOcc_total[-1,] %>% 
    dplyr::select(!wy)
  return(backOcc_total)
  
}## End fxn
