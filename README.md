# Checkpoint importer for R

* `read.checkpoint()` imports landmarks from Stratovan Checkpoint files (*.ckpt) [1] into R[2] so that the Export-step within Checkpoint can be skipped. Returned will be a list of which each list element consists of a dataframe with the collowing columns:
  * **defined:** missing (`M`) or present (`N`), as defined within Checkpoint. When `keep.missing = FALSE`, landmarks with the label `M` will be removed.
  * **X, Y, Z:** x-, y- and z-coordinates of landmarks
  * **LM:** names of landmarks
  * **file:** name the file that the list element was generated from
* `array.2D.from.LM.list()` converts a set of landmarks loaded with `read.checkpoint()` into a 2D array which can then e.g. be converted into a 3D array via `geomorph::arrayspecs()`. The resulting data.frame will have the following dinemsions: n.specimens x  n.landmarks*n.dimensions.
  * `remove_NAs = TRUE` will remove all landmarks that have missing coordinate values in at least one specimen.
  * `verbose = TRUE` informs the user if and which landmarks have beeen removed from the dataset in case `remove_NAs = TRUE`.

Please cite the following paper when you use these functions:

Rühr et al. (2021): Juvenile ecology drives adult morphology in two insect orders. Proceedings of the Royal Society B 288: 20210616. https://doi.org/10.1098/rspb.2021.0616

If you have issues, please raise them [here](https://github.com/Peter-T-Ruehr/checkpoint_importer_for_R/issues) and I will try to solve them as son as I can.

References:

[1] Stratovan Corporation, Davis, CA. https://www.stratovan.com/

[2] R Core Team. 2022 R: A language and environment for statistical computing. R Foundation for Statistical Computing. Vienna, Austria: R Foundation for Statistical Computing. http://www.R-project.org.

# Example R code
```
# read landmark files
folder.with.landmarks <- "./tmp/"
LM.list <- read.checkpoint(folder.with.landmarks)
LM.list

# convert LM.list to 2D array
array_2D <- array.2D.from.LM.list(LM.list = LM.list)
dim(array_2D)
#   returns: n.specimens,  n.landmarks*n.dimensions

# turn 2D array into 3D array
require(geomorph)
array.3D <- arrayspecs(array_2D,
                       (ncol(array_2D)/3),3, 
                       sep = ".") # p = # landmarks; k = # dimensions; n = # specimens
dim(array.3D)
# n.landmarks, n.specimens, n.dimenions

# Procrustes alignment
gpa.results <- gpagen(array.3D)
# !!! if this returned:
#   Error in gpagen(array.3D) : 
#     Data matrix contains missing values. Estimate these first (see 'estimate.missing').
# !!! then use remove_NAs = TRUE in array.2D.from.LM.list() to remove landmarks with missing data:

# convert LM.list to 2D array and remove landmarks with missing data
array_2D <- array.2D.from.LM.list(LM.list = LM.list,
                                  remove_NAs = TRUE,
                                  verbose = TRUE)
# if verbose = TRUE, this returns warning message with info on which landmarks were removed

dim(array_2D)
#   returns: n.specimens,  n.landmarks*n.dimensions

# turn 2D array into 3D array
require(geomorph)
array.3D <- arrayspecs(array_2D,
                       (ncol(array_2D)/3),3, 
                       sep = ".") # p = # landmarks; k = # dimensions; n = # specimens
dim(array.3D)
# n.landmarks, n.specimens, n.dimenions

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

# create geomorph data frmae
gdf <- geomorph.data.frame(gpa.coords = gpa.results$coords,
                           Csize = gpa.results$Csize)

# run PCA
pca.results.uncorr <- gm.prcomp(A = gdf$gpa.coords, phy = gdf$tree)
summary(pca.results.uncorr)
plot(pca.results.uncorr, pch = 16)

# and so on...
```

# History
* v.1-1-0
  * added `array.2D.from.LM.list()` (inspired by Dr. Christy Anna Hipsley, University of Copenhagen)
  * added example R code to Readme file
* v.1-0-0
  * [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5482977.svg)](https://doi.org/10.5281/zenodo.5482977)
  * first version that came with the paper
