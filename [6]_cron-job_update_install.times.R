

	rm(list = ls())
	library('XML')
	path.file.rds <-  "cran.times.rds"
	path.file.csv <-  "cran.times.csv"

  
  #1. load existing times
		existing=readRDS(path.file.rds)
	
  #2 Back it up
		path.today.backup.rds=paste0("backups/cran ",Sys.Date(),".rds") 
		saveRDS(existing,path.today.backup.rds,version=2,compress = "xz")
	
	#3 URL for new times
		url= "https://cran.r-project.org/bin/windows/contrib/checkSummaryWin.html"
  
	#4 process results
		  new=try(data.frame(readHTMLTable(scan(url,what='character') ,what='character')[[1]]))
		  new=new[,c("X.Package.","X.Version.", "X.Inst..timing.")]                #Keep variables of interest
		  names(new)=c("pkg", "vrs","installation.time")                                 #Rename them
		  new$pkg_vrs=paste0(new$pkg,"_",new$vrs)                            #Add pkg_vrs 
		  new=new[,c(4,3)]            
		  new$installation.time=as.numeric(as.character(new$installation.time))
		  new=new[complete.cases(new),]

	#5 Drop existing rows with packages we will add (effectively, update install time)
		  existing.without_new= existing[!existing$pkg_vrs %in% new$pkg_vrs,]
		  updated=rbind(existing.without_new, new)
		  
	#6 Save
      saveRDS(updated, path.file.rds,version=2,compress = "xz")                       #In .rds format, version=2 is for backwards compatibility
      write.csv(updated, path.file.csv,row.names=FALSE)
      
      
  
  

    
    
    
    
    
    