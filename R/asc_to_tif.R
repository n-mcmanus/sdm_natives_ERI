#' ASCII to TIF
#'
#' This function converts .asc files to .tif format. This is particularly 
#' useful for converting BCMv8 data, as .tif format saves time/space to 
#' work with and has explicit crs.
#' 
#' @author Nick McManus
#' @param filepath character. Path to directory of .asc files
#' @param crs character. Coordinate reference system associated with the .asc files (default = EPSG:3310)
#' @param remove logical. If `TRUE`, removes all .asc files from directory (default = FALSE)
#' @return files in .tif format with crs

asc_to_tif <- function(filepath, crs = "epsg: 3310", remove = FALSE) {

  ## Assign file path (selects all .asc files in directory)
  files_asc <- list.files(path = filepath,
                          pattern = '\\.asc$',
                          full = TRUE)
  ## Saves files w/same name but as .tif
  files_tif <- gsub("\\.asc$", ".tif", files_asc)
  
  ## Combine file paths into one df for pmap usage
  files_df <- data.frame("files_asc" = files_asc,
                         "files_tif" = files_tif)
  
  
  ## Function to convert and save ASC as TIF
  convert <- function(files_asc, files_tif, crs = crs) {
    r <- terra::rast(files_asc)
    crs(r) <- crs
    writeRaster(r, files_tif)
  }
    
  ## Iterate fxn for list of files
  purrr::pmap(files_df, convert, crs, .progress = TRUE)
  
  ## Optional: Remove original .asc files
  if (remove == TRUE) {
    file.remove(files_asc)
  }
  
}
