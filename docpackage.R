if ( !require(devtools) ) install.packages("devtools")
if ( !require(roxygen2) ) devtools::install_github("klutometis/roxygen")
library(devtools)
library(roxygen2)

if(grepl("w32", R.Version()$platform)){
  ROOTPATH <- "C:/Users/tcapu/Google Drive/modules/"
} else{
  ROOTPATH <- "/media/sf_Google_Drive/modules/"
}

setwd(ROOTPATH)
create("wondeR")

setwd("./wondeR")
document()

print("Documentation process successful.")
