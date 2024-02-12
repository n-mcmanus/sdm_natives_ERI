## Overview:
This repository contains the script and functions used for modeling the distribution for native plant species of interest within Kern County, CA. Due to size limitations, most raw and spatial data for this analysis is not hosted in the repo. Short descriptions of the data used, how they were obtained, and links to hosted data (where applicable) are provided in the "Data sources" section. Although not all pushed, the file structure and contents of the data directory is provided as well. 

## Code:
The analysis was divided between three different scripts, all found in the `src/` directory:
* `env_data_prep.Rmd` contains the code used to download and/or wrangle the environmental data used in the SDM (BCM and gNATSGO).
* `spp_occ_background.Rmd` is the script for downloading and wrangling species occurrence data as well as generating background points (pseudo-absences) for each species. Environmental variables are extracted for occurrence and background points to prepare the data in samples with data (SWD) format for the SDM.
* `kern_sdm.Rmd` evaluates the prepared data, then runs the SDMs for each species. Suitability probability distribution maps are also generated for each species by month.

Note that all of these scripts call on functions located in the `R/` directory of this repository. 
 * `asc_to_tif.R` converts BCMv8 data in .asc format to .tif
 * `quarterly_rast.R` generates seasonal (winter or summer) rasters by water year from monthly BCMv8 data.
 * `natsgo_agg.R` aggregates horizon-level gNATSGO soil data by map unit
 * `env_extract.R` extracts environmental data by year, month, and grid location of species occurrence and background data
 * `generate_backOcc.R` generates background points within a specified buffer of species occcurrences
 * `pred_month.R` produces suitability probability distribution maps for each month based on a provided SDM

## Data sources:
### Species occurrences:
* **<ins>GBIF:</ins>** Data were obtained from the Global Biodiversity Information Facility (GBIF) using the `rgbif` [package](https://docs.ropensci.org/rgbif/ "rgbif vignettes") and further filtered using the `CoordinateCleaner` [package](https://ropensci.github.io/CoordinateCleaner/index.html "CoordinateCleaner vignettes"). The rgbif package requires providing GBIF log-in credentials; instructions on setup can be found [here](https://docs.ropensci.org/rgbif/articles/gbif_credentials.html "GBIF setup"). 
* **<ins>CalFlora:</ins>** Data were directly downloaded from the CalFlora observation search [portal](https://www.calflora.org/entry/observ.html "CalFlora"). A single CSV was downloaded for each species; these were further filtered in the `spp_occ_background.Rmd` script.

### Environmental data:
* **<ins>BCMv8:</ins>** Climatic variables such as monthly max temperature, precipitation, AET, PET, and CWD were sourced from Basin Characterization Model (version 8). Data for each variable is available by month and year (for water years 1896-2022) in .asc format. More information on this model can be found on the [USGS website](https://www.usgs.gov/publications/basin-characterization-model-a-regional-water-balance-software-package "Model report"), and data can be downloaded directly from the [USGS ScienceBase repository](https://www.sciencebase.gov/catalog/item/5f29c62d82cef313ed9edb39 "BCMv8 Repository")
* **<ins>gNATSGO:</ins>** Soil data such as pH, percent organic matter, and cation exchange capacity were obtained from the gridded National Soil Survey Geographic Database (gNATSGO). NATSGO combines data from the Soil Survey Geographic Database (SSURGO) and State Soil Geographic Databse (STATSGO), prioritizing SSURGO data where available and filling in missing areas with lower-level STATSGO data. More information and links for direct download by state are available on the USDA's Natural Resource Conservation Service [website.](https://www.nrcs.usda.gov/resources/data-and-reports/gridded-national-soil-survey-geographic-database-gnatsgo)

## Data directory:
* `background\`: contains the randomly generated backgrount points for each species. Naming convention of files is "back_species_buffersize_occfilter.csv" (e.g. back_a_menziesii_5km_lowFilter.csv)
* `occ\`: contains the raw and filtered species occurrence data pulled from two databases
  * `calflora\`: species occurrence data from CalFlora, filtered and saved as .csv files. Naming convention is "species_calflora_occfilter.csv" (e.g. a_menziesii_calflora_lowFilter.csv)
      * `download\`: the raw .csv files as downloaded from the CalFlora website, filtered and saved in the parent directory
  * `gbif\`: species occurrence data pulled from GBIF using the `rgbif` package, filtered, and then saved as a .csv. Naming convention is "species_gbif.csv" (e.g. a_menziesii_gbif.csv)
  * `combined_spp_occ\`: species occurrence data from GBIF and CalFlora combined, spatially thinned, and saved as a .csv. Naming convention is "species_occfilter.csv" (e.g. a_menziesii_lowFilter.csv)
* `swd\`: species occurrence and background data formatted in "samples with data" (SWD) format for running in MaxEnt. These data have extracted environmental data by date and location of occurrence. Directory is divided into one folder per species. Each species contains a file for extracted occurrence data ("occExtract_"), extracted background data ("backExtract_"), and combined occurrence+background data in SWD format ("swd_"). Extracted soil data has been aggregated to a user-defined depth. Naming convention is "fileextract_species_soildepth_occFilter.csv" (e.g. backExtract_a_menziesii_soil200cm_lowFilter.csv)
* `bcm\`: directory with all the BCM data, both historic and future
   * `bcmv8_historic\`: contains rasters of the BCM version 8, 2021 release "historic" monthly data
      * `2000_2022_monthly\`: monthly data (270m rasters) for water years 2000-2022 for the following variables: AET, PET, CWD, PPT, TMN, TMX. Naming convention is "variable+wateryear+month.tif" (e.g. aet2018oct.tif)
      * `monthly_avgs\`: Averaged rasters (270m) by variable and month over the entire time period (2000-2022). Naming convention is variable_month_avg.tif (e.g. aet_oct_avg.tif)
      * `quarterly_avgs\`: Rasters (270m) of cumulative precip or average tmax by quarter of water year. Winter quarter includes Dec, Jan, Feb. Summer quarter includes Jun, Jul, Aug. Naming convention is variable+wateryear+quarter_method (e.g. ppt2018winter_sum.tif).
   * `bcm_future\`: contains projected data from the BCM, 2014 release
* `natsgo\`: contains the gNATSGO data, but downloaded and generated, used for the analysis. 
   * `gNATSGO_CA\`: contains the geodatabase for California gNATSGO, 2023 release.
   *  `rasters\`: includes the mapunit raster (10m) exported from the geodatabase using ArcGIS, the map unit raster upscaled to 270m, and four rasters for each soil variable included in the model. Naming convention is "natsgo_variable_resolution_CA_2023.tif" (e.g. natsgo_ph_270m_CA_2023.tif)
   *  `horizon_200cm_CA.csv`: data frame output with horizon-level soil data (down to 200cm depth) aggregated by map unit.
* `maxent_outputs\`: the model outputs and monthly suitability prediction maps. There is a separate subdirectory for each species.
   * `model\`: all the model outputs from running MaxEnt via dismo. These include response curve plots and a model summary titled "maxent.html". Each model was saved to later be read-in for generating suitability maps. The naming convention is "species_sdm.rData" (e.g. a_menziesii_sdm.rData)
   * `monthly_dist_hist\`: monthly suitability distribution rasters (270m) based on historic (2000-2022) BCM data. Naming convention is "month_species_2000_2022.tif" (e.g. oct_a_menziesii_2000_2022.tif)

