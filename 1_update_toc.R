#CRON SCRIPT TO UPDATE CRAN.TOC.CSV

#last update: 2020 10 19

#Read RDS file in CRAN listing available packages, adds new to cran.toc
    #https://cran.r-project.org/web/packages/packages.rds
#Read also the .dcf file with current R version
    #https://cran.r-project.org/src/base/VERSION-INFO.dcf

#########################################################################################

	today=Sys.Date()
	path.file.rds = "cran.toc.rds"
	
	path.today.backup.rds=paste0("backups/cran.toc ",today,".rds") 
	path.file.csv="cran.toc.csv"

#Path off public_html
	home_path = dirname(dirname(getwd()))

#Add personal library to path
	.libPaths(file.path(home_path, "/R/lib/"))
	
#load the aws package for saving to wasabi
	library(aws.s3)
	
#Read the wasbi credentials 
	credentials.list = readRDS(file.path(home_path,"wasabi_credentials.rds"))
	Sys.setenv(
				'AWS_S3_ENDPOINT' = credentials.list$endpoint,
				"AWS_ACCESS_KEY_ID" = credentials.list$key,
				"AWS_SECRET_ACCESS_KEY" = credentials.list$secret,
				"AWS_DEFAULT_REGION" = credentials.list$default_region
				)

	#Note: bit  of a hack to get aws.s3 to work with wasabi, probably more elegant solution exists, but this works
	#The credentials.rds file is a saved R list where 
	#  endpoint = 'wasabisys.com'
	#  region = "s3"
	#  when making the calls, oddly aws.s3 them pastes toghether the URL as https://s3.wasabisys.com
	#  key and secret are the actual key and secret

#1 Load existing existing.toc
   
   existing.toc=readRDS(path.file.rds)
   saveRDS(existing.toc,path.today.backup.rds,version=2,compress = "xz")
   toc.pkg_vrs=paste0(existing.toc$Package,"_",existing.toc$Version)          #pkg_vrs in toc
	

#2 Load current CRAN packages, bypassing  {tools}
      con=url("https://cran.r-project.org/web/packages/packages.rds")  #RDS file with all current packages
      ap=data.frame(readRDS(con))
      close(con)

     ap$Published=as.Date(ap$Published)
     ap.pkg_vrs=paste0(ap$Package,"_",ap$Version)
   
   
#3 Files only in CRAN are new to us
     #3.1 find rows appearing only in ap[]
       ap.add=ap[!(ap.pkg_vrs %in% toc.pkg_vrs) ,]

     #3.2 For packages being added, keep only columns in toc
       ap.add=ap.add[,c("Package","Version","Imports","Depends","Suggests","LinkingTo","Published")]
 
     #3.3 Elminate parenthesis for minimum requirement, and breaklines (\n) in the dependencies being added
       #Write functions 
         no.paren=function(x)     gsub("\\s*\\([^\\)]+\\)","",as.character(x)) #Kill the parenthense 
         no.breakline=function(x) gsub("\\n","",as.character(x))           #Kill the \n 
	    	 no.space=function(x)     gsub(" ","",as.character(x))             #Kill the space
         clean=function(x) no.space(no.paren(no.breakline(x)))             #Kills all three 
            
         
        #Run them
           ap.add$Depends=clean(ap.add$Depends)
           ap.add$Imports=clean(ap.add$Imports)
           ap.add$Suggests=clean(ap.add$Suggests)
           ap.add$LinkingTo=clean(ap.add$LinkingTo)

           ap.add$Depends=ifelse(is.na(ap.add$Depends),"", ap.add$Depends)
           ap.add$Imports=ifelse(is.na(ap.add$Imports),"", ap.add$Imports)
           ap.add$Suggests=ifelse(is.na(ap.add$Suggests),"", ap.add$Suggests)
           ap.add$LinkingTo=ifelse(is.na(ap.add$LinkingTo),"", ap.add$LinkingTo)

         

     #3.4 Merge vertically toc with new packages
       existing.toc=rbind(existing.toc,ap.add)
       
#4 Read most recent R information from CRAN page (.dcf file)
    current.url =url('https://cran.r-project.org/src/base/VERSION-INFO.dcf')
    current.dcf=read.dcf(current.url, all = TRUE)
    close(current.url) #close connection to URL
    current.r.date    = as.Date(current.dcf$Date, format="%Y-%m-%d")
    current.r.version = current.dcf$Release
    
#5 Is it new?
  #5.1 Get toc for "R"
     R.toc=subset(existing.toc,Package=="R")
  #5.2 Look for current version 
      new.r= !current.r.version %in% R.toc$Version   #TRUE/FALSE current.r.version is not in TOC
  #5.3 If new add  
      if (new.r==TRUE) {
      #Write new line for data.frame
         r.line=data.frame(Package="R", Version=current.r.version, Published=current.r.date,LinkingTo="", Imports="",Depends="",Suggests="")
      #add it
         existing.toc=rbind(existing.toc,r.line)
       }#End if new
      
#5 Drop row names
	rownames(existing.toc)=c()
	
#6 Replace NA with ""
		for (k in 3:6) {
		existing.toc[,k]=ifelse(is.na(existing.toc[,k]),"",existing.toc[,k])
		}

#7 Evaluate if file remains OK
	
	 #7.1 Function that looks for all orphan deps in a row of cran.toc.rds
        get_orphan_dep=function (k,df)
        {
        #put together the different dependency types
         deps=paste0( df$Imports[k] , ',' , df$Depends[k] , ',' , df$Suggests[k],  ',' , df$LinkingTo[k])
        
        #Turn to vector
         deps_vector=strsplit(deps,",")[[1]]
         deps_vector=deps_vector[deps_vector!='']
         
        #Find dependencies not included in cran toc
         deps_nocran = deps_vector [!deps_vector %in% existing.toc$Package]
        
        #Find remaining dependencies not in base R
         deps_nobase = deps_nocran [!deps_nocran %in% base]
         
        #Return reaminig 
         return (deps_nobase)
      }
	
        
  #7.2 Run it on new rows, saving infomation on what package it is and what dependcies it does not have
        base=rownames(installed.packages(priority="base"))
        non_cran_alert=""
        for (k in 1:nrow(ap.add))
        {
        orphan_dep_array=get_orphan_dep(k,ap.add)
        orphan_dep=paste0(orphan_dep_array,collapse=',')
        if (length(orphan_dep_array)>0) non_cran_alert=paste0(non_cran_alert,"\n",today, " - package:",ap.add$Package[k]," was added to cran.toc.rds and has these dependecies not on CRAN: ",orphan_dep)
        }
        
 
        
        
#8 Save toc
	#Sort from newest to oldest to facilitate showing differential rows in PHP
	existing.toc=existing.toc[order(existing.toc$Published,decreasing=TRUE),]
    saveRDS(existing.toc,path.file.rds,version=2,compress = "xz")      #In .rds format, version=2 is for backwards compatibility
 	write.csv(existing.toc, file = path.file.csv,row.names=FALSE)      #Uncompressed for showing in the PHP feedback after cron job

#9 Save	Groundhog version
	groundhog_version=as.character(subset(ap,Package=='groundhog')$Version)
	groundhog_version
	fileConn<-file("groundhog_version.txt")
	writeLines(c(groundhog_version), fileConn)
	close(fileConn)

     
#10 Save to wasabi
		put_object(
		file = path.file.rds, 
        object = path.file.rds, 
        bucket = "groundhog"
        )
  