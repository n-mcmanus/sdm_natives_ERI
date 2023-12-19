# sdm_natives_ERI
Distribution modelling for native species of interest within Kern County, CA

This repository contains three different scripts:
* `env_data_prep.Rmd` contains the code used to download and/or wrangle the environmental data used in the SDM.
* `spp_occ_background.Rmd` is the script for downloading and preparing species occurrence data as well as generating background (pseudo-absence) data for the SDM.
* `kern_sdm.Rmd` preps the data in a samples with data (SWD) format, then runs the SDMs for each species. 

Note that all of these scripts call on functions that are located in the `R/` directory of this repository. 

## <ins>Data:</ins>
Below are short descriptions of the data used in this analysis, how it was obtained, and links to the hosted data (where applicable). 

### Species occurrences:
* GBIF: 
* CalFlora
* VegBank

### Environmental data:
* **<ins>BCMv8:</ins>** Climatic variables such as monthly min/max temperature, precipitation, AET, PET, and CWD were sourced from Basin Characterization Model (version 8). Data for each variable is available by month and year (for water years 1896-2022) in .asc format. More information on this model can be found on the [USGS website](https://www.usgs.gov/publications/basin-characterization-model-a-regional-water-balance-software-package "Model report"), and data can be downloaded directly from the [USGS ScienceBase repository](https://www.sciencebase.gov/catalog/item/5f29c62d82cef313ed9edb39 "BCMv8 Repository")
* **<ins>gNATSGO:</ins>** Soil data such as pH, percent organic matter, and cation exchange capacity were obtained from the gridded National Soil Survey Geographic Database (gNATSGO). NATSGO combines data from the Soil Survey Geographic Database (SSURGO) and State Soil Geographic Databse (STATSGO), prioritizing SSURGO data where available and filling in missing areas with lower-level STATSGO data. More information and links for direct download by state are available on the USDA's Natural Resource Conservation Service [website.](https://www.nrcs.usda.gov/resources/data-and-reports/gridded-national-soil-survey-geographic-database-gnatsgo)
* **<ins>NLCD:</ins>** Land cover data, specifically locations of urban development, were obtained from the National Land Cover Database. These data were downloaded using the [FedData](https://github.com/ropensci/FedData "FedData GitHub") package.
  
