# groundhog_server_scripts
Scripts that update the databse of CRAN packages used by the package groundhog 

We created an R Packaged called {groundhog} which allows installing package versions, and all their dependencies, as current on a user set date.
e.g., groundhog.library('dplyr', '2019-10-10') installs the popular package dplyr as current on that date.

In order to do this, groundhog.library() needs to look-up what version of the package was available on the set date, what dependencies it has, what version of those 
dependencies was current that date, what their dependencies were, ...

To do this we created a database listing all packages-versions in CRAN, their publish date, and their dependencies.
There are also two companionn databases with dates when the MRAN archieve (a daily snapshot of CRAN done by Microsoft) was not available, and how long each package version
takes to install from source.

These three database (stored as .rds files) are updated daily using R Scripts.

This git repository includes the R Scripts and relatively up to date versions of those databases.


