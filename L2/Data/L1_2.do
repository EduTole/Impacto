cls
clear all
global ENAHO	"D:\Dropbox\BASES\ENAHO\2020"
global Codigo 	"${path}\BASES\ENAHO\DISEL-MTPE"

use "${ENAHO}/enaho01a-2020-500.dta",clear

* Filtración MTPE
drop if  fac500a==. 
drop if p501==.a | p501==. 
g corr=1 if  (p204==1 & p205==2) | (p204==2 & p206==1) 
keep if  corr==1


*Ingresos laborales
egen r6= rowtotal(i524a1 d529t i530a d536 i538a1 d540t i541a d543 d544t)    // generamos el ingreso en la ocupacion rincipal y secundario anual
replace r6= r6/12 

*Edad de la persona
g redad=p208a

*Sexo de la persona : ==2 mujer
g rmujer = (p207==2)

*Medicion del teletrabajo y trabajo remoto
g rwh=(p522a==3 | p522a==4 ) if !missing(p522a)
*g rwh=(p522a==3 | p522a==4 ) 
label var rwh "==1 work at home"
label define rwh 1 "Work at home" 0 "No home"
label values rwh rwh

*Area y departamento
do "${Codigo}/2.- rArea.do"
do "${Codigo}/3.- rDpto y rDpto2.do"

do "${Codigo}/9c.- r3.do"
do "${Codigo}/10.- r4.do"

*Sectores econmicos
do "${Codigo}/11.- r5r4mtpe.do"
do "${Codigo}/12.- r5r4mtpe2.do"
do "${Codigo}/28.- r5r4mtpe3.do"

*Ocupaciones
do "${Codigo}/18.- r8.do"
do "${Codigo}/19.- r8r.do"



*Filtros
*Solo jefe del hogar
*keep if p203==1

*No considera al sector agricultura
keep if r5r4mtpe!=1

*Solo ocupaciones (no considerar trabajador del hogar, artesano y operariop y jornalero)
keep if r8r!=6 
keep if r8r!=8
	
*-----------------------------------------------------------
* Estadisticas descriptivas
*-----------------------------------------------------------
*Proporcion cuantiles
xtile cuantil=r6 , nq(4)
svyset [pw=fac500a] 

*Proporcion por cuantiles
tab cuantil rwh [iw=fac500a], nofreq row
*Porcentaje de teletrabajo
tab rwh [iw=fac500a] if ocu500==1

*Porcentaje de teletrabajo por sectores
tab r5r4mtpe3 rwh [iw=fac500a] if ocu500==1, row nofreq

*Porcentaje de teletrabajo por departamentos
tab rDpto rwh [iw=fac500a] if ocu500==1, row nofreq

