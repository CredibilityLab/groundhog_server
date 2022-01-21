

	git.toc_path     <- 'git.toc.rds'
	new.remotes_path <- 'new_remotes.csv'	

	
#Function 1 - Get sha for HEAD make row for git.toc

  get.git_row<- function(remote_id, usr, pkg) {
   
      #URL
       url <-  paste0('https://',remote_id , ".com/" , usr, "/", pkg)
      
      #Get current sha if it exists, return FALSE otherwise
        sha<-try({git2r::remote_ls(url)})
        if (!exists('sha')) return(FALSE)
        sha_head <- as.character(sha[1])
      
      #Make row
        row <- data.frame(remote_id=remote_id,usr=usr,pkg=pkg,sha=sha_head,date=Sys.Date(),stringsAsFactors=FALSE)
      
        
      #Add row
        return(row)
        
    }
    
#--------------------------------------------------------------------
#2 - update existing git.toc remotes

    #1 Read existing toc
       git.toc <- readRDS(git.toc_path)
    
    
    #2 Make URL combining pkg info 
        url_all <- with( git.toc , paste0('https://',remote_id , ".com/" , usr, "/", pkg))
            
    #3 Drop repeats
            dup.row <- duplicated(url_all)
            git.toc.unique <- git.toc [dup.row==FALSE,]
            
    #4 Process them all
            for (k in 1:nrow(git.toc.unique))
            {
            #GET SHA for that pkg 
              row <- get.git_row(git.toc.unique$remote_id[k], git.toc.unique$usr[k], git.toc.unique$pkg[k])
			 
            #If exists and row is new, save it
              if (exists('row') && !row$sha %in% git.toc$sha) {
                git.toc <- rbind(row,git.toc)
              }
            #Remove row so that if next iteration is an error, we flag by missing row
              rm(row)
            }
      
        #Delete rows where sha is not 40 characters long 
            git.toc <- subset(git.toc, nchar(sha)==40)
            
      
  
#--------------------------------------------------------------------

#3 - add new remote package to git toc


	if (file.exists(new.remotes_path )) {
		#Read it
			new_remotes_all <- read.csv(new.remotes_path,header=FALSE)
			
		#Name columns
			names(new_remotes_all)=c('remote','usr','pkg')
			
		#Delete duplicates
			new_remotes_all <- new_remotes_all[!duplicated(new_remotes_all),]
			
		#Remove spaces
			new_remotes_all <- sapply(new_remotes_all,function(x) gsub(" ","" , x))
			new_remotes_all <- data.frame(new_remotes_all,stringsAsFactors = FALSE)
		
		#Drop any new packages that actually are in git.toc 
			repeated_remote <-paste0(new_remotes_all$remote_id, new_remotes_all$usr, new_remotes_all$pkg ) %in%  #combine remote, usr,pkg
							  paste0(git.toc$remote_id,         git.toc$usr,                 git.toc$pkg )
							  
			new_remotes_all <- new_remotes_all[!repeated_remote,]
		
		#Get the tic Add them to git.toc
		for (k in 1:nrow(new_remotes_all))
		{
			#If it is not github or gitlab, skip it
				  if (!new_remotes_all[k,]$remote %in% c('github','gitlab')) next
			
						
			#2 Try to get row with the sha for this new package
				new.git_row = get.git_row(new_remotes_all[k,]$remote, new_remotes_all[k,]$usr, new_remotes_all[k,]$pkg)
				  
			#if it exists, and the sha is new, add to git.toc
				if (exists('new.git_row') && (!new.git_row %in% git.toc$sha)) {
						
						git.toc <- rbind(new.git_row , git.toc)
						}
				rm(new.git_row)
		} #End  Loop
		
		  #Delete the csv file
			unlink(new.remotes_path)
			
		  } #End if file found
		  
	
#--------------------------------------------------------------------

#4 - save
	#Save the file
		saveRDS(git.toc ,git.toc_path, version=2)
			
	#Save csv to be able to easily see from PHP
		write.csv(git.toc, file = paste0("git.toc.csv") , row.names=FALSE)      

