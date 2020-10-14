
  library('XML')                                       #library to read files in snapshot directory
  URL="https://cran.microsoft.com/snapshot/"           #URL to directory
  rows=scan(URL,what='character')                      #Read the directory
  dates.listed=getHTMLLinks(rows)                      #Extract dictories (one per date)
  dates.listed=substr(dates.listed,1,10)               #Kill the trailing /
  recent.date=as.Date((Sys.Date()-2))             #Get date from 2 days ago
  date.included=recent.date %in% dates.listed          #See if it is there

  
#IF date is missing, add it to the missing.mran.dates.rds
  if (date.included==FALSE)
      {
      #load existin
        missing.mran.dates=readRDS("missing.mran.dates.rds")      
      #add new
        missing.mran.dates=c(recent.date,missing.mran.dates)
      #save file
        saveRDS(missing.mran.dates,"missing.mran.dates.rds",version=2)
        write.csv(missing.mran.dates,"missing.mran.dates.csv")
      }
  
