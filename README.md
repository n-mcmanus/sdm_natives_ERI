# sdm_natives_ERI
Distribution modelling for native species of interest within Kern County, CA

This repository contains three different scripts:
* `env_data_prep.Rmd` contains the code used to download and/or wrangle the environmental data used in the SDM.
* `spp_occ_background.Rmd` is the script for downloading and preparing species occurrence data as well as generating background (pseudo-absence) data for the SDM.
* `kern_sdm.Rmd` preps the data in a samples with data (SWD) format, then runs the SDMs for each species. 

Note that all of these scripts call on functions that are located in the R/ directory of this repository. 
