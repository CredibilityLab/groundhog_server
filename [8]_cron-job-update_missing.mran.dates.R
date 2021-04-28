

  rm(list = ls())

  library('XML')                                       #library to read files in snapshot directory
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

  
  