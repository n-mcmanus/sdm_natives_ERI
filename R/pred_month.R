#' Predict suitability by month
#'
#' This function reads in a folder of monthly averages for environmental data, 
#' then maps predicted suitability from a Maxent model by month. 
#' The outputs are 12 rasters, one for each month,
#' matching the extent, resolution, and crs of the input files. 
#' 
#' @author Nick McManus
#' @param model the Maxent model used for predicting suitability
#' @param spp the species being modeled
#' @param model_years the model and time range of supplied env variables. This is only used for file naming convention, so best to include future model with years for clarity (e.g. "2000_2022" or "MIROC45_2070_2099"). 
#' @param bcmPath path to directory of bcm monthly average rasters
#' @param soilPath path to directory of soil rasters
#' @param pathOut path to output directory where new rasters will be saved
#' @return 12 TIFs with predicted habitat suitability by month


pred_month <- function(model, spp, model_years, bcmPath, soilPath, pathOut) {
  
  ## List of months for map
  month <- c('jan', 'feb', 'mar', 'apr', 'may', 'jun',
             'jul', 'aug', 'sep', 'oct', 'nov', 'dec')
  
  
  ## Monthly pred fxn --------------------------------------------------------
  pred_fxn <- function(model, month, model_years, bcmPath, soilPath, pathOut) {
      ## Read each variable
      aet <- raster::raster(list.files(path = bcmPath,
                                       pattern = paste0("aet", ".+", month),
                                       full = TRUE))  
      tmx <- raster::raster(list.files(path = bcmPath,
                                       pattern = paste0("tmx",".+", month),
                                       full = TRUE))
      tdiff <- raster::raster(list.files(path = bcmPath,
                                         pattern = paste0("tdiff",".+", month),
                                         full = TRUE)) 
      # cwd <- raster::raster(list.files(path = bcmPath,
      #                                    pattern = paste0("cwd",".+", month),
      #                                    full = TRUE)) 
      # ppt <- raster::raster(list.files(path = bcmPath,
      #                                    pattern = paste0("ppt",".+", month),
      #                                    full = TRUE)) 
      tmxSummer <- raster::raster(list.files(path = bcmPath, 
                                             pattern = "tmx_summer",
                                             full = TRUE))
      pptWinter <- raster::raster(list.files(path = bcmPath, 
                                             pattern = "ppt_winter",
                                             full = TRUE))
      om <- raster::raster(list.files(path = soilPath,
                                      pattern = "_om_",
                                      full = TRUE))
      ph <- raster::raster(list.files(path = soilPath,
                                      pattern = "_ph_",
                                      full = TRUE))
      cec <- raster::raster(list.files(path = soilPath,
                                       pattern = "_cec_",
                                       full = TRUE))
      drclass <- raster::raster(list.files(path = soilPath,
                                           pattern = "_drclass_",
                                           full = TRUE))
      
      ## Stack and match lyr names to model variables
      stack <- raster::stack(aet, tdiff, tmx, tmxSummer, pptWinter, om, ph, cec, drclass)
      names(stack) <- c('aet','tdiff', 'tmx', 'tmx_summer_mean', 
                        'ppt_winter_sum', 'om', 'ph', 'cec', 'drclass')
      
      ## Predict suitability with model, then save raster
      pred <- dismo::predict(model, stack)
      writeRaster(pred, paste0(pathOut, month, '_', spp, '_', model_years, '.tif'), overwrite=TRUE)
  } ### END `pred_fxn()`
  
  ## Iterate fxn over list of months 
  purrr::map(month, pred_fxn, model=model, model_years,
             bcmPath, soilPath, pathOut, .progress = TRUE)
  
} ### END SCRIPT