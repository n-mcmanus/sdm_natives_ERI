## Overview:
This repository contains the script and data used for modeling the distribution for native plant species of interest within Kern County, CA. 

The analysis is divided between three different scripts:
* `env_data_prep.Rmd` contains the code used to download and/or wrangle the environmental data used in the SDM.
* `spp_occ_background.Rmd` is the script for downloading and preparing species occurrence data as well as generating background (pseudo-absence) data for the SDM.
* `kern_sdm.Rmd` preps the data in a samples with data (SWD) format, then runs the SDMs for each species. 

Note that all of these scripts call on functions located in the `R/` directory of this repository. 

## Data:
Due to size limitations, the raw data for this analysis is not hosted in the repository. Short descriptions of the data used, how they were obtained, and links to hosted data (where applicable) are provided below. 
### Species occurrences:
* **<ins>GBIF:</ins>** Data were obtained from the Global Biodiversity Information Facility (GBIF) using the `rgbif` [package](https://docs.ropensci.org/rgbif/ "rgbif vignettes") and further filtered using the `CoordinateCleaner` [package](https://ropensci.github.io/CoordinateCleaner/index.html "CoordinateCleaner vignettes"). The rgbif package requires providing GBIF log-in credentials; instructions on setup can be found [here](https://docs.ropensci.org/rgbif/articles/gbif_credentials.html "GBIF setup"). 
* **<ins>CalFlora:</ins>** Data were directly downloaded from the CalFlora observation search [portal](https://www.calflora.org/entry/observ.html "CalFlora"). A single CSV was downloaded for each species; these were further filtered in the `spp_occ_background.Rmd` script.
* **<ins>VegBank:</ins>** Data were directly downloaded from the [VegBank website](http://vegbank.org/vegbank/forms/plot-query.jsp). Data for all plots of one species were downloaded and zipped as a "batch". Information about the plots, contributors, and all the percent cover of species are written as separate CSV files. 

### Environmental data:
* **<ins>BCMv8:</ins>** Climatic variables such as monthly min/max temperature, precipitation, AET, PET, and CWD were sourced from Basin Characterization Model (version 8). Data for each variable is available by month and year (for water years 1896-2022) in .asc format. More information on this model can be found on the [USGS website](https://www.usgs.gov/publications/basin-characterization-model-a-regional-water-balance-software-package "Model report"), and data can be downloaded directly from the [USGS ScienceBase repository](https://www.sciencebase.gov/catalog/item/5f29c62d82cef313ed9edb39 "BCMv8 Repository")
* **<ins>gNATSGO:</ins>** Soil data such as pH, percent organic matter, and cation exchange capacity were obtained from the gridded National Soil Survey Geographic Database (gNATSGO). NATSGO combines data from the Soil Survey Geographic Database (SSURGO) and State Soil Geographic Databse (STATSGO), prioritizing SSURGO data where available and filling in missing areas with lower-level STATSGO data. More information and links for direct download by state are available on the USDA's Natural Resource Conservation Service [website.](https://www.nrcs.usda.gov/resources/data-and-reports/gridded-national-soil-survey-geographic-database-gnatsgo)
* **<ins>NLCD:</ins>** Land cover data, specifically locations of urban development, were obtained from the National Land Cover Database. These data were downloaded using the `FedData` [package](https://github.com/ropensci/FedData "FedData GitHub").
  
