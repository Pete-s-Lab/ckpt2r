read.checkpoint <- function(folder, keep.missing = T){
  
  file.list <- list.files(folder, pattern = "ckpt", full.names = T)
  
  # create list that stores dataframes of the LM names and coordinats
  landmark_list <- list()
  
  # set landmark_list_counter to 0
  landmark_list_counter = 0
  
  for(f in 1:length(file.list)){ #length(file.list)
    
    # load checkpoint file and get it's lines
    curr.file.name <- file.list[f]
    file_in <- file(curr.file.name, open = "r")
    lines <- readLines(file_in)
    close(file_in) # untested
    
    # get current specimen name
    curr.specimen <- sub("^(.+)\\.ckpt$", "\\1", basename(curr.file.name))
    
    
    # find line with NumberOfPoints
    if(sum(grepl("NumberOfPoints", lines)) >= 1){
      # check if cointains landmarks
      line.no.LM.no <- which(grepl("NumberOfPoints", lines)==T)
      no.of.LMs <- gsub("^.+ (\\d+)$", "\\1", lines[line.no.LM.no])
      if(no.of.LMs > 0){
        
        print(paste0("Adding ", no.of.LMs, " landmarks from ", curr.specimen))
        
        # increase counter value
        landmark_list_counter = landmark_list_counter+1
        
        # find lines with landmark information
        for(l in 1:length(lines)){
          
          # get current line as string
          curr_line <- lines[l]
          
          if(l == 1){
            # if dealing with the first line, set LM_falg to zero ( <- this is never a LM line)
            LM_flag <- 0
            # setcreate empty list of LM line numbers
            LM_line_numbers <- c()
            
          } else if(grepl("Units", curr_line) & LM_flag == 0){ # go through all lines until line starts with "Units"
            # set LM_flag to 1 to indicate that the follownig lines contain landmark information
            LM_flag <- 1
            
          } else if(grepl("^\\d+:.+", curr_line) & LM_flag > 0){
            # read landmark information from each line that starts with numbers, but only when LM_flag is > 0 (i.e., 1, 2 or 3)
            
            if(LM_flag == 1){
              # add current line number to list of LM line numbers
              LM_line_numbers <- c(LM_line_numbers, l)
              
              # set LM flag to 2 to indicate that
              LM_flag <- 2
              
            } else {
              # check if current line number is 1 higher than last LM line number <- proceed if true
              if(l-LM_line_numbers[length(LM_line_numbers)] == 1){
                LM_line_numbers <- c(LM_line_numbers, l)
                
              } else {
                # if current line number is more than 1 higher than last LM line number: set LM_flag to 3
                LM_flag <- 3
              }
            }
          }
          
          # when last line of LM file is reached:
          if(l == length(lines)){
            # save a list of the strings that contain LM information as LM_lines
            LM_lines <- lines[LM_line_numbers[1]:LM_line_numbers[length(LM_line_numbers)]]
            
            # create data frame from list of strings with LM infos
            LMs <- data.frame(do.call(rbind, strsplit(LM_lines, " ")))
            
            # convert column X11 to character <- this is necessary to change landmark names of curves later
            LMs$X11 <- as.character(LMs$X11)
            
            # these following three lines make sure that coordinates are treated as numbers and not factors 
            LMs$X5 <- as.numeric(as.character(LMs$X5))
            LMs$X6 <- as.numeric(as.character(LMs$X6))
            LMs$X7 <- as.numeric(as.character(LMs$X7))
          }
        }
        
        # find lines with curve information <- start again at beginning of list of lines as characters (=lines)
        for(l in 1:length(lines)){
          # save current line as string
          curr_line <- lines[l]
          
          # proceed if current line string contains "NumberOfCurves"
          if(grepl("NumberOfCurves", curr_line)){
            
            # save number of curves
            curve_number <- as.numeric(as.character(sub(pattern = "^.+(\\d+)$", replacement = "\\1", curr_line)))
            
            # save the number of the line that contains info on the first curve
            first_curve_line <- l+1
          }
          
          # if last line string is reached (= end of LM file):
          if(l == length(lines)){
            # save a list of the strings that contain curve LM information as curve_lines
            curve_lines <- lines[first_curve_line:(first_curve_line+curve_number-1)]
          }
        }
        
        # add landmark name to curves in LMs dataframe and save curve names
        curve_names <- c()
        for(c in 1:curve_number){
          # store current curve line as vector of strings
          s <- unlist(strsplit(curve_lines[c], " "))
          
          # find the line numbers that contrain the curve LM coordinates
          curve_numbers <- s[4:(length(s)-4)]
          
          # filter curve name (= third-last element of the curve line string vector s)
          curve_name <- s[length(s)-2]
          curve_names <- c(curve_names, curve_name)
          # add curve names of current curve to the LM dataframe
          for(i in 1:length(curve_numbers)){
            for(r in 1:nrow(LMs)){
              if(r == curve_numbers[i]){
                LMs$X11[r+1] <-  curve_name
              }
            }
          }
        }
        # remove \" at beginning and end of LM name
        LMs$X11 <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", LMs$X11) 
        curve_names <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", curve_names) 
        
        # add counter to curve_LMs
        for(n in 1:length(curve_names)){
          curr.curve.name <- curve_names[n]
          line.no.with.curr.curve.name <- length(LMs$X11[LMs$X11==curr.curve.name])
          LMs$X11[LMs$X11==curr.curve.name] <- paste0(LMs$X11[LMs$X11==curr.curve.name], "_", 1:line.no.with.curr.curve.name)
        }
        
        # reduce dataset to landmarks that have not been declared missing within Checkpoint (M), but present (N)
        # present <- LMs[ which(LMs$X3 == 'N'),]
        present <- LMs
        
        # get X, y, Z coordinate- and landmark name- columns
        landmark.coordinates.and.names <- c(3,5,6,7,11)
        
        present.df <- as.data.frame(present[,landmark.coordinates.and.names])
        colnames(present.df) <- c("defined", "X", "Y", "Z", "LM")
        
        present.df$file <- curr.specimen
        
        if(keep.missing == F){
          no.LM.M <- sum(present.df$defined=="M")
          print(paste0("Removing ", no.LM.M, " landmarks defined as missing from ", curr.specimen, "..."))
          present.df <- present.df[present.df$defined!="M",]
        }
        
        # convert LM names and coordinates into dataframe and store as list element within landmark_list at index landmark_list_counter
        landmark_list[[landmark_list_counter]] <- present.df
        
      } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
    } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
  }
  closeAllConnections()
  return(landmark_list)
}
