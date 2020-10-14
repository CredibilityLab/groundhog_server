#CRON SCRIPT TO UPDATE CRAN.TIMES.RDS
#last update: 2020 04 12

#Read page in CRAN listing installation times of binaries, add to .dsv
#https://cran.r-project.org/bin/windows/contrib/checkSummaryWin.html

#Results are used by groundhogR to estimate installation time when using tarballs

##########################################################################################
  rm(list = ls())
  library(XML) #to read the table with installation ties from CRAN/MRAN

#1 Path to existing installatino.times[]
	  path.file.csv=   "cran.times.csv"
   	  path.file.rds=   "cran.times.rds"
	  
	 

#2 Visit CRAN, get todays' install times
    url.times= "https://cran.r-project.org/bin/windows/contrib/checkSummaryWin.html"
    new.times=try(data.frame(readHTMLTable(scan(url.times,what='character') ,what='character')[[1]]))
    
  #Check for errors parsing the page
    if (class(new.times)=="try-error") stop("Could not parse HTML for new installation times")
    if (nrow(new.times)==0) stop("Did not find new installation times. URL may have rotten.")

  #Grab results    
    new.times=new.times[,c("X.Package.","X.Version.", "X.Inst..timing.")]                #Keep variables of interest
    names(new.times)=c("pkg", "vrs","installation.time")                                 #Rename them
    new.times$pkg_vrs=paste0(new.times$pkg,"_",new.times$vrs)                            #Add pkg_vrs 
    new.times=new.times[,c(4,3)]                                                         #Drop other variables (pkg & vrs)
    
  #Add today's date to de update date column (used for differential updating of users off the .csv)
    new.times$update.date=Sys.Date()
  
  #Drop if empty
    new.times=new.times[new.times$installation.time!="",]
    
#3 Load existing install.times() dataset
    existing.times=readRDS(path.file.rds)
	
	#Back up the file up to today, in case it gets corrupted we can return to a specific date instead of reading DESCRIPTION file on all tarballs 
		today=Sys.Date()
		path.today.backup.rds=paste0("backups/cran.times ",today,".rds") 
		saveRDS(existing.times,path.today.backup.rds,version=2,compress = "xz")
	
	 
  #Ceck for error reading .csv file
    if (class(existing.times)!="data.frame") stop("Could not read local existing.times .csv file")
    if (nrow(existing.times)==0) stop("Did not find existing installation times. file may be corrupt on ResearchBox server")

  #1st time runrename existing data
    #names(existing.times)=c("installation.time","pkg_vrs")
    #existing.times$update.date=Sys.Date()-10             #first time, make the existing stock have a previous date, this is use for the updating of users only

#4 Subset of pkg_vrs in new that are not in existing and are not empty
    add.times=new.times[!new.times$pkg_vrs %in% existing.times$pkg_vrs,]
    add.times=add.times[add.times$installation.time!="",]
    add.times$installation.time=as.numeric(add.times$installation.time)
    
#5 Combine them
    installation.times=rbind(add.times,existing.times)
    
	rownames(installation.times)=c()

#6 SAVE dataset with all installation times
      write.csv(installation.times,path.file.csv,row.names=FALSE)
	saveRDS(installation.times,path.file.rds,version=2,compress = "xz")                       #In .rds format, version=2 is for backwards compatibility
      
