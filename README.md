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
LM.list <- read.checkpoint(folder.with.landmarks,
                           keep.missing = FALSE)

print(LM.list)
# should return something like this:
[[1]]
    defined          X        Y         Z                      LM          file
1         M 1121.70068 721.9629  444.7175         frontS_X_coronS 0001_xxx_head
2         N  616.11871 531.3812  607.5993           C_of_clyplbrS 0001_xxx_head
3         N  440.10043 498.3546  611.0026            lat_clyplbrS 0001_xxx_head
4         N  608.94190 385.3711  426.4555             "C_lbr-tip" 0001_xxx_head
5         N  598.14355 599.1656  856.7567             C_of_epistS 0001_xxx_head
6         N  426.96515 557.9075  826.2263                 atp_med 0001_xxx_head
7         N  302.96197 457.7172  814.3900                 atp_lat 0001_xxx_head
8         N  363.25909 493.5258  793.6968                C_of_atp 0001_xxx_head
9         N  466.39160 396.7891  888.8391        ata_at_corpotent 0001_xxx_head
10        M 1118.57446 719.9429  412.1278             dta_at_head 0001_xxx_head
11        M 1102.92712 718.6509  381.6300              dta_on_ata 0001_xxx_head
[...]
115       N  298.52539 436.7891  754.3361           md3_insertion 0001_xxx_head

[...]

[[219]]
    defined          X         Y         Z                      LM          file
1         M 1314.68872 611.63977  430.6558         frontS_X_coronS 0219_xxx_head
2         N  598.62726 577.49445  355.6156           C_of_clyplbrS 0219_xxx_head
3         N  483.53073 546.49750  331.5674            lat_clyplbrS 0219_xxx_head
4         N  620.67725 557.91650  209.7814             "C_lbr-tip" 0219_xxx_head
5         N  566.06134 563.62402  511.8367             C_of_epistS 0219_xxx_head
6         N  419.86118 527.37500  459.2769                 atp_med 0219_xxx_head
7         N  292.12070 420.66412  497.9028                 atp_lat 0219_xxx_head
8         N  373.44629 474.37500  454.4275                C_of_atp 0219_xxx_head
9         N  453.11362 402.37500  523.0107        ata_at_corpotent 0219_xxx_head
10        M 1306.34668 582.40894  427.3746             dta_at_head 0219_xxx_head
11        M 1308.07910 597.16773  427.5869              dta_on_ata 0219_xxx_head
[...]
115       N  358.25000 455.21838  409.8817           md3_insertion 0219_xxx_head
 

# convert LM.list to 2D array
array_2D <- array.2D.from.LM.list(LM.list = LM.list)
dim(array_2D)
#  returns: n.specimens,  n.landmarks*n.dimensions
#  in the above case: (219, 345 [=115*3])

# turn 2D array into 3D array
require(geomorph)
array.3D <- arrayspecs(array_2D,
                       (ncol(array_2D)/3),3, 
                       sep = ".") # p = # landmarks; k = # dimensions; n = # specimens
dim(array.3D)
# n.landmarks, n.specimens, n.dimenions
#  in the above case: (115, 219, 3)

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
  * added `array.2D.from.LM.list()` (after request from Christy Anna Hipsley)
  * added example R code to Readme file
* v.1-0-0
  * [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5482977.svg)](https://doi.org/10.5281/zenodo.5482977)
  * first version that came with the paper
