# ckpt2r: Checkpoint importer for R

R package to import [Stratovan Checkpoint](https://www.stratovan.com/products/checkpoint) landmark files (*.ckpt) directly into R.

## Info
* `read_checkpoint()` imports landmarks from Stratovan Checkpoint files (*.ckpt) [1] into R[2] so that the Export-step within Checkpoint can be skipped. Returned will be a list of which each list element consists of a dataframe with the collowing columns:
  * **defined:** missing (`M`) or present (`N`), as defined within Checkpoint. When `keep.missing = FALSE`, landmarks with the label `M` will be removed.
  * **X, Y, Z:** x-, y- and z-coordinates of landmarks
  * **LM:** names of landmarks
  * **file:** name of the file that the list element was generated from
* `array_2D_from_LM_list()` converts a set of landmarks loaded with `read_checkpoint()` into a 2D array which can then e.g. be used via [`geomorph`](https://cran.r-project.org/web/packages/geomorph/index.html) or [`mvMORPH`](https://cran.r-project.org/web/packages/mvMORPH/index.html) for geometric morphometrics analyses. The resulting data.frame will have the following dimensions: n.specimens x  n.landmarks*n.dimensions.
  * `remove_NAs = TRUE` will remove all landmarks that have missing coordinate values in at least one specimen.
  * `verbose = TRUE` informs the user if and which landmarks have beeen removed from the dataset in case `remove_NAs = TRUE`.

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

# load ckpt2r
library(ckpt2r)

# read all landmark files from folder without considering potential subfolders.
folder.with.landmarks <- ckpt2r_examples()
LM.list <- read_checkpoint(folder.with.landmarks,
                           keep.missing = TRUE,
                           recursive = FALSE,
                           pattern = NULL)

print(LM.list)

# convert LM.list to 2D array
array_2D <- array_2D_from_LM_list(LM.list = LM.list,
                                  remove_NAs = FALSE)
dim(array_2D)
#  returns: n.specimens,  n.landmarks*n.dimensions
#  in the example file case: (15, 69 [=23*3])

# turn 2D array into 3D array
require(geomorph)
array.3D <- arrayspecs(A = array_2D,
                       p = (ncol(array_2D)/3),
                       k = 3, 
                       sep = ".") 
dim(array.3D)
# n.landmarks, n.dimenions, specimens
#  in the example file case: (23, 3, 15)

# Procrustes alignment
gpa.results <- gpagen(array.3D)
# !!! if this returned:
#   Error in gpagen(array.3D) : 
#     Data matrix contains missing values. Estimate these first (see 'estimate.missing').
# !!! then use keep.missing = TRUE in read_checkpoint) and
# !!! remove_NAs = TRUE in array_2D_from_LM_list() to remove landmarks with missing data.
# !!! In our case, specimen_0001 has the landmarks 'antenna_prox_L' and 'antenna_prox_L'
# !!! marked as missing:

# read landmark files from folder
LM.list <- read_checkpoint(folder.with.landmarks,
                           keep.missing = FALSE)
# landmarks 'antenna_prox_L' and 'antenna_prox_L' were removed from specimen_0001.

# convert LM.list to 2D array and remove landmarks with missing data
array_2D <- array_2D_from_LM_list(LM.list = LM.list,
                                  remove_NAs = TRUE,
                                  verbose = TRUE)
# if verbose = TRUE, this returns warning message with info on which landmarks were removed.
# In our case, six landmarks were missing in at least one of the specimens and were
# thus removed.
# Of course, you can also load all landmarks and filter them yourself instead letting
# ckpt2r to it for more control.

# get all landmarks that are still present in the dataset
LMs_present <- unique(sub("_[^_]+$", "", colnames(array_2D)))

dim(array_2D)
#   returns: 15 specimens and 17 landmarks (23-6) in 3 dimensions

# turn 2D array into 3D array again
array.3D <- arrayspecs(A = array_2D,
                       p = (ncol(array_2D)/3),
                       k = 3, 
                       sep = ".")
dim(array.3D)

# Procrustes alignment
gpa.results <- gpagen(array.3D)

# this should be fine now
summary(gpa.results$coords)

# plot all LM points of all specimens
for(i in 1:length(LM.list)){
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
* v.2-1-0 (2022-10-07)
  * changed package name from `chkpt2r` to `ckpt2r` to reflect actual Checkpoint file names
  * changed readme and example code accordingly
* v.2-0-0 (2022-10-05)
  * changed scripts into package
  * renamed `read.checkpoint()` to `read_checkpoint()`
  * renamed `array.2D.from.LM.list()` to `array_2D_from_LM_list()`
  * reworked example code
  * added example files
  * added `ckpt2r_examples()` function
* v.1-1-0 (2022-10-04)
  * added `array.2D.from.LM.list()` (after request from Christy Anna Hipsley)
  * added example R code to Readme file
* v.1-0-0 (2021)
  * [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5482977.svg)](https://doi.org/10.5281/zenodo.5482977)
  * first version that came with the paper
