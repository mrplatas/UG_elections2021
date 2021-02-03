/*
	* Purpose: Clean txt file to append results for 2021 presidential election
	* Authors: Frederic Cochinard (frederic.cochinard@gmail.com), Melina Platas (mplatas@nyu.edu)
	* Date: Februrary 1, 2021
	* Last update: Februrary 3, 2021
	* Notes: pdfs of district level polling station results downloaded from https://www.ec.or.ug/2021-presidential-results-tally-sheets-district on Jan 30, 2021 
		and available at https://github.com/mrplatas/UG_elections2021/tree/main/pres_results_pdf
	
	USES
https://github.com/mrplatas/UG_elections2021/tree/main/pres_results_xlsx/`y'.xlsx"

SAVES
	"uganda_2021_pres_election_polling_station.dta"
	"uganda_2021_pres_election_polling_station.xlsx"
*/

	clear

	*set cd
	
	* We load the xlsx file

	forvalues y = 1/28 {
		
		import excel using "`y'.xlsx", sheet("Table 1") clear

		preserve

		forvalues x = 2/150 {

			cap import excel using "`y'.xlsx", sheet("Table `x'") clear
			
			cap tostring _all, replace
			
			cap tempfile save`x'
			cap sa "`save`x''"
			
			}
		
		restore

		tostring _all, replace

		forvalues x = 2/150 {

			cap append using "`save`x''", force
		
			}
			
		tempfile file_`y'
		sa "`file_`y''"
		
		}
		
	* Appending all files
	
	use "`file_1'", clear
	
	forvalues x = 2/28 {
	
		append using "`file_`x''"
		
		}
		
	tempfile full_sample
	sa "`full_sample'"
	
	sa "full_sample.dta", replace
	
	* Cleaning the appended sheets
	
	* Uniform
	
	foreach var of varlist _all {
	
		replace `var' = upper(`var')
		
		}
	
	* Page per district
	
	gen a = 1 if regexm(A,"PRESIDENTIAL ELECTIONS,")
	replace a = sum(a)
	order a, first
	
	drop if regexm(A,"PRESIDENTIAL ELECTIONS,")
	
	* District
	
	gen b = 1 if regexm(A,"DISTRICT:")
	order b, after(a)
	
	preserve
	
	keep a b B
	
	gen district = B if b == 1 
	order district, after(b)
	split district, p(" ")
	ren district1 district_id
	drop district
	
	gen district = district2
	replace district = district + " " + district3 if district3 != ""
	replace district = district + " " + district4 if district4 != ""
	drop district2 district3 district4 B b
	
	drop if district_id == ""
	
	tempfile temp
	sa "`temp'"
	
	restore
	
	merge m:1 a using "`temp'", nogen
	order district_id district, after(b)
	
	* Constituency
	
	gen c = 1 if regexm(B,"CONSTITUENCY TOTAL")
	replace c = 1 if regexm(C,"CONSTITUENCY TOTAL")
	order c, after(b)
	replace c = sum(c)

	preserve
	
	keep b c J K
	replace J = K if K != "" & J == ""
	replace J = "" if b != 1
	drop K b
	
	drop if J == ""
	duplicates drop
	byso c: gen d = _n
	drop if d == 2
	drop d
	
	ren J constituency
	split constituency, p(" ")
	ren constituency1 constituency_id
	drop constituency
	
	gen constituency = constituency2
	
	forvalues x = 3/6 {
		replace constituency = constituency + " " + constituency`x' if constituency`x' != ""
		}
		
	drop constituency2 constituency3 constituency4 constituency5 constituency6
	
	tempfile temp
	sa "`temp'"
	
	restore
	
	merge m:1 c using "`temp'"
	
	replace constituency_id = "XXX" if _merge == 1
	replace constituency = "NOT SPECIFIED" if _merge == 1
	drop _merge a b c

	order constituency_id constituency, after(district)
	
	* Sub-county
	
	gen a = 1 if regexm(B,"SUB-COUNTY TOTAL")
	replace a = 1 if regexm(C,"SUB-COUNTY TOTAL")
	replace a = sum(a)
	order a, first
	
	preserve
	
	keep a A
	replace A = "" if !regexm(A,"SUB-COUNTY:")
	replace A = subinstr(A,"SUB-COUNTY:","",.)
	replace A = trim(A)
	drop if A == ""
	
	duplicates drop
	byso a: gen d = _n
	drop if d == 2
	drop d
	
	ren A subcounty
	split subcounty, p(" ")
	ren subcounty1 subcounty_id
	drop subcounty
	
	gen subcounty = subcounty2
	
	forvalues x = 3/6 {
		replace subcounty = subcounty + " " + subcounty`x' if subcounty`x' != ""
		}
		
	drop subcounty2 subcounty3 subcounty4 subcounty5 subcounty6
	
	tempfile temp
	sa "`temp'"
	
	restore
	
	merge m:1 a using "`temp'"
	
	replace subcounty_id = "XXX" if _merge == 1
	replace subcounty = "NOT SPECIFIED" if _merge == 1
	drop _merge a

	order subcounty_id subcounty, after(constituency)

	* Parish
	
	gen a = 1 if regexm(B,"PARISH TOTAL")
	replace a = 1 if regexm(C,"PARISH TOTAL")
	replace a = sum(a)
	order a, first
	
	preserve
	
	keep a A
	
	replace A = "" if regexm(A,"SUB-COUNTY:")
	replace A = "" if regexm(A,"CHAIRPERSON,")
	replace A = "" if regexm(A,"JUSTICE SIMON")
	replace A = "" if regexm(A,"---")
	replace A = "" if A == "."
	replace A = "" if A == "RESULTS TALLY SHEET"
	replace A = subinstr(A,char(10)," ",.)
	replace A = trim(A)
	replace A = "" if A == "DISTRICT:" | A == "PARISH"
	drop if A == ""
	
	duplicates drop
	byso a: gen d = _n
	
	drop d
	
	replace A = subinstr(A,"- ","-",.)
	
	split A, p(" ")
	
	forvalues x = 1/5 {
		
		replace A`x' = trim(A`x')
		
		}
		
	ren A1 parish_id
	
	gen parish = A2
	
	forvalues x = 3/5 {
	
		replace parish = parish + " " + A`x' if A`x' != ""
		
		}
	
	drop A*
	
	tempfile temp
	sa "`temp'"
	
	restore
	
	merge m:1 a using "`temp'"
	
	replace parish_id = "XXX" if _merge == 1
	replace parish = "NOT SPECIFIED" if _merge == 1
	drop _merge a

	order parish_id parish, after(subcounty)

	* Tempfile for later crosscheck
	
	tempfile crosscheck
	sa "`crosscheck'"

	* Polling station
	
	replace B = trim(B)
	replace C = trim(C)
	
	drop if B == "CONSTITUENCY TOTAL" | B == "SUB-COUNTY TOTAL" | B == "PARISH TOTAL" | B == "DISTRICT TOTAL" | B == "STATION" | B == "."  
	drop if C == "CONSTITUENCY TOTAL" | C == "SUB-COUNTY TOTAL" | C == "PARISH TOTAL" | C == "DISTRICT TOTAL" | C == "STATION" | C == "." 
	drop if A == "DISTRICT:"
	drop if B == "" & C == ""
	
	gen order = 1 if B == "" & C != ""
	replace B = C if order == 1
	replace C = D if order == 1
	replace D = E if order == 1
	replace E = F if order == 1
	replace F = G if order == 1
	replace G = H if order == 1
	replace H = I if order == 1
	replace I = J if order == 1
	replace J = K if order == 1
	replace K = L if order == 1
	replace L = M if order == 1
	replace M = N if order == 1
	replace N = O if order == 1
	replace O = P if order == 1
	replace P = Q if order == 1
	replace Q = R if order == 1
	replace R = S if order == 1
	replace S = T if order == 1
	replace T = U if order == 1
	replace U = V if order == 1
	
	drop U V order
	
	local letter C D E F G H I J K L M N O P Q R S T
	
	foreach var of local letter {
		
		replace `var' = subinstr(`var',char(10)," ",.)
		split `var', p(" ")
		replace `var' = `var'1 
		cap drop `var'1 
		cap drop `var'2
		
		}
	
	
	replace B = subinstr(B,char(10)," ",.)
	split B, p(" ")
	
	ren B1 polling_station_id
	
	gen polling_station = B2
	
	forvalues x = 3/12 {
		replace polling_station = polling_station + " " + B`x' if B`x' != ""
		}
		
	drop B*
	
	order polling_station_id polling_station, after(parish)
	
	* Computing the register vote
	
	destring C, replace
	egen total = total(C)
	drop total
	* confirmed to the the official results
	
	ren C reg_voters
	drop A
	
	count
	* polling station confirmed to the official results
	
	* Creating the nullified polling stations
	
	gen nullified_polling_station = 0
	replace nullified_polling_station = 1 if polling_station == "RUTOOBO SDA CHURCH" & parish == "LAMIA WARD"
	replace nullified_polling_station = 1 if polling_station == "LUBANYI PRIMARY SCHOOL FRONT YARD" & parish == "LUBANYI WARD"
	replace nullified_polling_station = 1 if polling_station == "LUBANYI TECHNICAL" & parish == "LUBANYI WARD"
	replace nullified_polling_station = 1 if polling_station == "EXCEL PR. SCH.(KI-M)" & parish == "BWAISE I"
	replace nullified_polling_station = 1 if polling_station == "EXCEL PR. SCH.(N-NAL)" & parish == "BWAISE I"
	replace nullified_polling_station = 1 if polling_station == "MPERERWE PRI. SCHOOL (A- K)" & parish == "KAWEMPE II"
	replace nullified_polling_station = 1 if polling_station == "NAMWANDU NKOYOOYO'S HOME (KI-NABUK)" & parish == "KAWEMPE II"
	replace nullified_polling_station = 1 if polling_station == "SEBAMBA'S COMPOUND (NAMU-Z)" & parish == "KAWEMPE II"
	replace nullified_polling_station = 1 if polling_station == "NAMWANDU NKOYOOYO'S HOME (NANSO-Z)" & parish == "KAWEMPE II"
	replace nullified_polling_station = 1 if polling_station == "SERINA PR. SCHOOL (A - K)" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "SERINA PR. SCHOOL (L - NABU)" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "KISALOSALO (KIT-MUGE)- KYEBANDO VOC. TRAINING CTRE" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "LCI MEETING PLACE (KIT-NAI)" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "KISALOSALO (SSE-Z)- CLEVELAND PRI.SCH" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "KYEBANDO PROGRESSIVE P. SCH. (N - NAM)" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "LCI MEETING PLACE (NANT - Z)" & parish == "KYEBANDO"
	replace nullified_polling_station = 1 if polling_station == "UMARU NYAGO PARKING YARD (A-M)" & parish == "BWAISE II"
	replace nullified_polling_station = 1 if polling_station == "ST. JAMES CHURCH (A-M)" & parish == "BWAISE III"
	replace nullified_polling_station = 1 if polling_station == "LORD'S HARVEST CHURCH" & parish == "BWAISE III"
	replace nullified_polling_station = 1 if polling_station == "LC MEETING PLACE (A-L)" & parish == "BWAISE III"
	replace nullified_polling_station = 1 if polling_station == "LC MEETING PLACE (NAL- NAM)" & parish == "BWAISE III"
	replace nullified_polling_station = 1 if polling_station == "ST. FRANCIS NURSERY SCH. (O-Z)" & parish == "BWAISE III"
	replace nullified_polling_station = 1 if polling_station == "LATE J.B. KASAJJA' S PLACE[A-M]" & parish == "NDEEBA"
	replace nullified_polling_station = 1 if polling_station == "B.M.K. (A-M)" & parish == "NDEEBA"
	replace nullified_polling_station = 1 if polling_station == "B.M.K. (N-Z)" & parish == "NDEEBA"
	replace nullified_polling_station = 1 if polling_station == "LATE J.B. KASAJJA' S PLACE[N-Z]" & parish == "NDEEBA"
	replace nullified_polling_station = 1 if polling_station == "KARUKADONG" & parish == "NAADOI"
	replace nullified_polling_station = 1 if polling_station == "NKONGE CHURCH" & parish == "BULIJJO"
	replace nullified_polling_station = 1 if polling_station == "KYAMPISI SUBCOUNTY HQTRS [A-NAJ]" & parish == "KYABAKADDE"
	replace nullified_polling_station = 1 if polling_station == "NAMANGANGA" & parish == "KYABAKADDE"
	replace nullified_polling_station = 1 if polling_station == "KYAMPISI SUBCOUNTY HQTRS [NAK-Z]" & parish == "KYABAKADDE"
	replace nullified_polling_station = 1 if polling_station == "KASALA" & parish == "KYABAKADDE"
	replace nullified_polling_station = 1 if polling_station == "KALAGALA" & parish == "DDUNDU"
	replace nullified_polling_station = 1 if polling_station == "KASENENE" & parish == "NTONTO"
	replace nullified_polling_station = 1 if polling_station == "MBALALA PARENTS [A-M]" & parish == "KASENGE"
	replace nullified_polling_station = 1 if polling_station == "MBALALA S.S.S COMPOUND [A-M]." & parish == "KASENGE"
	replace nullified_polling_station = 1 if polling_station == "MBALALA S.S.S COMPOUND [N-Z]." & parish == "KASENGE"
	replace nullified_polling_station = 1 if polling_station == "NAMAWOJJOLO ISLAMIC P/S [A-M]" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "BWEFULUMYA EAST-AT FOREST HILL" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "BULIGOBE KITAWULUZI" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "NAMAWOJJOLO ISLAMIC P/S [N-Z]" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "NAMAWOJJOLO WEST [N-Z]" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "BWEFULUMYA WEST-AT FOREST HILL" & parish == "NAMAWOJJOLO"
	replace nullified_polling_station = 1 if polling_station == "GOSHEN LAND [NAK-Z]" & parish == "SEETA WARD"
	replace nullified_polling_station = 1 if polling_station == "KIBUUKA P/SCHOOL" & parish == "KIBUUKA"
	replace nullified_polling_station = 1 if polling_station == "KYANIKA CATHOLIC CHURCH" & parish == "KIBUUKA"
	replace nullified_polling_station = 1 if polling_station == "LWOYO P/SCHOOL" & parish == "KIBUUKA"
	replace nullified_polling_station = 1 if polling_station == "OLEL" & parish == "OIMAI"
	replace nullified_polling_station = 1 if polling_station == "BUGOROGORO" & parish == "KAMPALA"
	replace nullified_polling_station = 1 if polling_station == "KYATTUBA B" & parish == "BULONGO"
	replace nullified_polling_station = 1 if polling_station == "KABUKONGOTE PRI SCH" & parish == "KABUKONGOTE"
	replace nullified_polling_station = 1 if polling_station == "KAKINGA C.O.U" & parish == "LUBAALE"
	replace nullified_polling_station = 1 if polling_station == "NSOZI A" & parish == "KYAMBOGO"
	replace nullified_polling_station = 1 if polling_station == "KABAALE" & parish == "KABAALE" & district=="SSEMBABULE"
	replace nullified_polling_station = 1 if polling_station == "MBUYA MOSLEM" & parish == "MBUYA"
	replace nullified_polling_station = 1 if polling_station == "MBUYE/KATIKAMU" & parish == "MBUYA"
	replace nullified_polling_station = 1 if polling_station == "KIZAANO PENTECOSTAL CHURCH" & parish == "KAIRASYA"
	replace nullified_polling_station = 1 if polling_station == "NYAKATABO" & parish == "MWITSI"
	replace nullified_polling_station = 1 if polling_station == "NKOMA" & parish == "KYABI"
	replace nullified_polling_station = 1 if polling_station == "KABULASOKE" & parish == "LUTUNKU"
	replace nullified_polling_station = 1 if polling_station == "KAGANGO N-Z" & parish == "LWENTALE"
	replace nullified_polling_station = 1 if polling_station == "MITIMA" & parish == "MITIMA"
	replace nullified_polling_station = 1 if polling_station == "MISEENYI" & parish == "LWEMBOGO"
	replace nullified_polling_station = 1 if polling_station == "KABUUMBA-KITAWULUZI" & parish == "KABUUMBA"
	replace nullified_polling_station = 1 if polling_station == "BUNGWANYI C/U" & parish == "BUNGWANYI"
	replace nullified_polling_station = 1 if polling_station == "KAKONI C.O.U" & parish == "MIGYERA WARD"
	replace nullified_polling_station = 1 if polling_station == "KATAMCHUBA" & parish == "KATEBE"
	replace nullified_polling_station = 1 if polling_station == "LATIDA CENTRE" & parish == "PAWOR WEST"
	replace nullified_polling_station = 1 if polling_station == "AWENO - OLUI MARKET" & parish == "GOTKWAR"
	replace nullified_polling_station = 1 if polling_station == "MADDU TOWN COUNCIL HQTRS (A-M)" & parish == "MADDU WARD A"
	replace nullified_polling_station = 1 if polling_station == "BIGASA SUBCOUNTY PLAY GROUND" & parish == "MBIRIZI"
	replace nullified_polling_station = 1 if polling_station == "MIREMBE PRIMARY SCHOOL" & parish == "GAYAAZA"
	replace nullified_polling_station = 1 if polling_station == "KIBAATI" & parish == "KISAGAZI WARD"
	replace nullified_polling_station = 1 if polling_station == "KIRYASAKA HOPE PRI SCHOOL" & parish == "KISAGAZI WARD"
	replace nullified_polling_station = 1 if polling_station == "TEITEK CENTRE" & parish == "OMUGE"
	replace nullified_polling_station = 1 if polling_station == "BBANDA PRI. SCH" & parish == "KYANIKA"
	replace nullified_polling_station = 1 if polling_station == "KAMPUNGU P/SCHOOL" & parish == "BYERIMA"
	replace nullified_polling_station = 1 if polling_station == "KATTENJU PLAYGROUND" & parish == "KYASSIMBI"
	replace nullified_polling_station = 1 if polling_station == "BULYANA MOSQUE (A-M)" & parish == "KYASSIMBI"
	replace nullified_polling_station = 1 if polling_station == "BULYANA MOSQUE (N-Z)" & parish == "KYASSIMBI"
	replace nullified_polling_station = 1 if polling_station == "MASESE I (A-D)-LAKESIDE MAIN PLAYGROUND SOUTH" & parish == "MASESE WARD"
	replace nullified_polling_station = 1 if polling_station == "MASESE III (J-MAK)-BETHEL PRIMARY SCHOOL" & parish == "MASESE WARD"
	replace nullified_polling_station = 1 if polling_station == "ALL SAINTS NURSERY SCH.(N-Z)" & parish == "WALUKUBA EAST WARD"
		
	order nullified_polling_station, after(polling_station)
	
	* Correcting constituencies not specified -- creating new constituency_ids. These are new counties likely not reflected in EC system
	
	replace constituency_id = "800" if district_id=="065" & subcounty=="KASHONGI"
	replace constituency = "KASHONGI COUNTY" if district_id=="065" & subcounty=="KASHONGI"
	replace constituency_id = "800" if district_id=="065" & subcounty=="KITURA"
	replace constituency = "KASHONGI COUNTY" if district_id=="065" & subcounty=="KITURA"
	
	replace constituency_id = "801" if district_id=="018" & (subcounty=="CENTRAL DIVISION"|subcounty=="NORTH DIVISION"|subcounty=="SOUTH DIVISION")
	replace constituency = "KISORO MUNICIPALITY" if constituency_id=="801"
	
	replace constituency_id = "802" if district_id=="028" & (subcounty=="NORTH DIVISION"|subcounty=="SOUTH DIVISION")
	replace constituency = "MOROTO MUNICIPALITY" if constituency_id=="802"
	
	replace constituency_id = "803" if district_id=="033" & (subcounty=="ABINDU DIVISION"|subcounty=="CENTRAL DIVISION"|subcounty=="THATHA DIVISION")
	replace constituency = "NEBBI MUNICIPALITY" if constituency_id=="803"
	
	*Note there are duplicate subcounty_ids in DODOTH WEST COUNTY, KARENGA district
	replace constituency_id = "237" if district_id=="130" & constituency=="NOT SPECIFIED"
	replace constituency = "DODOTH WEST COUNTY" if constituency_id=="237"

	
	* Creating candidates variables
	
	local x = 0
	
	foreach var in D E F G H I J K L M N O P Q R S T {
		
		local x = `x' + 1
		replace `var' = "" if `var' == "."
		ren `var' var`x'
		
		}
		
	gen amuriat = var1 
	replace amuriat = var2 if var1 == ""
	destring amuriat, replace
	tab amuriat, m
	*cross-checked
	
	replace var2 = "" if var1 == ""
	drop var1
	
	gen kabuleta = var2 
	replace kabuleta = var3 if var2 == ""
	destring kabuleta, replace
	tab kabuleta, m
	*cross-checked
	
	replace var3 = "" if var2 == ""
	drop var2
	
	gen kalembe = var3 
	replace kalembe = var4 if var3 == ""
	destring kalembe, replace
	tab kalembe, m
	*cross-checked
	
	replace var4 = "" if var3 == ""
	drop var3
	
	gen katumba = var4 
	replace katumba = var5 if var4 == ""
	destring katumba, replace
	tab katumba, m
	*cross-checked
	
	replace var5 = "" if var4 == ""
	drop var4
	
	gen kyagulanyi = var5
	replace kyagulanyi = var6 if var5 == ""
	destring kyagulanyi, replace
	tab kyagulanyi, m
	*cross-checked
	
	replace var6 = "" if var5 == ""
	drop var5
	
	gen mao = var6
	replace mao = var7 if var6 == ""
	replace mao = var8 if var6 == "" & var7 == ""
	destring mao, replace
	tab mao, m
	*cross-checked
	
	replace var8 = "" if var7 == "" & var6 == ""
	replace var7 = "" if var6 == ""
	drop var6
	
	gen mayambala = var7
	replace mayambala = var8 if var7 == ""
	replace mayambala = var9 if var7 == "" & var8 == ""
	destring mayambala, replace
	tab mayambala, m
	*cross-checked
	
	replace var9 = "" if var8 == "" & var7 == ""
	replace var8 = "" if var7 == ""
	drop var7
	
	gen muntu = var8
	replace muntu = var9 if var8 == ""
	replace muntu = var10 if var8 == "" & var9 == ""
	replace muntu = var11 if var8 == "" & var9 == "" & var10 == ""
	destring muntu, replace
	tab muntu, m
	*cross-checked
	
	replace var11 = "" if var10 == "" & var9 == "" & var8 == ""
	replace var10 = "" if var9 == "" & var8 == ""
	replace var9 = "" if var8 == ""
	drop var8
	
	gen mwesigye = var9
	replace mwesigye = var10 if var9 == ""
	replace mwesigye = var11 if var10 == "" & var9 == ""
	replace mwesigye = var12 if var11 == "" & var10 == "" & var9 == ""
	destring mwesigye, replace
	tab mwesigye, m
	*cross-checked
	
	replace var12 = "" if var11 == "" & var10 == "" & var9 == ""
	replace var11 = "" if var10 == "" & var9 == ""
	replace var10 = "" if var9 == ""
	drop var9
	
	gen tumukunde = var10
	replace tumukunde = var11 if var10 == ""
	replace tumukunde = var12 if var11 == "" & var10 == ""
	replace tumukunde = var13 if var12 == "" & var11 == "" & var10 == ""
	destring tumukunde, replace
	tab tumukunde, m
	*cross-checked
	
	replace var13 = "" if var12 == "" & var11 == "" & var10 == ""
	replace var12 = "" if var11 == "" & var10 == ""
	replace var11 = "" if var10 == ""
	drop var10
	
	gen museveni = var11
	replace museveni = var12 if var11 == ""
	replace museveni = var13 if var12 == "" & var11 == ""
	replace museveni = var14 if var13 == "" & var12 == "" & var11 == ""
	destring museveni, replace
	tab museveni, m
	*cross-checked
	
	replace var14 = "" if var13 == "" & var12 == "" & var11 == ""
	replace var13 = "" if var12 == "" & var11 == ""
	replace var12 = "" if var11 == ""
	drop var11
	
	* Creating last variable about valid, invalid and total votes
	
	gen valid_votes = var12
	replace valid_votes = var13 if var12 == ""
	replace valid_votes = var14 if var13 == "" & var12 == ""
	replace valid_votes = var15 if var14 == "" & var13 == "" & var12 == ""
	destring valid_votes, replace
	tab valid_votes, m
	*cross-checked
	
	replace var15 = "" if var14 == "" & var13 == "" & var12 == ""
	replace var14 = "" if var13 == "" & var12 == ""
	replace var13 = "" if var12 == ""
	drop var12 
	
	gen invalid_votes = var13
	replace invalid_votes = var14 if var13 == ""
	replace invalid_votes = var15 if var14 == "" & var13 == ""
	replace invalid_votes = var16 if var15 == "" & var14 == "" & var13 == ""
	destring invalid_votes, replace
	tab invalid_votes, m
	*cross-checked
	
	replace var16 = "" if var15 == "" & var14 == "" & var13 == ""
	replace var15 = "" if var14 == "" & var13 == ""
	replace var14 = "" if var13 == ""
	drop var13 
	
	gen total_votes = var14
	replace total_votes = var15 if var14 == ""
	replace total_votes = var16 if var15 == "" & var14 == ""
	replace total_votes = var17 if var16 == "" & var15 == "" & var14 == ""
	destring total_votes, replace
	tab total_votes, m
	*cross-checked
	
	replace var17 = "" if var16 == "" & var15 == "" & var14 == ""
	replace var16 = "" if var15 == "" & var14 == ""
	replace var15 = "" if var14 == ""
	drop var14 
	
	drop var17 var16 var15
	
	* Labeling variables
	
	lab var district_id "District ID"
	lab var district "District name"
	lab var constituency_id "Constituency ID"
	lab var constituency "Constituency name"
	lab var subcounty_id "Subcounty ID"
	lab var subcounty "Subcounty"
	lab var parish_id "Parish ID"
	lab var parish "Parish name"
	lab var polling_station_id "Polling station ID"
	lab var polling_station "Polling station name"
	lab var nullified_polling_station "=1 if the polling station has been nullified"
	lab var reg_voters "Number of register voters"
	
	foreach var in amuriat kabuleta kalembe katumba kyagulanyi mao mayambala muntu mwesigye tumukunde museveni {
		
		lab var `var' "Number of votes for `var' in the PS"
		
		}
	
	lab var valid_votes "Total number of valid votes in the PS"
	lab var invalid_votes "Total number of invalid votes in the PS"
	lab var total_votes " Total number of votes in the PS"
	
	* Saving dataset
	sa "uganda_2021_pres_election_polling_station.dta", replace
	export excel using "uganda_2021_pres_election_polling_station.xlsx", first(var) replace
	
	
