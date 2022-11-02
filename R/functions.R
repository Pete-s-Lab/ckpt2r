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
#' @param pattern Character string defining pattern that should be part of file 
#' file names that the functions should consider. Default `NULL`. 
#' 
#' @param recursive Logical value defininf if function should consider 
#' subfolders (`TRUE`) or not (`FALSE`). Default: `FALSE`.
#'
#' @return Returns a tibble containing the following columns:\cr
#' \cr
#'

#' | **`file_name`** |   | name of the file that the list element was generated from |
#' | **`LM`** |   | names of landmarks |
#' | **`X, Y, Z`** |  | x-, y- and z-coordinates of landmarks |
#' | **`defined`** |   | missing (M) or present (N), as defined within 
#' Checkpoint or (O) when not defined at all but present in other files.|
#' 
#' @examples
#' # read landmark files
#' folder.with.landmarks <- ckpt2r_examples()
#' LM_list <- read_checkpoint(folder.with.landmarks)
#'                            
#' print(LM_list)
#'
#' @export
read_checkpoint <- function(folder,
                            pattern = NULL,
                            recursive = TRUE){
  
  
  # # testing
  # folder <- ckpt2r_examples()
  # pattern = NULL
  # pattern = "0007"
  # recursive = FALSE
  # f=1
  # l=1
  require(dplyr)
  
  file.list.all <- list.files(folder, 
                              pattern = "\\.ckpt", 
                              full.names = TRUE,
                              recursive = recursive)
  
  # filter out files with pattern
  if(!is.null(pattern)){
    file.list <- file.list.all[grepl(pattern, file.list.all)]
    print(paste0("Found ", length(file.list.all), " Checkpoint files of which ",
                                                                          length(file.list), " file(s) fit the pattern ", pattern, "."))
  } else{
    file.list <- file.list.all
    print(paste0("Found ", length(file.list.all), " Checkpoint files."))
  }
  
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
        if(curve_number > 0){
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
        # remove \" at beginning and end of LM name (LMs$X11 is name column)
        LMs$X11 <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", LMs$X11) 
        
        if(curve_number > 0){
          curve_names <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", curve_names) 
          
          # add counter to curve_LMs
          for(n in 1:length(curve_names)){
            curr.curve.name <- curve_names[n]
            line.no.with.curr.curve.name <- length(LMs$X11[LMs$X11==curr.curve.name])
            LMs$X11[LMs$X11==curr.curve.name] <- paste0(LMs$X11[LMs$X11==curr.curve.name], "_", 1:line.no.with.curr.curve.name)
          }
        }
        
        # reduce dataset to landmarks that have not been declared missing within Checkpoint (M), but present (N)
        # present <- LMs[ which(LMs$X3 == 'N'),]
        present <- LMs
        
        # get X, y, Z coordinate- and landmark name- columns
        landmark.coordinates.and.names <- c(3,5,6,7,11)
        
        present.df <- as.data.frame(present[,landmark.coordinates.and.names])
        colnames(present.df) <- c("defined", "X", "Y", "Z", "LM")
        
        present.df$file_name <- curr.specimen

        # convert LM names and coordinates into dataframe and store as list element within landmark_list at index landmark_list_counter
        landmark_list[[landmark_list_counter]] <- present.df
        
      } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
    } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
  }
  closeAllConnections()
  
  # convert landmark list to tibble
  landmark_df <- as_tibble(bind_rows(landmark_list))
  
  # add NA values for missing data (i.e. for landmarks that are not present in all files)
  all_landmarks <- unique(landmark_df$LM)
  all_files <- unique(landmark_df$file_name)
  
  landmark = all_landmarks[1] # 21
  filename = all_files[1]
  for(landmark in all_landmarks){
    for(filename in all_files){
      check <- landmark_df %>% 
        filter(LM == landmark & file_name == filename) %>% 
        nrow()
      if(check == 0){
        landmark_df <- landmark_df %>% 
          add_row(defined = "O",
                  X = NA,
                  Y = NA,
                  Z = NA,
                  LM = landmark,
                  file_name = filename)
      }
    }
  }
  landmark_df <- landmark_df %>% 
    arrange(file_name, LM) %>% 
    select(file_name, LM, X, Y, Z, defined)
  
  print("done!")
  return(landmark_df)
  
  # file.list <- list.files(folder, pattern = "ckpt", 
  #                         full.names = TRUE,
  #                         recursive = recursive)
  # 
  # # filter out files with pattern
  # if(!is.null(pattern)){
  #   file.list <- file.list[grepl(pattern, file.list)]
  # }
  # 
  # # create list that stores dataframes of the LM names and coordinats
  # landmark_list <- list()
  # 
  # # set landmark_list_counter to 0
  # landmark_list_counter = 0
  # 
  # for(f in 1:length(file.list)){ #length(file.list)
  #   
  #   # load checkpoint file and get it's lines
  #   curr.file.name <- file.list[f]
  #   file_in <- file(curr.file.name, open = "r")
  #   lines <- readLines(file_in)
  #   close(file_in) # untested
  #   
  #   # get current specimen name
  #   curr.specimen <- sub("^(.+)\\.ckpt$", "\\1", basename(curr.file.name))
  #   
  #   
  #   # find line with NumberOfPoints
  #   if(sum(grepl("NumberOfPoints", lines)) >= 1){
  #     # check if cointains landmarks
  #     line.no.LM.no <- which(grepl("NumberOfPoints", lines)==T)
  #     no.of.LMs <- gsub("^.+ (\\d+)$", "\\1", lines[line.no.LM.no])
  #     if(no.of.LMs > 0){
  #       
  #       print(paste0("Adding ", no.of.LMs, " landmarks from ", curr.specimen))
  #       
  #       # increase counter value
  #       landmark_list_counter = landmark_list_counter+1
  #       
  #       # find lines with landmark information
  #       for(l in 1:length(lines)){
  #         
  #         # get current line as string
  #         curr_line <- lines[l]
  #         
  #         if(l == 1){
  #           # if dealing with the first line, set LM_falg to zero ( <- this is never a LM line)
  #           LM_flag <- 0
  #           # setcreate empty list of LM line numbers
  #           LM_line_numbers <- c()
  #           
  #         } else if(grepl("Units", curr_line) & LM_flag == 0){ # go through all lines until line starts with "Units"
  #           # set LM_flag to 1 to indicate that the follownig lines contain landmark information
  #           LM_flag <- 1
  #           
  #         } else if(grepl("^\\d+:.+", curr_line) & LM_flag > 0){
  #           # read landmark information from each line that starts with numbers, but only when LM_flag is > 0 (i.e., 1, 2 or 3)
  #           
  #           if(LM_flag == 1){
  #             # add current line number to list of LM line numbers
  #             LM_line_numbers <- c(LM_line_numbers, l)
  #             
  #             # set LM flag to 2 to indicate that
  #             LM_flag <- 2
  #             
  #           } else {
  #             # check if current line number is 1 higher than last LM line number <- proceed if true
  #             if(l-LM_line_numbers[length(LM_line_numbers)] == 1){
  #               LM_line_numbers <- c(LM_line_numbers, l)
  #               
  #             } else {
  #               # if current line number is more than 1 higher than last LM line number: set LM_flag to 3
  #               LM_flag <- 3
  #             }
  #           }
  #         }
  #         
  #         # when last line of LM file is reached:
  #         if(l == length(lines)){
  #           # save a list of the strings that contain LM information as LM_lines
  #           LM_lines <- lines[LM_line_numbers[1]:LM_line_numbers[length(LM_line_numbers)]]
  #           
  #           # create data frame from list of strings with LM infos
  #           LMs <- data.frame(do.call(rbind, strsplit(LM_lines, " ")))
  #           
  #           # convert column X11 to character <- this is necessary to change landmark names of curves later
  #           LMs$X11 <- as.character(LMs$X11)
  #           
  #           # these following three lines make sure that coordinates are treated as numbers and not factors 
  #           LMs$X5 <- as.numeric(as.character(LMs$X5))
  #           LMs$X6 <- as.numeric(as.character(LMs$X6))
  #           LMs$X7 <- as.numeric(as.character(LMs$X7))
  #         }
  #       }
  #       
  #       # find lines with curve information <- start again at beginning of list of lines as characters (=lines)
  #       for(l in 1:length(lines)){
  #         # save current line as string
  #         curr_line <- lines[l]
  #         
  #         # proceed if current line string contains "NumberOfCurves"
  #         if(grepl("NumberOfCurves", curr_line)){
  #           
  #           # save number of curves
  #           curve_number <- as.numeric(as.character(sub(pattern = "^.+(\\d+)$", replacement = "\\1", curr_line)))
  #           
  #           # save the number of the line that contains info on the first curve
  #           first_curve_line <- l+1
  #         }
  #         
  #         # if last line string is reached (= end of LM file):
  #         if(l == length(lines)){
  #           # save a list of the strings that contain curve LM information as curve_lines
  #           curve_lines <- lines[first_curve_line:(first_curve_line+curve_number-1)]
  #         }
  #       }
  #       
  #       # add landmark name to curves in LMs dataframe and save curve names
  #       if(length(curve_lines) > 2){
  #         curve_names <- c()
  #         for(c in 1:curve_number){
  #           # store current curve line as vector of strings
  #           s <- unlist(strsplit(curve_lines[c], " "))
  #           
  #           # find the line numbers that contrain the curve LM coordinates
  #           curve_numbers <- s[4:(length(s)-4)]
  #           
  #           # filter curve name (= third-last element of the curve line string vector s)
  #           curve_name <- s[length(s)-2]
  #           curve_names <- c(curve_names, curve_name)
  #           # add curve names of current curve to the LM dataframe
  #           for(i in 1:length(curve_numbers)){
  #             for(r in 1:nrow(LMs)){
  #               if(r == curve_numbers[i]){
  #                 LMs$X11[r+1] <-  curve_name
  #               }
  #             }
  #           }
  #         }
  #       }
  #       
  #       # remove \" at beginning and end of LM name
  #       LMs$X11 <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", LMs$X11) 
  #       if(length(curve_lines) > 2){
  #         curve_names <- sub(pattern = "^\\W+(\\w+)\\W+$", replacement = "\\1", curve_names) 
  #         
  #         # add counter to curve_LMs
  #         for(n in 1:length(curve_names)){
  #           curr.curve.name <- curve_names[n]
  #           line.no.with.curr.curve.name <- length(LMs$X11[LMs$X11==curr.curve.name])
  #           LMs$X11[LMs$X11==curr.curve.name] <- paste0(LMs$X11[LMs$X11==curr.curve.name], "_", 1:line.no.with.curr.curve.name)
  #         }
  #       }
  #       
  #       # get X, y, Z coordinate- and landmark name- columns
  #       landmark.coordinates.and.names <- c(3,5,6,7,11)
  #       
  #       LMs.df <- as.data.frame(LMs[,landmark.coordinates.and.names])
  #       colnames(LMs.df) <- c("defined", "X", "Y", "Z", "LM")
  #       
  #       LMs.df$file <- curr.specimen
  #       
  #       # reduce dataset to landmarks that have not been declared missing within Checkpoint (M), but present (N)
  #       if(keep_missing == FALSE){
  #         no.LM.M <- sum(LMs.df$defined=="M")
  #         print(paste0("Removing ", no.LM.M, " landmarks defined as missing from ", curr.specimen, "..."))
  #         present.df <- LMs.df[LMs.df$defined!="M",]
  #       } else{
  #         present.df <- LMs.df
  #       }
  #       
  #       # convert LM names and coordinates into dataframe and store as list element within landmark_list at index landmark_list_counter
  #       landmark_list[[landmark_list_counter]] <- present.df
  #       
  #     } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
  #   } else {message(paste0("!!! No landmarks found in ", curr.specimen, "...  !!!"))}
  # }
  # closeAllConnections()
  # return(landmark_list)
}



#' Convert landmark table to 2D array 
#' 
#' Converts a table with landmark X-, Y-, and Z-coordinates into a 2D array.
#'
#' @param df A `data.frame` with columns containing specimen names, landmark 
#' names, X-coordinates, Y-coordinates, and Z-coordinates.
#' 
#' @param specimen_column Character string with the name of the specimen column.
#' Default: `"specimen"`.
#' 
#' @param LM_column Character string with the name of the specimen column.
#' Default: `"landmark"`.
#' 
#' @param X_column Character string with the name of the specimen column.
#' Default: `"X"`.
#' 
#' @param Y_column Character string with the name of the specimen column.
#' Default: `"Y"`.
#' 
#' @param Z_column Character string with the name of the specimen column.
#' Default: `"Z"`.
#'
#' @return Returns a tibble containing a `specimen` column and one column per 
#' landmark and coordinate, e.g. `landmark1_X`, `landmark1_Y`, `landmark1_Z`,
#' `landmark2_X`, `landmark2_Y`, `landmark2_Z`, [...].
#' 
#' @examples
#' # read landmark files
#' folder.with.landmarks <- ckpt2r_examples()
#' LM_list <- read_checkpoint(folder.with.landmarks)
#'                            
#' print(LM_list)
#' 
#' array_2D <- array_2D_from_df(df = LM_list, 
#'                 specimen_column = "file_name",
#'                 LM_column = "LM",
#'                 X_column = "X",
#'                 Y_column = "Y",
#'                 Z_column = "Z")
#'                            
#' print(array_2D)
#'
#' @export
# create array.2D from a set of landmark names and a list of landmarks - see below for general version of this function
array_2D_from_df <- function(df, 
                             specimen_column = "specimen",
                             LM_column = "landmark",
                             X_column = "X",
                             Y_column = "Y",
                             Z_column = "Z"){
  # # testing  
  # df = LM_list
  # LM_column = "LM"
  # specimen_column = "file_name"
  # X_column = "X"
  # Y_column = "Y"
  # Z_column = "Z"
  
  require(dplyr)
  
  # find column number of LM column
  LM_col_no <- which(colnames(df) == LM_column)
  
  # get all unique landmark names
  landmarks <- unique(df[, LM_col_no]) %>% 
    pull()
  
  # find column number of specimen column
  specimen_col_no <- which(colnames(df) == specimen_column)
  
  # get all unique specimen names
  specimens <- unique(df[, specimen_col_no]) %>% 
    pull()
  
  # find column number of X,Y,Z-coordinate columns
  X_col_no <- which(colnames(df) == X_column)
  Y_col_no <- which(colnames(df) == Y_column)
  Z_col_no <- which(colnames(df) == Z_column)
  
  # # create column names ( , LM1_x, LM1_y, LM1_z, ...) for horizontal 2D array
  for(k in 1:length(landmarks)){
    if (k==1){
      column_names <- c("specimen")
    }
    column_names <- c(column_names,
                      paste0(landmarks[k],"_X"),
                      paste0(landmarks[k],"_Y"),
                      paste0(landmarks[k],"_Z"))
  }
  
  ### create array_2D and add landmark data
  array_2D <- NULL
  l=1
  # go through all specimens
  for(l in 1:length(specimens)){
    # create empty dataframe
    if(l==1){
      # create 2D array
      array_2D <- setNames(data.frame(matrix(ncol = length(column_names), nrow = length(specimens))), column_names)
      row.names(array_2D) <- specimens
      array_2D$specimen <- specimens
    }
    
    curr_specimen <- specimens[l]
    print(curr_specimen)
    
    # go through all landmarks
    LM=1
    for(LM in 1:length(landmarks)){
      curr_landmark <- landmarks[LM]
      # print(curr_landmark)
      
      # get landmark name and add X,Y,Z to separate the three coordinates of each line in the list of landmark data.frames
      curr_landmark_X <- paste0(curr_landmark,"_X")
      curr_landmark_Y <- paste0(curr_landmark,"_Y")
      curr_landmark_Z <- paste0(curr_landmark,"_Z")
      
      # get the column number that matches the current landmark name for each coordinate
      if(!is.na(match(curr_landmark_X, colnames(array_2D)))){
        current_column_X <- match(curr_landmark_X, colnames(array_2D))
        current_column_Y <- match(curr_landmark_Y, colnames(array_2D))
        current_column_Z <- match(curr_landmark_Z, colnames(array_2D))
        
        # add the coordinate value into these column numbers at the current line number (1=X, 2=Y, 3=Z)
        array_2D[l, current_column_X] <- df %>%
          filter(!!as.symbol(specimen_column) == curr_specimen,
                 !!as.symbol(LM_column) == curr_landmark) %>% 
          select(all_of(X_col_no)) %>% pull()
        array_2D[l, current_column_Y] <- df %>%
          filter(!!as.symbol(specimen_column) == curr_specimen,
                 !!as.symbol(LM_column) == curr_landmark) %>% 
          select(all_of(Y_col_no)) %>% pull()
        array_2D[l, current_column_Z] <- df %>%
          filter(!!as.symbol(specimen_column) == curr_specimen,
                 !!as.symbol(LM_column) == curr_landmark) %>% 
          select(all_of(Z_col_no)) %>% pull()
      } else{
        print("error")
      }
    }
    print("***********")
  }
  
  # delete all rows that only contain specimen number and rest NAs
  # array_2D <- array_2D[rowSums(!is.na(array_2D)) > 1, ]
  return(as_tibble(array_2D))
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
