/*******************************************************************************************************************************
Program: 				Timor Leste.do
Purpose: 				For the baseline analysis  			
Data outputs:			Coded and clean variables
Author: 				Ellestina Jumbe (FAO) & Nathan Barzola 
Date last modified:		September 18 2023 by Nathan
*******************************************************************************************************************************/
set more off
clear all 

if c(username)=="Jumbee" {
gl data "C:\Users\Jumbee\Food and Agriculture Organization\ESAD - RIMA\RIMA COUNTRY SUPPORT\TIMOR LESTE\2023\analysis\data"
}

else if c(username)=="Barzolan" {
gl data "C:\Users\Barzolan\OneDrive - Food and Agriculture Organization\RIMA\RIMA COUNTRY SUPPORT\TIMOR LESTE\TIMOR LESTE 2023\analysis\data"
}

gl raw "${data}\raw"
gl basic "${data}\basic"
gl final "${data}\final"

**** Create Sub-categories of datasets. 

/*import excel "${raw}\timorleste_data2023_Original.xlsx", sheet("Var names") firstrow

global var_abs Name_data if Category == "ABS"


foreach var of varlist _all { // Loop through all variables
    if regexm("`var'", "^HDDS") { // Check if the variable name starts with 'HDDS'
        local collist "`collist' `var'" // Add the variable name to the list
    }
}
*/

****import dataset
import excel "${raw}\timorleste_data2023_Original.xlsx", sheet("data") firstrow

* Clean Data
display _N //923 obs.  

keep if Consent_statement == "yes"

display _N //923 obs.
codebook _id // we have 923 individual IDs. 

** If the respondant is the HH Head

gen Dum_respo_HHH = 0
replace Dum_respo_HHH = 1 if Name_respondent == Name_HHhead

tab Dum_respo_HHH // 425/923 are HH Head
lab var Dum_respo_HHH "The Respondant is the Household Head"

****
drop start end Date_interview Consent_statement Validation_question Name_enumerator Name_respondent Name_HHhead Phonenumber
display _N //923 obs.
sa "${basic}\rawdata.dta", replace

**********************************
**# Build the characteristics 
**********************************
u "${basic}\rawdata.dta", clear

** Participant in the FAO program 

gen beneficiary = 1
replace beneficiary = 0 if In2022didyouparticipatein == "no"

tab beneficiary // 337/923 are beneficiaries
lab var beneficiary "The Household benefits from the FAO intervention in 2022"

** Composition of the Household had to be corrected.

replace Males_6to17years = "0" if Males_6to17years == "sa"
destring Males_6to17years, replace
foreach var of varlist Females_under_6years Males_under_6years Females_6to17years Males_6to17years Males_18to64years Females_18to64years Females_65_years Males_65_years{
	replace `var'=0 if missing(`var')
	}

** If the HH Head is a male

gen Dum_male_HHH = 0 
replace Dum_male_HHH =1 if Sex_HHhead == "male"
tab Dum_male_HHH // 823/923 HHH are male 
lab var Dum_male_HHH "Male HHH (Dummy)"

** Verification of the working_age variable

gen working_age= Tot_HHmembers_workingage_14to6
egen working_age1864 = rowtotal(Females_18to64years Males_18to64years)
egen hh_size = rowtotal(Females_under_6years Males_under_6years Females_6to17years Males_6to17years Males_18to64years Females_18to64years Females_65_years Males_65_years)

replace working_age = hh_size if working_age>hh_size
g dep_ratio = working_age/hh_size
su dep_ratio

lab var hh_size "Total of HH members (calculated)"
lab var working_age1864 "Total of HH members between 18 and 64 (calculated)"
lab var dep_ratio "#HHM between 14 and 64 / HH size"

*** Vulnerable populations 

egen vulnerable_members = rowtotal(Howmanymembersofthehousehol- AP)

/* VERIFICATION OF THE CONSISTENCY OF THE DATA

br Females_under_6years - Males_65_years working_age working_age1864 hh_size if 
hh_size<working_age
br Females_under_6years - Males_65_years working_age working_age1864 hh_size if working_age1864>working_age
*/

** Simplified HH variables

egen male_adults= rowtotal(Males_18to64years Males_65_years)
egen female_adults= rowtotal(Females_18to64years Females_65_years)
egen infants= rowtotal(Females_under_6years Males_under_6years)

lab var male_adults "Total of Male in the HH older than 18"
lab var female_adults "Total of Female in the HH older than 18"
lab var infants "Total of HH member younger than 6"

*** Create a global of the variables of characteristics

global characteristics Sex_HHhead Marital_status_HHhead name_municipality Name_post_administration name_Suco name_subvillage GPS_coordinates _GPS coordinates_latitude _GPS coordinates_longitude _GPS coordinates_altitude _GPS coordinates_precision Females_under_6years Females_under_6years Males_under_6years Females_6to17years Males_6to17years Males_18to64years Females_18to64years Females_65_years Males_65_years vulnerable_members Hhmember_disabilityYN

**********************************
* SHOCKS SECTION 
**********************************

egen num_shocks = rowtotal(H3Drought - H3Otherspecify) 

ren (H3Drought H3Floodswaterloggingstorm H3Watershortage H3Unusuallyhighlevelofcrop H3Unusuallyhighleveloflives H3Unusuallyhighcostsofagric H3Unusuallylowpricesofagric H3Seriousillnessofaccidento AOC H3Deathofotherhouseholdmemb H3Theftofmoneyvaluablesnon H3Theftofagriculturalassets H3ConflictViolence H3Fire H3Otherspecify H3Noshock)(shock_drought shock_floods shock_watershort shock_pests shock_livestock shock_inputs shock_ouputs shock_illness_incomee shock_illness_hh shock_death shock_theft shock_theft_agri shock_conflict shock_fire shock_other noshock)

foreach v of varlist shock_drought shock_floods shock_watershort shock_pests shock_livestock shock_inputs shock_ouputs shock_illness_incomee shock_illness_hh shock_death shock_theft shock_theft_agri shock_conflict shock_fire shock_other noshock{
	lab var `v' "dummy if household experienced `v' " 
	}

/*
ren (DM DN DO DP DQ DR DS DT) (wheat livestock cfw uct poultry gardening summer_crop agri_tools)	

foreach v of varlist wheat livestock cfw uct poultry gardening summer_crop agri_tools{
	destring `v', replace 
	recode `v' (. = 0)
	lab var `v' "dummy if household received `v' "
	su `v' 
	}

*/
	
	
gen dum_beneficiary = 0
replace dum_beneficiary =1 if Beneficiarystatus == "Beneficiary" 
	
keep _id name_Suco name_municipality name_subvillage Name_post_administration Dum_male_HHH working_age1864 working_age dep_ratio num_shocks shock_* hh_size male_adults female_adults infants dum_beneficiary


su

sa "${basic}\characteristics.dta", replace


********************************
**#  Create first pillar: ABS
********************************

u "${basic}\rawdata.dta", clear
display _N //923 obs.

keep _id name_subvillage DoesyourHHhaveaccesstoirri whatkindofirrigation specifyother Main_Source_irrigation_water waterharvesting riverpond wellborehole treadlepump other AccesstoBasicServicesABS - Q4_6Howfaristhisdwellingf // Keep only the good part of the questionnaire

*** Facilities

* ta Q1Isthemainsourceofdrinki  // 92% 
gen watersource = Q1Isthemainsourceofdrinki // 855/923 obs

*ta Q2Isthemaintypeoftoiletf //92%
gen maintoilet = Q2Isthemaintypeoftoiletf
replace maintoilet = 0 if missing(maintoilet) // 2 obs

* ta Q3Iselectricitythemainsour  // 80%
gen electricity = Q3Iselectricitythemainsour
replace electricity = 0 if missing(electricity) // 1obs

*** Irrigation 

gen abs_irrigation = 1 
replace abs_irrigation = 0 if  DoesyourHHhaveaccesstoirri == "no" // No missing variables

*** Distance Variables

ren (Q4_1Howfaristhisdwellingf Q4_2Howfaristhisdwellingf Q4_3Howfaristhisdwellingf Q4_4Howfaristhisdwellingf Q4_5Howfaristhisdwellingf Q4_6Howfaristhisdwellingf) (distance_water distance_school distance_hosp distance_liv_mark distance_agri_mark distance_pub_trans) // No missing variables

global distances distance_water distance_school distance_liv_mark distance_agri_mark distance_pub_trans distance_hosp


su $distances // Potential Outliers. 

bysort name_subvillage: egen avg_distance_water = mean(distance_water)
replace distance_water = avg_distance_water if distance_water > 90
replace distance_water = avg_distance_water if distance_water <1 & distance_water>0

bysort name_subvillage: egen avg_distance_school = mean(distance_school)
replace distance_school = avg_distance_school if distance_school > 120
replace distance_school = avg_distance_school if distance_school <1 & distance_school>0

bysort name_subvillage: egen avg_distance_liv_mark= mean(distance_liv_mark)
replace distance_liv_mark = avg_distance_liv_mark if distance_liv_mark > 180
replace distance_liv_mark = avg_distance_liv_mark if distance_liv_mark <1 & distance_liv_mark>0

bysort name_subvillage: egen avg_distance_agri_mark = mean(distance_agri_mark)
replace distance_agri_mark = avg_distance_agri_mark if distance_agri_mark > 180
replace distance_agri_mark = avg_distance_agri_mark if distance_agri_mark <1 & distance_agri_mark>0

bysort name_subvillage: egen avg_distance_pub_trans= mean(distance_pub_trans)
replace distance_pub_trans = avg_distance_pub_trans if distance_pub_trans > 120
replace distance_pub_trans = avg_distance_pub_trans if distance_pub_trans <1 & distance_pub_trans>0

bysort name_subvillage: egen avg_distance_hosp = mean(distance_hosp)
replace distance_hosp = avg_distance_hosp if distance_hosp > 180
replace distance_hosp = avg_distance_hosp if distance_hosp <1 & distance_hosp>0
// Drop unnecessary variables (optional)
drop avg_distance_water avg_distance_pub_trans avg_distance_school avg_distance_agri_mark avg_distance_liv_mark avg_distance_hosp


*** Normalize the variables of distance 
foreach var of varlist $distances {
	destring `var', replace
gen inv_`var' = 1/`var'
		replace inv_`var' = 1 if `var' == 0
		egen max_inv_`var' =max(inv_`var')
		egen min_inv_`var' = min(inv_`var')
		gen r_inv_`var'= (inv_`var'- min_inv_`var')/(max_inv_`var' - min_inv_`var')
		drop min_inv_`var' max_inv_`var'
}

*** Clean and rename the database
drop $distances inv_distance_water inv_distance_school inv_distance_liv_mark inv_distance_agri_mark inv_distance_pub_trans inv_distance_hosp

ren (r_inv_distance_water r_inv_distance_school r_inv_distance_liv_mark r_inv_distance_agri_mark r_inv_distance_pub_trans r_inv_distance_hosp) (distance_water distance_school distance_liv_mark distance_agri_mark distance_pub_trans distance_hosp)

/*** Plot the kdensity of the distance variable after the normalization
kdensity distance_water, name(Water_new)
kdensity distance_school, name(School_new)
kdensity distance_liv_mark, name(LivestockMarket_new)
kdensity distance_agri_mark, name(AgriMarket_new)	   
kdensity distance_pub_trans, name(PubTransp_new)	   
kdensity distance_hosp, name(Hospital_new)
 
graph combine Water_new School_new LivestockMarket_new AgriMarket_new PubTransp_new Hospital_new, cols(3) rows(2) title("Kernel Density Plots")
*/

*** Conduct the factor analysis trough an Iterative Principal Factor
factor distance_liv_mark distance_hosp distance_school distance_pub_trans distance_agri_mark, ipf
*** Create the scores in the distance_index variable with the bart method. 
predict distance_index, bart
lab var distance_index "Index of the inv. of time distances to ABS"

kdensity distance_index, name(before)

*** Normalize the scores. 
foreach var of varlist distance_index{
	su `var'
	replace `var' = (`var' - `r(min)') / (`r(max)'-`r(min)')
}

kdensity distance_index, name(after)

graph combine before after, cols(2) rows(1) title("Normalisation of the distance index")

keep _id watersource electricity maintoilet distance_water distance_index abs_irrigation

rename (watersource electricity maintoilet distance_water distance_index) (abs_watersource abs_electricity abs_maintoilet abs_distance_water abs_distance_index)


global abs abs_watersource abs_electricity abs_maintoilet abs_irrigation abs_distance_water abs_distance_index

su $abs // It is strange that the index of inverse distance is so low compared to the other variables
display _N //923 obs.  
sa "${basic}\abs.dta", replace

**********************************
**# Creating the pillar ASSETS
**********************************
u "${basic}\rawdata.dta", clear

*** Keep only the useful variables
keep _id ASSETS- ALZ
 
ren (Q5_1HowmanyCarsforwater Q5_2HowmanyBicyclesdoesy Q5_3HowmanyGasElectriccook Q5_4HowmanyMobilesdoesyo Q5_5HowmanyPloughsdoesyo Q5_6HowmanyMachetesdoesy Q5_7HowmanyTractorsdoesy) (car bicycle cooker mobile plough machete tractor) 

/*
** Issue with the survey  
tab car if ALN==1 // ok
tab bicycle if ALN==1 // 1
tab cooker if ALN==1 // 1
tab mobile if ALN==1 //3
tab plough if ALN==1 // ok
tab machete if ALN==1 //5
tab tractor if ALN==1 //ok 
*/

foreach v of varlist car bicycle cooker mobile plough machete tractor{
	destring `v', replace
	recode `v' (. = 0)
	}	
	
factor car bicycle cooker mobile, ipf
predict wealth_index, bart

factor plough tractor machete , ipf
predict agri_index, bart

factor plough tractor machete car bicycle cooker mobile, ipf
predict ast_assets_index, bart // Try to make just one indicator. 

ren (ALW ALX ALY ALZ) (NoInputs seeds herbicide fertilizer) 

foreach v of varlist NoInputs seeds herbicide fertilizer{ 
	destring `v', replace
	recode `v' (. = 0)
	su `v' 
	}

tab seeds if NoInputs==1	
tab herbicide if NoInputs==1	
tab fertilizer if NoInputs==1	
	
	
factor seeds herbicide fertilizer, ipf
predict input_index, bart		

keep _id wealth_index agri_index input_index ast_assets_index

rename (wealth_index agri_index input_index) (ast_wealth_index ast_agri_index ast_input_index)

global ast_indexes ast_wealth_index ast_agri_index ast_input_index ast_assets_index

foreach var of varlist $ast_indexes{
	su `var'
	replace `var' = (`var' - `r(min)') / (`r(max)'-`r(min)')
}

display _N //923 obs.  
sa "${basic}\ast_1.dta", replace

*** Open the livestock variables

u "${basic}\rawdata.dta", clear

** Keep only the useful variables
keep _id Livestock_owned_kept- Which_months_MAHFP
display _N //923 obs.

ren(Cattle_owned_kept_tot Buffalo_owned_kept_tot Sheep_owned_kept_tot Goat_owned_kept_tot Pig_owned_kept_tot Chicken_owned_kept_tot Horses_owned_kept_tot) (n_cattle n_buffalo n_sheep n_goat n_pig n_poultry n_horse)

** Add a variable if the livestock is vaccinated ("_vac") but idk what is the rationnal to have that informations. Isn't it ex post analysis? Ask Monica. 

foreach v of varlist n_cattle n_buffalo n_sheep n_goat n_pig n_poultry n_horse{
	destring `v', replace
	recode `v' (. = 0)
	su `v' 
	}
	
//  standard 
g tlu = (n_cattle*0.5+n_buffalo*.5) +(n_sheep*0.1+n_goat*.1)+ (n_poultry*0.01)+ (n_horse*1.4)+(n_pig*0.7)
su tlu		

rename (tlu) (ast_tlu)


// Diversification of the livestock

gen ast_div_livestock = 7 
foreach var of varlist n_cattle n_buffalo n_sheep n_goat n_pig n_poultry n_horse{
	replace ast_div_livestock = ast_div_livestock - 1 if `var'!= 0
}

// Vaccination 

gen cattle_vac = 1
replace cattle_vac = 0 if Cattle_Vac != "yes" 
gen buffalo_vac = 1
replace buffalo_vac = 0 if Buffalo_Vac != "yes" 
gen pig_vac = 1
replace pig_vac = 0 if Pig_Vac != "yes" 
gen chicken_Vac = 1
replace chicken_Vac = 0 if Chicken_Vac != "yes" 
gen horses_Vac = 1
replace horses_Vac = 0 if Horses_Vac != "yes" 
gen sheep_Vac = 1
replace sheep_Vac = 0 if Sheep_Vac != "yes" 
gen goat_Vac = 1
replace goat_Vac = 0 if Goat_Vac != "yes" 


factor cattle_vac buffalo_vac pig_vac chicken_Vac horses_Vac sheep_Vac goat_Vac , ipf
predict ast_vac_index, bart		

*___________________________________*

keep _id ast_tlu ast_div_livestock ast_vac_index
display _N //923 obs.  
sa "${basic}\ast_2.dta", replace

*** Open the land/crop variables

u "${basic}\rawdata.dta", clear

** Keep only the useful variables

destring Whatisthetotalareaofland, replace
replace Whatisthetotalareaofland = 0 if missing(Whatisthetotalareaofland) 
replace Whatisthetotalareaofland = 0 if Whatisthetotalareaofland == 1000

graph box Whatisthetotalareaofland
gen ast_land_ha = Whatisthetotalareaofland
su ast_land_ha

replace cassava_area_ha="0.1" if cassava_area_ha=="0,1"
replace cassava_area_ha="0" if cassava_area_ha=="1000"
replace cassava_area_ha="0" if missing(cassava_area_ha)

destring cassava_area_ha, replace

egen sum_land_ha = rowtotal(Maize_area_ha Sorghum_area_ha Vegetables_area_ha rice_paddy_area_ha Groundnut_area_ha cassava_area_ha sweet_potato_area_ha Potato_area_ha Taro_area_ha coffee_area_ha coconut_area_ha chilli_area_ha)

global food_area Maize_area_ha Sorghum_area_ha Vegetables_area_ha rice_paddy_area_ha Groundnut_area_ha cassava_area_ha sweet_potato_area_ha Potato_area_ha Taro_area_ha coffee_area_ha coconut_area_ha chilli_area_ha


foreach v of varlist Maize_area_ha Sorghum_area_ha Vegetables_area_ha rice_paddy_area_ha Groundnut_area_ha cassava_area_ha sweet_potato_area_ha Potato_area_ha Taro_area_ha coffee_area_ha coconut_area_ha chilli_area_ha {
	destring `v', replace
	replace `v' = 0 if missing(`v')
	}

gen pb_land_ha=0
replace pb_land_ha=1 if sum_land_ha>ast_land_ha // 35% it could be due to the effect of the rotation crops. 

****************
display _N //923 obs.	
br maize- chilli 

foreach v of varlist maize- chilli {
	destring `v', replace
	replace `v'=0 if missing(`v')
	su `v' 
	}
	
// 31 observation that don't grow anything = TO EXPLORE
	
egen ast_foodcrops = rowtotal(maize-taro)
su ast_foodcrops
		
egen ast_cashcrops = rowtotal(coffee-chilli)
su ast_cashcrops

egen ast_nbr_crops = rowtotal(maize-chilli)



// Use the variables on the sale of the production (They almost all sell whenever they produce...)
          
gen ast_nbr_cashcrops = 13 
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Maizeproduce_market) // 217/253 
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Sorghumproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Vegproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(rice_paddyproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Beansproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(cassavaproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Groundnutproduce_market)
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(sweet_potatoproduce_market) //
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(Taroproduce_market) // 237/247
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(coffeeproduce_market) // Only 68 obs positive
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(coconutproduce_market) // Only 69 obs positive
replace ast_nbr_cashcrops = ast_nbr_cashcrops -1 if missing(chilliproduce_market) // Only 22 obs positive (100% of the producers)

// the amount harvested is to imprecise 

su quantityofoniongarlicharves quantityofeggplantharvested quantityofcucumberharvested cassava_harvest_50kg_sack quantityofcarrotraddishharve Sorghum_harvest_50kg_sack Maize_harvest_50kg_sack Groundnut_harvest_50kg_sack
		
keep _id ast_cashcrops ast_foodcrops ast_land_ha ast_nbr_cashcrops ast_nbr_crops
		
merge 1:1 _id using "${basic}\ast_1.dta"
drop _merge
merge 1:1 _id using "${basic}\ast_2.dta"
drop _merge

		
foreach var of varlist ast_wealth_index ast_agri_index ast_input_index ast_cashcrops ast_foodcrops ast_land_ha{
		egen max_`var' =max(`var')
		egen min_`var' = min(`var')
		gen r_`var'= (`var'- min_`var')/(max_`var' - min_`var')
		drop min_`var' max_`var' 
		drop `var'
		ren r_`var' `var'
		}		
		
la var ast_land_ha "land"
la var ast_wealth_index "wealth index"
la var ast_input_index "agricultural input index" // A lot have the same value TO EXPLORE
la var ast_agri_index "Agricultural asset index"
la var ast_tlu "tropical livestock index"
la var ast_cashcrops "number of cash crops harvested"
la var ast_foodcrops "number of food crops harvested"
la var ast_nbr_cashcrops "number of crops sold"
la var ast_nbr_crops "number of crops harvested"

keep _id ast_land_ha ast_wealth_index ast_input_index ast_agri_index ast_tlu ast_cashcrops ast_foodcrops ast_nbr_crops ast_nbr_cashcrops ast_div_livestock ast_vac_index

display _N //923 obs.  
sa "${basic}\ast.dta", replace

**********************************
* Create the Pillar SSN 
**********************************

u "${basic}\rawdata.dta", clear

foreach var of varlist Q10Whatisthetotalamountof Q11Whatisthetotalamountof Q12Whatisthetotalamountof  Q13_1HowmanyAssociationsnet Q13_2HowmanynetworksofRela{
	destring `var', replace
	}	

*** Transfers 
	
tab Q10Whatisthetotalamountof
// winsor2 Q10Whatisthetotalamountof, cuts(0 95) suffix(_new) 
**su Q10Whatisthetotalamountof_new
ren Q10Whatisthetotalamountof loan

gen formal_trans = Q11Whatisthetotalamountof
graph box formal_trans
tab formal_trans
egen  med_formal_trans = median(formal_trans) 
replace formal_trans= med_formal_trans if formal_trans==1700800 
//winsor2 formal_trans, cuts(0 99) suffix(_new) 
**graph box formal_trans_new

gen informal_trans = Q12Whatisthetotalamountof
tab informal_trans
graph box informal_trans
winsor2 informal_trans, cuts(0 99) suffix(_new) 
drop informal_trans
ren informal_trans_new informal_trans

*** Associations

ren(Q13_1HowmanyAssociationsnet Q13_2HowmanynetworksofRela) (assosications relatives)
su assosications relatives 

tab assosications relatives 

foreach v of varlist assosications relatives{
recode `v' (. = 0)	
}

replace assosications= 10 if assosications>=10
replace relatives= 10 if relatives>=10


*** Receive SS Transfers 

gen receive_transfer = AMU


su loan formal_trans informal_trans assosications relatives receive_transfer

keep _id loan formal_trans informal_trans assosications relatives receive_transfer

rename (loan formal_trans informal_trans assosications relatives receive_transfer) (ssn_loan ssn_formal_trans ssn_informal_trans ssn_assosications ssn_relatives ssn_receive_transfer)

su
display _N //923 obs.  
sa "${basic}\ssn.dta", replace


**********************************
* Create the pillar AC
**********************************
u "${basic}\rawdata.dta", clear

keep _id Q14Cantheheadofthehouseho-Q20WhatpercentageofyourTOT

*** Read and Write

g literacy =1
replace literacy =0 if Q14Cantheheadofthehouseho =="no"
ta literacy,m

foreach var of varlist Q15Howmanyyearshasthehous Q16Howmanyyearshasthehous Q17Howmanyyearsonaverageh AMQ - AMW Q20WhatpercentageofyourTOT {
	destring `var', replace
	}

su Q15Howmanyyearshasthehous Q16Howmanyyearshasthehous Q17Howmanyyearsonaverageh

winsor Q16Howmanyyearshasthehous, p(.1) gen(highest_edu_mem)
winsor Q17Howmanyyearsonaverageh, p(.1) gen(average_years_edu)
winsor Q15Howmanyyearshasthehous, p(.1) gen(years_edu_hh)

su highest_edu_mem average_years_edu years_edu_hh


*** Sources of income // We keep only the sources of income that are associated with an activity. 

egen income_div = rowtotal(AMQ - AMU)
su income_div

*** Main source of income

egen income_employed = rowtotal(ANB - ANC)
egen income_selfemployed = rowtotal(AMZ - ANA)
su income_employed income_selfemployed

/*
su Q20Howmanydifferentcropsha
graph box Q20Howmanydifferentcropsha
winsor2 Q20Howmanydifferentcropsha, cuts(0 99) replace
ren Q20Howmanydifferentcropsha num_crops
su num_crops
*/ 


*** Percentage

ta Q20WhatpercentageofyourTOT

ren Q20WhatpercentageofyourTOT income_percent
replace income_percent=10 if income_percent<10 
replace income_percent=100 if income_percent>=100 // This is certainly not correct, we should verify the size of the income
ta income_percent


*____________________________________*

keep _id literacy years_edu_hh highest_edu_mem average_years_edu income_percent income_div income_employed income_selfemployed 
rename (literacy years_edu_hh highest_edu_mem average_years_edu income_percent income_div income_employed income_selfemployed)(ac_literacy ac_years_edu_hh ac_highest_edu_mem ac_average_years_edu ac_income_percent ac_income_div  ac_income_employed ac_income_selfemployed)
su
display _N //923 obs.  
sa "${basic}\ac.dta", replace

*************************************
* Creating variables on FOOD SECURITY
*************************************
u "${basic}\rawdata.dta", clear


**** In the past 7 days. 
foreach var of varlist Inthepast7daysiftherehav - AIY{
	destring `var', replace
	}

	
// HDDS is a dummy, sum them 	
	
foreach var of varlist _all { // Loop through all variables
    if regexm("`var'", "^HDDS") { // Check if the variable name starts with 'HDDS'
        local collist "`collist' `var'" // Add the variable name to the list
    }
}

egen hdds_sum = rowtotal(`collist') // Calculate the sum of selected columns
su hdds_sum


// this range from 1 to 7 days 
// Keep the one from wfp 
foreach var of varlist _all { // Loop through all variables
    if regexm("`var'", "^FCS") { // Check if the variable name starts with 'FCS'
        local collist "`collist' `var'" // Add the variable name to the list
    }
}
 
su `collist' 

gen fcs = 2*(FCS_cereal) +3*(FCS_legumes+FCS_nuts_seeds) +4*(FCS_milk_milkproducts+FCS_meat) +1*(FCS_fruits+FCS_vegetables)+0.5*(FCS_oils_fats+FCS_sugar)+0*(FCS_condiments)

ta fcs, m
su fcs 

// Women FCS

ren (Inthelast24hoursdidwomen AKD AKE Inthelast24hrsdidwomenag AKG AKH AKI AKJ AKK AKL) (w_cereal w_beans w_nuts w_green w_orange w_red w_meat w_eggs w_dairy w_fruits)

gen w_fcs = 2*(w_cereal) +3*(w_beans+w_nuts) +4*(w_dairy+w_meat) +1*(w_fruits+ w_green + w_orange + w_red)

replace w_fcs = fcs if missing(w_fcs)
ta w_fcs, m
su w_fcs 

// Large coping startegy

ren (Q28_1Howoftendayshadyour Q28_2Howoftendayshadyour Q28_3Howoftendayshadyour Q28_4Howoftendayshadyour Q28_5Howoftendayshadyour Q28_6Howoftendayshadyour Q28_7Howoftendayshadyour Q28_8Howoftendayshadyour Q28_9Howoftendayshadyour Q28_10Howoftendayshadyou Q28_11Howoftendayshadyou) (csi_days_lessexpensive csi_days_borrow csi_days_credit csi_days_immaturefood csi_days_consumestock csi_days_eatelsewhere csi_days_beg csi_days_sizeportion csi_days_adultcons csi_days_nbrmeal csi_days_entireday)

gen csi_long = (csi_days_lessexpensive + csi_days_borrow+csi_days_credit)*1 + (csi_days_immaturefood+csi_days_consumestock+csi_days_sizeportion)*2 + (csi_days_eatelsewhere+csi_days_beg+csi_days_adultcons)*3 + (csi_days_nbrmeal)*4+(csi_days_entireday)*5

gen inv_csi_long = 1/csi_long
replace inv_csi_long = 1/0.5 if missing(inv_csi_long)

// copping stategy short 


ren (Inthepast7daysiftherehav AIV AIW AIX AIY) (less_preferred borrow limit_portion adult_restriction restriction)

// ask for the scale to TL 

gen csi = borrow*2 + less_preferred*2 + limit_portion*3 + adult_restriction*2 + restriction*3




foreach var of varlist fcs w_fcs hdds_sum csi csi_long inv_csi_long {
		egen max_`var' =max(`var')
		egen min_`var' = min(`var')
		gen r_`var'= (`var'- min_`var')/(max_`var' - min_`var')
		drop min_`var' max_`var' 
		drop `var'
		ren r_`var' `var'
		}

		
		
		
keep _id fcs w_fcs csi hdds_sum csi_long inv_csi_long

su

sa "${basic}\fs.dta", replace

// FIES Food insecurity experience scale ? to explore. 


**********************************
*final dataset
**********************************
u "${basic}\characteristics.dta", clear

merge 1:1 _id using "${basic}\abs.dta"
drop _merge
merge 1:1 _id using "${basic}\ast.dta"
drop _merge
merge 1:1 _id using "${basic}\ssn.dta"
drop _merge
merge 1:1 _id using "${basic}\ac.dta"
drop _merge
merge 1:1 _id using "${basic}\fs.dta"
drop _merge

order _id

sa "${final}\clean_final.dta", replace

// do verification on the stability of the rci. 

// scales comes from documents. exept the coping startegy

******************************************
*variable check
******************************************
u "${final}\clean_final.dta", clear

global abs abs_watersource abs_electricity abs_distance_water abs_distance_index abs_maintoilet

corr $abs
pwcorr $abs, sig  star(.05) bonferroni
alpha $abs

global ast ast_land_ha ast_wealth_index ast_agri_index ast_input_index ast_tlu
corr $ast

pwcorr $ast, sig  star(.05) bonferroni
alpha $ast

global ssn ssn_loan ssn_formal_trans ssn_informal_trans ssn_assosications ssn_relatives

corr $ssn
pwcorr $ssn, sig  star(.05) bonferroni
alpha $ssn


// Strange to get a negative link. 




