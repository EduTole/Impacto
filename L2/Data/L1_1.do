cls
global path "D:\Dropbox"
global ENAHO 	"${path}\BASES\ENAHO\2020"
global Out 		"${path}\Docencia\Impacto\L2\Data"
global Codigo 	"${path}\BASES\ENAHO\DISEL-MTPE"


import excel "${Out}/_Data.xlsx", sheet("DataFinal") firstrow clear
d

label var L1 "Municipalidades acceden internet (Numero)"
label var L2 "Poblacion censada (Numero-2017)"
label var L3 "Superficie (Km)"
label var L4 "Hogares acceden internet (%)"

egen Lm=total(L1)
g L5=L1/Lm*100
label var L5 "Municipalidades acceden internet (%)"

g FIRST_IDDP=_n
tostring FIRST_IDDP, replace
replace FIRST_IDDP="0"+FIRST_IDDP if length(FIRST_IDDP)==1

order dpto FIRST_IDDP
d
saveold "${Out}/_Data_1.dta",replace

*Modulo de Trabajo
*****************************
u "${ENAHO}/enaho01-2020-500.dta",clear

*Filtro MTPE
do "${Codigo}/1.- Filtro de residentes habituales.do"
do "${Codigo}/2.- rArea.do"
do "${Codigo}/3.- rDpto y rDpto2.do"

do "${Codigo}/6.- r2.do"
do "${Codigo}/7.- r2r_a.do"
do "${Codigo}/8.- r2r_b.do"

do "${Codigo}/9c.- r3.do"
do "${Codigo}/10.- r4.do"
do "${Codigo}/11.- r5r4mtpe.do"
do "${Codigo}/12.- r5r4mtpe2.do"
do "${Codigo}/28.- r5r4mtpe3.do"

*Teletrabajo
*****************************
*Solo para dependientes:
/*
==4 por teletrabajo
==3 actividad laboral por remoto
*/
d p522*
tab p522a 

g rwh=(p522a==3 | p522a==4 ) if !missing(p522a)
*g rwh=(p522a==3 | p522a==4 ) 
label var rwh "==1 work at home"
label define rwh 1 "Work at home" 0 "No home"
label values rwh rwh
tab rwh [iw=fac500a] if ocu500==1

tab rDpto rwh [iw=fac500a], col nofreq
tab rDpto rwh [iw=fac500a], row nofreq
tab rDpto rwh [iw=fac500a] if ocu500==1, row nofreq
tab rDpto  [iw=fac500a] if ocu500==1 & rwh==1

*u "${empleo}/enaho500_2020.dta",clear

g FIRST_IDDP=substr(ubigeo,1,2)
g L6=(ocupinf ==1) /*Informalidad laboral*/
g L7=(r2r_b==5 & ocu500==1) if !missing(r2r_b, ocu500) /*peaocupada sup.*/
g L8=(r5r4mtpe3==6 & ocu500==1) if !missing(r5r4mtpe2, ocu500)  /*pea ocupada servicios*/
g L9=(r5r4mtpe3==3 & ocu500==1) if !missing(r5r4mtpe2, ocu500) /*pea ocupada manufactura*/
g L10=(r5r4mtpe3==4 & ocu500==1) if !missing(r5r4mtpe2, ocu500) /*pea ocupada construccion*/
g L11=(r5r4mtpe3==1 & ocu500==1) if !missing(r5r4mtpe2, ocu500) /*pea ocupada Agricultura*/
g L12=(p207==2 & ocu500==1) if !missing(p207 ,ocu500)  /*pea ocupada mujeres*/
g L13=(r4r<=4 & ocu500==1) if !missing(r4r ,ocu500)  /*ocupados tecnicos, profesionales , gerentes y vendedores */
g L14=(rArea==1 & ocu500==1) if !missing(rArea, ocu500) /*pea ocupada por area urbana */

collapse (mean) rwh L6 L7 L8 L9 L10 L11 L12 L13 L14 [iw=fac500a ],by(FIRST_IDDP rDpto)

label var rwh "==1 Teletrabajo (%)"
label var L6 "==1 Informal (%)"
label var L7 "==1 PEA ocupada sup univ. (%)"
label var L8 "==1 PEA ocupada servicios. (%)"
label var L9 "==1 PEA ocupada manufactura. (%)"
label var L10 "==1 PEA ocupada construccion. (%)"
label var L11 "==1 PEA ocupada agricultura. (%)"
label var L12 "==1 PEA ocupada mujeres. (%)"
label var L13 "==1 PEA ocupada profesionales, tecnivos, gerentes. (%)"
label var L14 "==1 PEA ocupada zonas urbanas. (%)"

saveold "${Out}/_Data_2.dta",replace

gl llave "conglome vivienda hogar"

u "${ENAHO}/sumaria-2020.dta",clear
merge 1:1 $llave using "${ENAHO}/enaho01-2020-100.dta", keep(match) nogen

do "${Codigo}/2.- rArea.do"

g FIRST_IDDP=substr(ubigeo,1,2)
g L11=(pobreza<=2)


g L15=(p1141==1) if !missing(p1141)
g L16=(p1142==1) if !missing(p1142)
g L17=(rArea==1) if !missing(rArea)

g pond= factor07 *mieperho 

g L18= gashog2d/mieperho/12
g L19= (pobreza<=2) if !missing(pobreza)

collapse (mean) L15 L16 L17 L18 L19 [iw=pond ],by(FIRST_IDDP )

label var L15 "==1 Hogar con acceso telefono(fijo) (%)"
label var L16 "==1 Hogar con acceso Celular (%)"
label var L17 "==1 Hogar en zonas urbanas (%)"
label var L18 "Gastos percapita (soles prom.)"
label var L19 "==1 Hogar pobre (%)"

saveold "${Out}/_Data_3.dta",replace

*Datos PBI percapita
*-------------------------------
import excel "${Out}/pbi_percapita_dpto.xlsx", sheet("Hoja4") firstrow clear
d
tostring ID, g(FIRST_IDDP)
tostring FIRST_IDDP, replace
replace FIRST_IDDP="0"+FIRST_IDDP if length(FIRST_IDDP)==1

rename pbipc L20
label var L20 "PBI percapita - 2020"

saveold "${Out}/_Data_4.dta",replace

*-----------------------------------------
* Union de bases dedatos
*-----------------------------------------
u "${Out}/_Data_1.dta",clear
merge 1:1 FIRST_IDDP using "${Out}/_Data_2.dta", nogen
merge 1:1 FIRST_IDDP using "${Out}/_Data_3.dta", nogen
merge 1:1 FIRST_IDDP using "${Out}/_Data_4.dta", nogen

keep rDpto FIRST_IDDP rwh L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 L13 L14 L15 L16 L17 L18 L19 L20
order rDpto FIRST_IDDP rwh L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 L13 L14 L15 L16 L17 L18 L19 L20 

replace rwh=rwh*100
foreach i in 6 7 8 9 10 11 12 13 14 15 16 17 19{
replace L`i'=L`i'*100
}

d
saveold "${Out}/_Data_teletrabajo_2020.dta",replace

*Borramos las bases anteriores
erase "${Out}/_Data_1.dta"
erase "${Out}/_Data_2.dta"
erase "${Out}/_Data_3.dta"
erase "${Out}/_Data_4.dta"
