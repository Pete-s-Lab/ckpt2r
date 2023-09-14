# ckpt2r: Checkpoint importer for R (v.3-0-0)

R package to import [Stratovan Checkpoint](https://www.stratovan.com/products/checkpoint) landmark files (*.ckpt) directly into R.

## Info
* `read_checkpoint()` imports landmarks from Stratovan Checkpoint files (*.ckpt) [1] into R[2] so that the Export-step within Checkpoint can be skipped. Returned will be a list of which each list element consists of a dataframe with the collowing columns:
  * **defined:** missing (`M`) or present (`N`), as defined within Checkpoint. When `keep.missing = FALSE`, landmarks with the label `M` will be removed.
  * **X, Y, Z:** x-, y- and z-coordinates of landmarks
  * **LM:** names of landmarks
  * **file:** name of the file that the list element was generated from
* `array_2D_from_LM_list()` converts a set of landmarks loaded with `read_checkpoint()` into a 2D array which can then e.g. be used via [`geomorph`](https://cran.r-project.org/web/packages/geomorph/index.html) or [`mvMORPH`](https://cran.r-project.org/web/packages/mvMORPH/index.html) for geometric morphometrics analyses. The resulting data.frame will have the following dimensions: n.specimens x  n.landmarks*n.dimensions.

Note that the old link `https://github.com/Peter-T-Ruehr/checkpoint_importer_for_R` links to this page.

## Installation
Use the command `devtools::install_github('https://github.com/Peter-T-Ruehr/ckpt2r')` to install the `ckpt2r` package directly from its [GitHub page](https://github.com/Peter-T-Ruehr/ckpt2r).

## Issues
If you have trouble with the package, please raise an issue [here](https://github.com/Peter-T-Ruehr/checkpoint_importer_for_R/issues) and I will try to solve it as soon as I can.

## Citation
Please cite the following paper when you use these functions:

Rühr et al. (2021): Juvenile ecology drives adult morphology in two insect orders. Proceedings of the Royal Society B 288: 20210616. https://doi.org/10.1098/rspb.2021.0616

### References:

[1] Stratovan Corporation, Davis, CA. https://www.stratovan.com/

[2] R Core Team. 2022 R: A language and environment for statistical computing. R Foundation for Statistical Computing. Vienna, Austria: R Foundation for Statistical Computing. http://www.R-project.org.

# Example R code
```
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
array_2D <- array_2D_from_df(landmarks_df, 
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

# and so on...
```

# History
* v.3-0-0 (2022-11-03)
  * total re-write of code
    * read_checkpoint() returns data frame now
    * replaced array_2D_from_LM_list() with array_2D_from_df() accordingly
* v.2-1-0 (2022-10-07)
  * changed package name from `chkpt2r` to `ckpt2r` to reflect actual Checkpoint file names
  * changed readme and example code accordingly
* v.2-0-0 (2022-10-05)
  * changed scripts into package
  * renamed `read.checkpoint()` to `read_checkpoint()`
  * renamed `array.2D.from.LM_list()` to `array_2D_from_LM_list()`
  * reworked example code
  * added example files
  * added `ckpt2r_examples()` function
* v.1-1-0 (2022-10-04)
  * added `array.2D.from.LM_list()` (after request from Christy Anna Hipsley)
  * added example R code to Readme file
* v.1-0-0 (2021)
  * [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5482977.svg)](https://doi.org/10.5281/zenodo.5482977)
  * first version that came with the paper
