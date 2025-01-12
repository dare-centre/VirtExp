# extract point timeseries data from the gridded rainfall
# Willem Vervoort 2016
# We have the following directory structure in BOM_GriddedRainfallData folder: 
# Daily-rainfall--|
#                 |-rainfall_1900-1909-|
#                 |                    |-rainfall-1900
#                 |                    |-rainfall-1901
#                 |                    |-etc
#                 |-rainfall_1910-1919
#                 |-rainfall_1920-1929
#                 |-etc
# in each of the lower order folders are a list files for each day
# There are two types of files: a *.prj file and a *.txt file

# so we need a loop through the decades and then a loop through the years
# the extract the timeseries for each year and store with the relevant dates
# then later combine all the annual timeseries
setwd("W:/GRP-HGIS/public/BOM_griddedrainfalldata")

library(zoo)
library(raster)
library(rgdal)
# map = raster(files[1]) # reads in the whole raster
#image(map)
# read in the list of decades
decades <- dir("Daily-rainfall", pattern="rainfall")

# store to put data in
Store <- list()

# Stations
sourcedatadir <- "c:/users/rver4657/owncloud/Virtual Experiments/VirtExp"
Stations <- read.csv(paste(sourcedatadir,"data/CatchmentCharact.csv",sep="/"))
# should be in decimal degrees
Stations.sp <- cbind(Long=Stations$Longitude,Lat=Stations$Latitude)

#for (i in 1:length(decades)) {
for (i in 8:11) {# only a limited number of decades needed for 1970 - 2010
    # read in the list of years
  Years <- dir(paste("Daily-rainfall/",decades[i],sep=""))
  yearlist <- list()
  
  for (j in 1:length(Years)) {
    # read the grids
    files= list.files(paste("Daily-rainfall/",decades[i],"/",Years[j],sep=""),pattern=".txt", full.names=TRUE)
    # stack the grids
    s <- stack(files)
    # extract the stations
    df <- extract(s, SpatialPoints(Stations.sp,proj4string=CRS("+proj=longlat")), df=TRUE, method='simple')
    #colnames(out) <- ....
    # store in the list
    yearlist[[j]] <- df
  }
  Store[[i]] <- yearlist
}

Store2 <- list()
for (i in 1:4) {
  Store2[[i]] <- Store[[i+7]]
}

output1 <- list()
for (i in 1:4) {
  output1[[i]] <- do.call(cbind,Store2[[i]])
}

#remove ID column
for (i in 1:4) {
  remove <- grep("ID",names(output1[[i]]))
  output1[[i]] <- output1[[i]][,-as.numeric(remove)]
}


output <- t(do.call(cbind,output1))
output.z <- zoo(output,order.by=seq.Date(as.Date("1970-01-01"),as.Date("2010-12-31"),by="days"))

save(output.z,file=paste(sourcedatadir,"data/GriddedRainfallData.Rdata",sep="/"))
