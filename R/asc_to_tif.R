#' ASCII to TIF
#'
#' This function converts .asc files to .tif format. This is particularly 
#' usefull for converting BCMv8 data, as .tif format saves time/space to 
#' work with and has explicit crs.
#' 
#' @author Nick McManus
#' @param filepath directory location of .asc files
#' @param crs coordinate reference system associated with the .asc files
#' @return files in .tif format with crs

asc_to_tif <- function(filepath, crs = "epsg: 3310") {

    ## Assign file path (selects all .asc files in directory)
    file_asc <- list.files(path = filepath, 
                           pattern='\\.asc$', 
                           full=TRUE)
    ## Saves files w/same name but as .tif
    file_tif <- gsub("\\.asc$", ".tif", file_asc)
    
    
    ## Progress bar (fxn can take long time to run)
    fileLength <- length(file_asc)
    pb <- txtProgressBar(min = 0,
                         max = fileLength,
                         style = 3,
                         width = fileLength,
                         char = "=")
    
    
    ## Loop to read in .asc, add crs, then output .tif
    for (i in 1:fileLength) {
      r <- rast(file_asc[i])
      crs(r) <- crs
      writeRaster(r, file_tif[i])
      
      setTxtProgressBar(pb, i)
    }

}