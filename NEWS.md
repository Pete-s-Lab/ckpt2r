# `forceR` v1.0.16 (Release date: xxx)
### Major changes

### Minor changes:
  * made `convert_measurement()` more reliable regarding input column types
  
### Bug fixes


# `forceR` v1.0.15 (Release date: 2022-06-07)
### Major changes
  * Optimized peak finding by adding/subtracting one time step from bite start/end, respectively, and by making sure that numbers are numeric within the 'find_strongest_peaks()' function
  * Added `peak_duration_max_force()` to calculate duration and maximum force per peak and store it in a tibble with one peak per row

### Minor changes:
  * Added checks of output folder existence to `rescale_peaks()`, `red_peaks_100()`, and `avg_peaks()`
  * Removed the necessity of having the species name in df.peaks of `rescale_peaks()`
  * Added some internal data checks with meaningful error messages to `rescale_peaks()` and `correct_peak()`
  * Disentangled in `plot.to.screen` and `path.plots` `find_best_fits()`
  * Updated vignette
  * Updated README.md
  * added DOI to CITATION

### Bug fixes
  * Corrected input tests of `y_to_force()`



# `forceR` v1.0.14 (Release date: 2022-05-10)
### Major changes
  * Added logo (v.1.0.14)
  * Added this NEWS.md file

### Minor changes:
  * Updated the help file of `y_to_force()` to clarify inputs and improved input checks
  * Added recommendation in help file of `crop_measurement()` and the vignette to not over-crop
  * Added recommendation  in the help file of `crop_measurement()` and the vignette to copy RAW files when extracting distinct regions within time series data

### Bug fixes
  * Changed file name extension of output files from "_cropped" to "_converted" in `convert_measurement()`



# `forceR` v0.0.13 (Release date: 2022-05-02)
  * First version of `forceR` on CRAN.
