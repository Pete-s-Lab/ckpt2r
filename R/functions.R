#' Read Checkpoint files from folder
#' 
#' Allows reading Checkpoint files (*.ckpt) directly into R so that the 
#' time-consuming export step within Checkpoint can be skipped.
#' 
#' So far, only point and curve landmarks are supported.
#'
#' @param folder A character string with the path to the Checkpoint files
#' (*.ckpt).
#' 
#' @param keep.missing If `FALSE`, landmarks marked as missing within 
#' Checkpoint are removed, no matter if they are defined or not (i.e. no matter
#' if there are coordinate values present). Default: `FALSE`.
#'
#' @return Returns a list of which each list element consists of a dataframe 
#' with the collowing columns:\cr
#' \cr
#'
#' | **`defined`** |   | missing (M) or present (N), as defined within Checkpoint. When keep.missing = FALSE, landmarks with the label M will be removed. |
#' | **`X, Y, Z`** |  | x-, y- and z-coordinates of landmarks |
#' | **`LM`** |   | names of landmarks |
#' | **`file`** |   | name of the file that the list element was generated from |
#' 
#' @examples
#' # read landmark files
#' folder.with.landmarks <- ckpt2r_examples()
#' LM.list <- read_checkpoint(folder.with.landmarks,
#'                            keep.missing = FALSE)
#'                            
#' print(LM.list)
#'
#' @export
read_checkpoint <- function(folder, keep.missing = TRUE){
  # # testing
  # folder <- ckpt2r_examples()
  # f=1
  # l=1
  
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
        if(length(curve_lines) > 2){
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
        }
        
        # remove \" at beginning and end of LM name
        LMs$X11 <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", LMs$X11) 
        if(length(curve_lines) > 2){
          curve_names <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", curve_names) 
          
          # add counter to curve_LMs
          for(n in 1:length(curve_names)){
            curr.curve.name <- curve_names[n]
            line.no.with.curr.curve.name <- length(LMs$X11[LMs$X11==curr.curve.name])
            LMs$X11[LMs$X11==curr.curve.name] <- paste0(LMs$X11[LMs$X11==curr.curve.name], "_", 1:line.no.with.curr.curve.name)
          }
        }
        
        # get X, y, Z coordinate- and landmark name- columns
        landmark.coordinates.and.names <- c(3,5,6,7,11)
        
        LMs.df <- as.data.frame(LMs[,landmark.coordinates.and.names])
        colnames(LMs.df) <- c("defined", "X", "Y", "Z", "LM")
        
        LMs.df$file <- curr.specimen
        
        # reduce dataset to landmarks that have not been declared missing within Checkpoint (M), but present (N)
        if(keep.missing == FALSE){
          no.LM.M <- sum(LMs.df$defined=="M")
          print(paste0("Removing ", no.LM.M, " landmarks defined as missing from ", curr.specimen, "..."))
          present.df <- LMs.df[LMs.df$defined!="M",]
        } else{
          present.df <- LMs.df
        }
        
        # convert LM names and coordinates into dataframe and store as list element within landmark_list at index landmark_list_counter
        landmark_list[[landmark_list_counter]] <- present.df
        
      } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
    } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
  }
  closeAllConnections()
  return(landmark_list)
}

#' Convert landmark list to table
#' 
#' Converts a landmark list loaded with `read_checkpoint()` to table (2D array).
#'
#' @param remove_NAs remove landmarks that are missing in at least one specimen 
#' from the whole dataset. Default: `TRUE`.
#' 
#' @param verbose If `TRUE` will inform the user if and which landmarks have 
#' been removed in case `remove_NAs` was set to `TRUE`. Default: `TRUE`.
#'
#' @return The resulting data.frame will have the following dimensions: 
#' `n.specimens x n.landmarks*n.dimensions`. Rownames will be the filenames the 
#' data came from.
#' 
#' @examples
#' # read landmark files
#' folder.with.landmarks <- ckpt2r_examples()
#' LM.list <- read_checkpoint(folder.with.landmarks,
#'                            keep.missing = FALSE)
#'                            
#' print(LM.list)
#' 
#' # convert LM.list to 2D array
#' array_2D <- array_2D_from_LM_list(LM.list = LM.list)
#' dim(array_2D)
#' 
#' @export
array_2D_from_LM_list <- function(LM.list,
                                  remove_NAs = FALSE,
                                  verbose = TRUE){
  # show progress percentage
  show.progress <- function(current, end){
    cat("\r", paste0(round(current/end*100,2), "%..."))
  }
  
  i=1
  for(i in 1:length(LM.list)){
    curr_specimen_name <- LM.list[[i]]$file[1]
    names(LM.list)[i] <- curr_specimen_name
  }
  
  # get all specimen names
  specimen_names <- names(LM.list)
  
  # find all landmark names that are used in all files (in case different files have different landmarks)
  LM_names <- c()
  s=1
  for(s in 1:length(LM.list)){
    curr_LM_names <- LM.list[[s]]$LM
    LM_names <- unique(c(LM_names, curr_LM_names))
    if(s == length(LM.list)){
      LM_names <- gsub("\"", "", LM_names)
    }
  }
  
  # create column names ( , LM1_x, LM1_y, LM1_z, ...) for horizontal 2D array
  k=1
  for(k in 1:length(LM_names)){
    if (k==1){
      column_names <- c("specimen")
    }
    column_names <- c(column_names,
                      paste0(LM_names[k],"_X"),
                      paste0(LM_names[k],"_Y"),
                      paste0(LM_names[k],"_Z"))
  }
  
  ### create array_2D and add landmark data
  array_2D <- NULL
  l=1
  for(l in 1:length(specimen_names)){
    if(l==1){
      # create 2D array
      array_2D <- setNames(data.frame(matrix(ncol = length(column_names), nrow = length(specimen_names))), column_names)
      row.names(array_2D) <- specimen_names
      array_2D$specimen <- specimen_names
    }
    
    e=1
    for(e in 1:nrow(LM.list[[l]])){
      # get landmark name and add X,Y,Z to separate the three coordinates of each line in the list of landmark data.frames
      curr_landmark_X <- paste0(gsub('\"', "", LM.list[[l]]$LM[e]),"_X")
      curr_landmark_Y <- paste0(gsub('\"', "", LM.list[[l]]$LM[e]),"_Y")
      curr_landmark_Z <- paste0(gsub('\"', "", LM.list[[l]]$LM[e]),"_Z")
      
      # get the column number that matches the current landmark name for each coordinate
      current_column_X <- match(curr_landmark_X, colnames(array_2D))
      current_column_Y <- match(curr_landmark_Y, colnames(array_2D))
      current_column_Z <- match(curr_landmark_Z, colnames(array_2D))
      
      # add the coordinate value into these column numbers at the current line number (1=X, 2=Y, 3=Z)
      array_2D[l,current_column_X] <- LM.list[[l]]$X[e]
      array_2D[l,current_column_Y] <- LM.list[[l]]$Y[e]
      array_2D[l,current_column_Z] <- LM.list[[l]]$Z[e]
    }
    show.progress(l, length(LM.list))
  }
  
  # remove specimen column (info is in rownames)
  array_2D$specimen <- NULL
  
  if(remove_NAs == TRUE){
    colnames_before <- gsub("_X$", "", colnames(array_2D))
    colnames_before <- gsub("_Y$", "", colnames_before)
    colnames_before <- unique(gsub("_Z$", "", colnames_before))
    array_2D <- array_2D[ , colSums(is.na(array_2D)) == 0]
    colnames_after <- gsub("_X$", "", colnames(array_2D))
    colnames_after <- gsub("_Y$", "", colnames_after)
    colnames_after <- unique(gsub("_Z$", "", colnames_after))
    LMs_removed <- setdiff(colnames_before, colnames_after)
    if(verbose == TRUE){
      if(length(LMs_removed) > 0){
        message("Removed the following ",  length(LMs_removed), " landmarks:\n", 
                paste0(LMs_removed, "; "))
      } else if(length(LMs_removed) == 0){
        message("No missing landmark data detected.")
      }
    }
  }
  
  return(array_2D)
}

#' Get path to landmark example files
#'
#' ckpt2r comes with example Checkpoint files. The files are stored in 
#' `ckpt2r`'s `inst/extdata` folder, and this function returns the path to that 
#' folder in examples.
#' 
#' @return
#' Returns the path to the folder containing example Checkpoint files.
#' 
#' @export
ckpt2r_examples <- function(){
  path <- system.file("extdata", "example_files",
                      package = "ckpt2r",
                      mustWork = TRUE)
  return(path)
}