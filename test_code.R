# if not already done, install ckpt2r
devtools::install_github('https://github.com/Peter-T-Ruehr/ckpt2r')

remove.packages("ckpt2r")

# load ckpt2r
library(ckpt2r)

# read all landmark files from folder without considering potential subfolders.
folder.with.landmarks <- ckpt2r_examples()
landmarks_df <- read_checkpoint(folder.with.landmarks,
                                recursive = FALSE,
                                pattern = NULL)

print(landmarks_df)

# We have several two landmarks 'antenna_prox_L' and 'antenna_prox_R' marked as 
#   missing (defined = M). So let's remove these landmark lines:
landmarks_df <- landmarks_df[landmarks_df$defined != "M",]

# now we will convert the table into an array 2D
array_2D <- array_2D_from_df(df = landmarks_df, 
                             LM_column = "LM",
                             specimen_column = "file_name",
                             X_column = "X",
                             Y_column = "Y",
                             Z_column = "Z")

# In our case, we have several landmarks that are not defined for all 
# species. Keeping these in the array_2D may cause problems in downstream
# analyses. So let's remove all landmarks that contain NA values
array_2D <- array_2D[, - which(colSums(is.na(array_2D)) > 0)]


# convert array_2D to data.frame, add column names and remove specimen column
array_2D <- as.data.frame(array_2D)
rownames(array_2D) <- array_2D$specimen
array_2D$specimen <- NULL

dim(array_2D)
#  returns: n.specimens,  n.landmarks*n.dimensions
#  in the example file case: (15, 51 [=17*3])

# get names of landmarks that are still in array_2D
LMs_present = unique(gsub("_\\w{1}$", "", colnames(array_2D)))
print(LMs_present)

# turn 2D array into 3D array
require(geomorph)
array.3D <- arrayspecs(A = array_2D,
                       p = (ncol(array_2D)/3),
                       k = 3, 
                       sep = ".") 
dim(array.3D)
# n.landmarks, n.dimenions, specimens
#  in the example file case: (17, 3, 15)

# Procrustes alignment
gpa.results <- gpagen(array.3D)
# !!! if this returned:
#   Error in gpagen(array.3D) : 
#     Data matrix contains missing values. Estimate these first (see 'estimate.missing').
# !!! then check if you still have NA values in your array 2D.

# this should be fine now
summary(gpa.results$coords)

# plot all LM points of all specimens
for(i in 1:length(landmarks_df)){
  if(i == 1){
    plot(gpa.results$coords[,,i], pch = 16, cex = 0.5, col="gray80")
  } else {
    points(gpa.results$coords[,,i], pch = 16, cex = 0.5, col="gray80")
  }
}

# plot consensus of all LM points of all specimens
points(gpa.results$consensus, pch=16)
text(gpa.results$consensus, labels = LMs_present, 
     pos = 4, cex = 0.75, srt=-30)

# run PCA
pca.results <- gm.prcomp(A = gpa.results$coords)

# print and plot PCA results
summary(pca.results)
plot(pca.results, pch = 16)
text(pca.results$x[, 1:2], labels = rownames(pca.results$x), 
     pos = 4, cex = 0.75, srt=-0)
