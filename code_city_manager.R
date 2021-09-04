

#-----------Transform city data into dyadic logit structure----------- 

#NOTE: the example files in this repository are files representing potential receiver cities, with "_i" subscripts for column names. 
#Sender files have the same content as the receiver files. The only difference is the "_j" subscripts for column names.
#In the paper, we use "_r" for receiver cities and "_s" for sender cities.


#------Example: transform 2010 files
receiver2010 <- read.csv("~/Desktop/2010_all_attr_i.csv")
sender2010 <- read.csv("~/Desktop/2010_all_attr_j.csv")

#repeat each row by itself 767 times in the receiver file 
#(e.g. the first 767 rows are the same and show attributes of the first city)
receiver_2010 <- receiver2010[rep(seq_len(nrow(receiver2010)), each = 767),]
head(receiver_2010)

#repeat the 767 rows in the sender file 767 times
#(e.g. the first 767 rows show attributes of each of the 767 cities)
n <- 767
sender_2010 <- do.call("rbind", replicate(n, sender2010, simplify = FALSE))
head(sender_2010)

#column bind the repeated sender city file to the repeated receiver city file
#(e.g. in the first 767 rows, the first half are attributes of city 1 as the receiver city, 
#the second half are attributes of each of the 767 cities as the sender cities)
receiver_sender_2010 <- cbind(receiver_2010, sender_2010)
head(receiver_sender_2010)

#choose rows where sender is not the same as the receiver, so we don't pair a city with itself
clean_2010 <- subset(receiver_sender_2010, city_ID_i != city_ID_j)
head(clean_2010)
nrow(clean_2010)

#re-index the rows and generate the file containing dyadic logit data
row.names(clean_2010) <- 1:nrow(clean_2010)

write.csv(clean_2010, "~/Desktop/clean_2010.csv", 
          row.names = FALSE)

#The same process is repeated for 1990 and 2000 sender and receiver city attribute files.

#NOTE: the files with dyadic logit data is further processed to add columns detailing whether the institutions of a pair of cities are the same ("ins_same"),
#whether a turnover (any type) took place ("turnover"), whether a demotion ("dem"), horizontal ("hor"), promotion ("pro") turnover took place, 
#and whether a mutual exchange ("mutual") took place. 
#All these variables are binary: "1" suggests the event took place, "0" otherwise. To protect the confidentiality of the ICMA data, "turnover",
#"dem", "pro", "hor" are not provided here. "ins_same" can be easily calculated in excel (=IF(cm_i<>cm_j,0,IF(mc_i<>mc_j,0,IF(co_i<>co_j,0,1))).

#To locate a turnover event that took place and code it as 1 in 767*766 rows of 0's, create a new column that binds the city ID of the receiver and sender city. 
#For example, a row where "1234" is the receiver ID and "6789" is the sender ID will have an event ID of "1234-5678". Then, generate the event IDs in the same 
#manner in the original turnover dataset where turnovers took place , and use these event IDs to fill in "1" for matching rows in the dyadic logit data,
#"0" otherwise. Each type of turnover and whether a turnover is mutual can be coded in the dyadic logit data similarly.


#-----------Import and scale dyadic logit data----------- 

setwd("~/Desktop")

options(scipen=999)
library(tidyverse)
library(margins)
library(Zelig)
library(stargazer)
library(NISTunits)


#create data frame with dyadic logit data of all periods
clean_1990 <- read.csv("~/Desktop/clean_1990.csv")
clean_2000 <- read.csv("~/Desktop/clean_2000.csv")
clean_2010 <- read.csv("~/Desktop/clean_2010.csv")

#row bind data from all three periods
df1 <- rbind(clean_1990, clean_2000, clean_2010)
nrow(df1)
head(df1)

#create new columns and objects

#calculate the natural log of per capita income 
lninc_i <- log(df1$pcinc_i)
lninc_j <- log(df1$pcinc_j)

#rescale population to the unit of 10,000 persons
poptt_i <- (df1$pop_i)/10000
poptt_j <- (df1$pop_j)/10000

#get longitude and latitude of cities
lat_i <- df1$lat_i
lat_j <- df1$lat_j
longt_i <- df1$longt_i
longt_j <- df1$longt_j

#calculate Haversine distance between cities
a <- cos(NISTdegTOradian(90-lat_i))*cos(NISTdegTOradian(90-lat_j))
b <- sin(NISTdegTOradian(90-lat_i))*sin(NISTdegTOradian(90-lat_j))*cos(NISTdegTOradian(longt_i-longt_j))
hav_km <- acos(a + b)*6371
hav_mi <- acos(a + b)*3963

#scale distance between each pair of cities to 100 miles
dis_hm <- hav_mi/100

#calculate the absolute difference between sender and receiver cities for each attribute
abs_poptt <- abs(poptt_i - poptt_j)
abs_unemp <- abs(df1$unemp_i - df1$unemp_j)
abs_lninc <- abs(lninc_i - lninc_j)
abs_dem <- abs(df1$dem_i - df1$dem_j)
abs_div <- abs(df1$div_i - df1$div_j)

newcol <- data.frame(poptt_i, poptt_j, lninc_i, lninc_j, 
                     dis_hm, abs_poptt, abs_unemp, abs_lninc, abs_dem, abs_div)
df2 <- cbind(df1, newcol)
head(df2)

#change unit for unemployment rate, votes for democrat, diversity index to percentage points
unemp_perc_i <- 100*(df2$unemp_i)
unemp_perc_j <- 100*(df2$unemp_j)
abs_unemp_perc <- 100*abs(df2$unemp_i-df2$unemp_j)

dem_perc_i <- 100*(df2$dem_i)
dem_perc_j <- 100*(df2$dem_j)
abs_dem_perc <- 100*abs(df2$dem_i-df2$dem_j)

div_perc_i <- 100*(df2$div_i)
div_perc_j <- 100*(df2$div_j)
abs_div_perc <- 100*abs(df2$div_i-df2$div_j)

#column bind percentage point variables to the dataframe
perc <- data.frame(unemp_perc_i, unemp_perc_j, abs_unemp_perc, dem_perc_i, dem_perc_j, abs_dem_perc,
                   div_perc_i, div_perc_j, abs_div_perc)
df2 <- cbind(df2, perc)
head(df2)


poptt_i <- df2$poptt_i
unemp_i <- df2$unemp_i
unemo_perc_i <- df2$unemp_perc_i
lninc_i <- df2$lninc_i
div_i <- df2$div_i
div_perc_i <- df2$div_perc_i
dem_i <- df2$dem_i
dem_perc_i <- df2$dem_perc_i
poptt_j <- df2$poptt_j
unemp_j <- df2$unemp_j
unemp_perc_j <- df2$unemp_perc_j
lninc_j <- df2$lninc_j
div_j <- df2$div_j
div_perc_j <- df2$div_perc_j
dem_j <- df2$dem_j
dem_perc_j <- df2$dem_perc_j

#NOTE: as explained, the follwoing variables are not in the dataset we provided
mutual <- df2$mutual
ins_same <- df2$ins_same
turnover <- df2$turnover
pro <- df2$promotion
dem <- df2$demotion
hor <- df2$horizontal


#-----------Estimate models----------- 

#General model
#Model 1: panel dyadic logit
fin_gmo_scaled <- glm(turnover ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                      + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                      + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                      + mutual + ins_same + dis_hm, family = "binomial")
summary(fin_gmo_scaled)
exp(coef(fin_gmo_scaled))

#Model 2: rare event dyadic logit
z_gmo_scaled <- zelig (turnover ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                       + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                       + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                       + mutual + ins_same + dis_hm,
                       model = "relogit", tau = 611/1762569, bias.correct = TRUE,
                       data = df2,  cite = FALSE)

summary(z_gmo_scaled)
exp(coef(z_gmo_scaled))

##Promotion turnover model
#Model 1: panel dyadic logit
fin_pro_scaled <- glm(pro ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                      + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                      + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                      + mutual + ins_same + dis_hm, family = "binomial")
summary(fin_pro_scaled)
exp(coef(fin_pro_scaled))

#Model 2: rare event dyadic logit
z_pro_scaled <- zelig (pro ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                       + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                       + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                       + mutual + ins_same + dis_hm,
                       model = "relogit", tau = 131/1762569, bias.correct = TRUE,
                       data = df2,  cite = FALSE)
summary(z_pro_scaled)
exp(coef(z_pro_scaled))


##Horizontal turnover model
#Model 1: panel dyadic logit
fin_hor_scaled <- glm(hor ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                      + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                      + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                      + mutual + ins_same + dis_hm, family = "binomial")
summary(fin_hor_scaled)
exp(coef(fin_hor_scaled))

#Model 2: rare event dyadic logit
z_hor_scaled <- zelig (hor ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                       + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                       + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                       + mutual + ins_same + dis_hm,
                       model = "relogit", tau = 416/1762569, bias.correct = TRUE,
                       data = df2,  cite = FALSE)
summary(z_hor_scaled)
exp(coef(z_hor_scaled))

##Demotion turnover model
#Model 1: panel dyadic logit
fin_dem_scaled <- glm(dem ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                      + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                      + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                      + mutual + ins_same + dis_hm, family = "binomial")
summary(fin_dem_scaled)
exp(coef(fin_dem_scaled))

#Model 2: rare event dyadic logit
z_dem_scaled <- zelig (dem ~ poptt_i + unemp_perc_i + lninc_i + div_perc_i + dem_perc_i 
                       + poptt_j + unemp_perc_j + lninc_j + div_perc_j + dem_perc_j 
                       + abs_poptt + abs_unemp_perc + abs_lninc + abs_dem_perc + abs_div_perc
                       + mutual + ins_same + dis_hm,
                       model = "relogit", tau = 64/1762569, bias.correct = TRUE,
                       data = df2,  cite = FALSE)
summary(z_dem_scaled)
exp(coef(z_dem_scaled))
