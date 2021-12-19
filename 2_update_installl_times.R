	rm(list = ls())

	path.file.rds <-  "cran.times.rds"
	path.file.csv <-  "cran.times.csv"

#Off public_html path to home directory with wasabi credentials and R library
	home_path = dirname(dirname(getwd()))
	.libPaths(file.path(home_path, "/R/lib/"))

#Load packages
	library(aws.s3)
	library('XML')
    

#Setup wasabi (S3 provider, http://wasabisys.com) credentials to save directly to bucket, 
	#Credentials saved off git directory
	credentials.list = readRDS(file.path(home_path,"wasabi_credentials.rds"))
	Sys.setenv(
			'AWS_S3_ENDPOINT' = credentials.list$endpoint,
			"AWS_ACCESS_KEY_ID" = credentials.list$key,
			"AWS_SECRET_ACCESS_KEY" = credentials.list$secret,
			"AWS_DEFAULT_REGION" = credentials.list$default_region
			)
	
  
  #1. load existing times
		existing=readRDS(path.file.rds)
	
  #2 Back it up
		path.today.backup.rds=paste0("backups/cran ",Sys.Date(),".rds") 
		saveRDS(existing,path.today.backup.rds,version=2,compress = "xz")
	
	#3 URL for new times
	  #3.1 Ge most current R version in cran toc rds
		  cran.toc.rds <- readRDS('cran.toc.rds')
		  r.toc <- subset(cran.toc.rds,Package=='R')
		  r.max.full <- max(r.toc$Version)
		  r.max.split <- strsplit(r.max.full,'.', fixed=T)[[1]]
		  r.max <- paste0(r.max.split[1],".",		  r.max.split[2])
		
		#3.2 The URL includes both the R version and the data
		  url= paste0("https://cloud.r-project.org/bin/windows/contrib/" , r.max , "/stats/Status_", Sys.Date()-2);


	#4 Read the data 
		  new <- read.delim(url,sep=" ")
		  
	#5 Process new data
		  new <- subset(new,select=c('packages','version','insttime'))         #Subset variables
  	  names(new) <- c("pkg", "vrs","installation.time")                    #Rename them
		  new$pkg_vrs <- paste0(new$pkg,"_",new$vrs)                           #Add pkg_vrs 
		  new <- new[,c(4,3)]                                                  #Keep only pkg_vrs and time
		  new$installation.time <- as.numeric(as.character(new$installation.time))
		  new <- new[complete.cases(new),]

	#6 Drop existing rows with packages we will add (effectively, update install time)
		  existing.without_new= existing[!existing$pkg_vrs %in% new$pkg_vrs,]
		  updated=rbind(new, existing.without_new)
		  
	#7 Save locally (compressed)
      saveRDS(updated, path.file.rds,version=2,compress = "xz")     #In .rds format, version=2 is for backwards compatibility with earlier R versions
      write.csv(updated, path.file.csv,row.names=FALSE)
      
  #8 Save to wasabi
		put_object(
       file = path.file.rds, 
        object = path.file.rds, 
        bucket = "groundhog"
        )
  
  

    
    
    
    
    
    