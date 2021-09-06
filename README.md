# Panel_dyadic_logit

This is a data and code repository for the article "A Vacancy Chain Model of Local Managers' Career Advancement" (Hongtao Yi & Catherine Chen), to
be published in the Journal of Public Administration Research and Theory. The article investigates the career trajectories of U.S. city managers from a
national-level angle and examines city-level attributes that drive city managers' career move choices. 

In this repository, we provide the R code we used to organize city-level attributes into a structure suitable for dyadic logit regression, scale variables, and estimate panel dyadic logit models and rare event logit models. The details can be found in "code_dyadic_logit."

We also include city attributes data for 767 cities in our dataset. The data were collected from the 1990, 2000, 2010 census, CQ Press, and other sources. 
The files are: "1990_all_attri_i.csv," "2000_all_attri_i.csv," and "2000_all_attri_i.csv." Below is the list of variables included in the CSV files. Please see 
"dyadic_logit_code" for explanations of the variable subscript "_i" shown in the csv files. 

- city_ID: FIPS code 
- pop: population 
- unemp: unemployment rate
- pcinc: per capita income 
- div: racial diversity index
- dem: vote share for Democratic presidential candiate
- lat: latitude 
- longt: longtitude
- cm: council manager form of government 
- mc: mayor council form of government
- co: commissioner form of government

(*All variables indicate city-level data)

Further details of data sources, coding, and modeling can be found in our paper.
