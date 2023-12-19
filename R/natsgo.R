#' Prepare gNATSGO data for point extraction
#'
#' This function performs a series of joins to relate horizon-level soil data
#' (pH, % organic matter, and cation exchange capacity) to larger mapunits. 
#' A cutoff soil depth (`depth`) is provided, and a weighted average for each
#' soil variable within a component is calculated based on thickness of each horizon.
#' Then, a weighted average of component-level data is found by % area within
#' a mapunit. The resulting CSV of aggregated soil data by mapunit is used 
#' for extraction in the `env_extract()` function.#' 
#' 
#' @author Nick McManus
#' @param horizon dataframe of horizon-level gNATSGO data
#' @param component dataframe of component-level gNATSGO data
#' @param mapunit dataframe of mapunit-level gNATSGO data
#' @param depth numeric. Cutoff depth (cm) for averaging horizon data
#' @param pathOut character. Directory file path where .csv will be written
#' @return CSV with averaged and aggregated soil data (pH, %OM, CEC) by mapunit


natsgo_avg <- function(horizon, component, mapunit, depth, pathOut) {
  
  ## Remove variables with all NAs
  not_all_na <- function(x) any(!is.na(x))
  
  horizon <- horizon %>% 
    select_if(not_all_na)
  component <- component %>% 
    select_if(not_all_na)
  mapunit <- mapunit %>% 
    select_if(not_all_na)
  
  ## HORIZON DATA ------------------------------------------------
  ## Remove horizons that start below cutoff depth
  horizon_depth = horizon %>%
    filter(hzdept_r < depth) %>%
    droplevels()
  
  ## Summarize vars of interest w/weighted mean 
  ## of horizon thickness (above cutoff)
  horizon_wmean = horizon_depth %>% 
    ## find thickness of each horizon
    mutate(thick = ifelse(hzdepb_r > depth, depth - hzdept_r,
                          hzdepb_r - hzdept_r)
           ) %>% 
    ## weighted mean of each variable by component
    group_by(cokey) %>% 
    summarize(om = round(weighted.mean(om_r, thick, na.rm = TRUE),2),
              cec = round(weighted.mean(cec7_r, thick, na.rm = TRUE),2),
              ph = round(weighted.mean(ph1to1h2o_r, thick, na.rm = TRUE),2)
              ) 
  
  ## COMPONENT DATA ------------------------------------------------
  ## Filter component data for vars of interest
  component = component %>% 
    dplyr::select(c(comppct_r, compname, mukey, cokey))
  
  ## join with horizon data
  component_horizon = left_join(component, horizon_wmean, by = "cokey")
  
  ## MAPUNIT DATA ------------------------------------------------
  ## Find weighted average of vars based on % component area in a mapunit
  full_soil = component_horizon %>%
    group_by(mukey) %>%
    summarize(om = round(weighted.mean(om, comppct_r, na.rm = TRUE),2),
              cec = round(weighted.mean(cec, comppct_r, na.rm = TRUE),2),
              ph = round(weighted.mean(ph, comppct_r, na.rm = TRUE),2)
              ) %>%
    ## join w/mapunit data
    left_join(., mapunit, by = "mukey") %>%
    ## convert commas to _ in muname so it's csv compatible
    mutate(muname = gsub(", ", "_", muname)) %>%
    ## remove mapunit variables we don't care about
    dplyr::select(!c(mukind:lkey)) %>%
    ## convert mukey from dbl to char for spatial join step
    mutate(mukey = as.character(mukey))
  
  ## Save as CSV
  write_csv(full_soil, 
            paste0(pathOut, "horizon", depth, "_CA.csv"))
  
} ### end fxn