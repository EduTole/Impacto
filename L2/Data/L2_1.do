cls
clear all 

glo path "D:/Dropbox" // ET

*Dirección de carpeta de bases ENAHO
glo main 	"${path}/BASES/ENAHO"
glo clean	"${path}/Docencia/Impacto/L2/Data"		// 
glo disel	"${main}/DISEL-MTPE"		// dofiles empleo

******************************************************
gl llave "conglome vivienda hogar codperso"

	forvalues i=2019/2019{
	
	u "${main}//`i'//enaho01a-`i'-500.dta", clear
	
	do "${disel}/1.- Filtro de residentes habituales.do"
	do "${disel}/2.- rArea.do"
	do "${disel}/3.- rDpto y rDpto2.do"
	do "${disel}/4.- r1.do"	
	do "${disel}/5.- r1r_a.do"
	do "${disel}/5.- r1r_b.do"
	do "${disel}/6.- r2.do"
	do "${disel}/7.- r2r_a.do"
	do "${disel}/9c.- r3.do"
	do "${disel}/10.- r4.do"
	do "${disel}/11.- r5r4mtpe.do"
	do "${disel}/12.- r5r4mtpe2.do"
	do "${disel}/28.- r5r4mtpe3.do"
	do "${disel}/15.- r6.do"
	do "${disel}/16.- r6prin.do"
	do "${disel}/18.- r8.do"
	do "${disel}/19.- r8r.do"
	do "${disel}/19.- r8r_v.do"
	do "${disel}/20.- r11.do"
	do "${disel}/21.- r11r.do"
	do "${disel}/22.- r19.do"
	do "${disel}/23.- r19em.do"
	do "${disel}/29.- r8r2.do"
	do "${disel}/30.- rhoras.do"
	do "${disel}/40a.- rinfo.do"
	do "${disel}/41.- rsexo.do"
	do "${disel}/38a.- redad.do"
	
	g ryear=`i'
	do "${disel}/45.- r7_rmv.do"

	*Unir variable de educación
	merge 1:1 $llave using "${main}//`i'//enaho01a-`i'-300.dta",  nogen
	
	*Generando las variable de desempleo y ninis
	do "${disel}/27.- r13_c.do"	

	*Calculando desempleo (ajustando IMR)
	***********************************
	preserve
	do "${disel}/31.- imr2.do"
	save "${main}//`i'//mod500_hogares_`i'.dta", replace
	*Base creada hogar
	restore

	preserve
	use "${main}//`i'//sumaria-`i'.dta", clear
	sort conglome vivienda hogar
	merge 1:1 conglome vivienda hogar using "${main}//`i'//mod500_hogares_`i'.dta"
	do "${disel}/32.- imr3.do"
	save "${main}//`i'//imr_`i'.dta", replace
	*Base creada imr
	restore

	do "${disel}/33.- imr4.do"
	sort domgeo
	merge m:1 domgeo using "${main}//`i'//imr_`i'.dta"
	drop _merge
	sort conglome vivienda hogar codperso

	
	*Informacion de desempleo
	do "${disel}/27.- r13.do"
	do "${disel}/27.- r13_d.do"
	
	
	*Calculo del ITD
	********************************************************************
	*Salud
	merge 1:1 $llave using "${main}//`i'//enaho01a-`i'-400.dta",keepusing(p4191 p419a1 p4192 p419a2 p4193 p419a3 p4194 p419a4 p4195 p419a5 p4196 p419a6 p4197 p419a7 p4198 p419a8) nogen
	do "${disel}/24.- rsalud.do"
	
	*Pension
	do "${disel}/25.- rpension.do"
	
	*Informacion de independientes
	g activida="1"
	merge 1:1 $llave activida using "${main}//`i'/enaho04-`i'-1-preg-1-a-13.dta", nogen keepusing(e1 e5)
	
	*Construccion de ITD
	display "-------------------------------Año: `i'"
	do "${disel}/46.- ritd.do"
	
	*Registro 
	do "${disel}/51.- r_registro.do"
		********************************************************************
	
	if `i'>=2018{
	drop r559_16-r559_50
	order $llave r* fac500a 
	cls
	d
	
	save "${clean}/MTPE_enaho500_`i'.dta", replace
*	erase "${main}//`i'//imr_`i'.dta"
*	erase "${main}//`i'//mod500_hogares_`i'.dta"
	}

	
	keep $llave r* p203 fac500a ocu500 jornal pension salud ingreso 
	drop r559_01-r559_15	
	order $llave r* p203 fac500a ocu500 jornal pension salud ingreso 
	cls
	d
	
	save "${clean}//MTPE_enaho500_`i'.dta", replace
	erase "${main}//`i'//imr_`i'.dta"
	erase "${main}//`i'//mod500_hogares_`i'.dta"
	
	}	
	
	
 u "${clean}//MTPE_enaho500_2019.dta", clear	
 keep if p203==1
 *rename r1r_b  redad
 g redadsq = redad*redad

 keep $llave r6 ritd rsexo redad redadsq rArea rDpto
 order $llave r6 ritd rsexo redad redadsq rArea rDpto
 
 *descripccion de missing
 mdesc  
 
 *Missing values 
 keep if r6!=.

 *Informacion de r6
 sum r6, detail
 local p1= r(p5)
 keep if r6>=`p1'
 
 g lnr6 =log(r6)
 
 saveold "${clean}//MTPE_2019.dta", replace	
		