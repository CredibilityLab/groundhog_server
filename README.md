# groundhog_server_scripts
Scripts that update the databases used by groundhog (the r package, see https://groundhogr.com:
1) cran.toc.rds (most important): database with all package versions available on CRAN at any point
2) cran.times.rds: database with installation times for each package version, if installed from source (used to give estimates of completion times while installing.
3) missing.mran.data.rds: database with dats in which the MRAN database was not backedup by Microsoft, to avoid trying to get packages on those dates



