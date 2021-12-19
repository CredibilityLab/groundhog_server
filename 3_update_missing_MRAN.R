

	rm(list = ls())
	


#Off public_html path to home directory with wasabi credentials and R library
	home_path = dirname(dirname(getwd()))
	.libPaths(file.path(home_path, "/R/lib/"))

#Load packages
	library(aws.s3)
	library('XML')           

#Setup wasbi credentials to save directly to bucket
	home_path = dirname(dirname(getwd()))
	credentials.list = readRDS(file.path(home_path,"wasabi_credentials.rds"))
	Sys.setenv(
			'AWS_S3_ENDPOINT' = credentials.list$endpoint,
			"AWS_ACCESS_KEY_ID" = credentials.list$key,
			"AWS_SECRET_ACCESS_KEY" = credentials.list$secret,
			"AWS_DEFAULT_REGION" = credentials.list$default_region
			)
	



	#library to read files in snapshot directory
  URL="https://cran.microsoft.com/snapshot/"           #URL to directory
  rows <- scan(URL,what='character')                   #Read the directory
  dates.listed1=getHTMLLinks(rows)                     #Extract directories (one per date)
  dates.listed2=substr(dates.listed1,1,10)             #Kill the trailing /
  dates.listed3=dates.listed2[nchar(dates.listed2)==10]#Drop . and ..
  dates.listed4=as.Date(dates.listed3)                 #make them dates

  
#Range of possible dates
  from=as.Date("2014-09-18")
  till=Sys.Date()-2
  all.dates=from:till  

#Gap between dates listed in MRAN and those that could be listed
  new.missing=all.dates[!all.dates %in% dates.listed4]
  new.missing=as.Date(new.missing,origin='1970-01-01')
  
#Load old missing
  old.missing=readRDS("missing.mran.dates.rds")      
  
#Compare lengths
  if (length(new.missing)!=length(old.missing))
  {
  saveRDS(new.missing,"missing.mran.dates.rds",version=2)
  write.csv(new.missing,"missing.mran.dates.csv")
  }

  
  
#Save to wasabi
		put_object(
		file = "missing.mran.dates.rds", 
        object = "missing.mran.dates.rds", 
        bucket = "groundhog"
        )
  