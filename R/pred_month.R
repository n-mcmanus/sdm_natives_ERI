#' Predict suitability by month
#'
#' This function reads in a folder of monthly averages for environmental data
#' (created using env_avg function), then maps predicted suitability from
#' a Maxent model by month. The outputs are 12 rasters, one for each month,
#' matching the extent, resolution, and crs of th einput files. 
#' 
#' @author Nick McManus
#' @param model the Maxent model used for predicting suitability
#' @param pathIn path to input directory of env data monthly average rasters
#' @param pathOut path to output directory where new rasters will be saved
#' @return 12 TIFs with predicted habitat suitability by month


pred_month <- function(model, pathIn, pathOut) {
  
  ## Create df for variables to avg  -----------------------------------------
  names_df <- data.frame(vars = rep(variables, each = 12),
                         month = c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
                                   'jul', 'aug', 'sep', 'oct', 'nov', 'dec'))
  
  
  ## Monthly pred fxn --------------------------------------------------------
  pred_fxn <- function(model, months, pathIn, pathOut) {
      ## Read each variable and mask to AET (areas of NA)
      aetFile <- list.files(path = pathIn,
                            pattern = paste0("aet", ".+", months),
                            full = TRUE)
      aet <- terra::rast((aetFile))
      
      pptFile <- list.files(path = pathIn,
                            patter = paste0("ppt",".+", months),
                            full = TRUE)
      ppt <- terra::rast(pptFile)  %>% 
        terra::mask(., aet)
      
      tmnFile <- list.files(path = pathIn,
                            patter = paste0("tmn",".+", months),
                            full = TRUE)
      tmn <- terra::rast(tmnFile) %>% 
        terra::mask(., aet)
      
      tmxFile <- list.files(path = pathIn,
                            patter = paste0("tmx",".+", months),
                            full = TRUE)
      tmx <- terra::rast(tmxFile)  %>% 
        terra::mask(., aet)
      
      ## Find temp mean and difference
      tmean <- (tmx+tmn)/2
      tdiff <- tmx-tmn
      
      ## Convert to rasterLayers, stack, and name layers
      aet <- raster(aet)
      tmean <- raster(tmean)
      tdiff <- raster(tdiff)
      
      stack <- raster::stack(aet, tmean, tdiff)
      names(stack) <- c('aet','tmean','tdiff')
      
      ## Predict suitability with model, then save raster
      pred <- dismo::predict(model, stack)
      writeRaster(pred, paste0(pathOut, months, '_pred.tif'), overwrite=TRUE)
  } ### END `pred_fxn()`
  
  ## Iterate fxn over list of months ---------------------------------------
  purrr::pmap(months, pred_fxn, model=model, pathIn, pathOut, .progress = TRUE)
  
} ### END SCRIPT