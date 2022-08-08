cls
clear all

gl Data 	"D:\Dropbox\Docencia\Impacto\L1\Data"
gl Imagen 	"D:\Dropbox\Docencia\Impacto\L1\Imagen"
gl Tabla 	"D:\Dropbox\Docencia\Impacto\L1\Tablas"

use "$Data/BD_1.dta",clear

gl Xs "rmujer reduca rexper rexpersq rpareja"
gl Zs "reduca rexper rexpersq rpareja"
g lnr6=log(r6)

*Grafico
cumul r6 if rmujer==1 , g(y1) 
cumul r6 if rmujer==0 , g(y2) 
	
	tw conn y1 y2 r6 if r6<4001 , sort xline(1000) connect(J J ) ms(none none )  graphr(color(white)) legend(label(1 "Mujer") label(2 "Hombre") rows(1) size(1.9)) subtitle("")  xtitle("Salarios - mensuales por Genero de trabajador (S/.)") ytitle("Porcentaje de trabajadores" ,size(2.9)) note("Fuente : INEI - 2021" "Elaboracion: Autor"  ) 	
graph save "$Imagen\\e_1.gph", replace
graph export "$Imagen\\e_1.pdf", replace
graph export "$Imagen\\e_1.emf", replace	
graph export "$Imagen\\e_1.png", replace	


tw (kdensity lnr6 if rmujer==1) (kdensity lnr6 if rmujer==0), legend(label(1 "Mujer") label(2 "Hombre") rows(1) size(1.9)) graphr(color(white)) ytitle("Densidad") xtitle("")
graph save "$Imagen\\e_2.gph", replace
graph export "$Imagen\\e_2.pdf", replace
graph export "$Imagen\\e_2.emf", replace
graph export "$Imagen\\e_2.png", replace


*Estadisticas
*------------------------------------
sum $Xs
tabstat lnr6 rmujer reduca rexper rexpersq rpareja, s(n mean p50 min max sd) col(stat)
		
*Test de Media
*------------------------------------
ttest lnr6, by(rmujer)
ttest reduca, by(rmujer)
ttest rexper, by(rmujer)
ttest rexpersq, by(rmujer)
ttest rpareja, by(rmujer)


*Regresion por tipo de empleo
*Oaxaca - Blinder
*------------------------------------
reg lnr6  $Zs if rmujer==1 , r
estimates store informal

reg lnr6  $Zs if rmujer==0, r
estimates store formal

*Esta ecuacion asume la estructura de informal en ausencia de  tratamiento desigual
oaxaca8 informal formal, weight(1)
*Esta ecuacion asume la estructura de formal en ausencia de  tratamiento desigual
oaxaca8 informal formal, weight(0)

*Detalle de Oaxaca Blinder
*Estructura de ecuacion segun la predominancia de ingresos de hombres
oaxaca lnr6  $Zs , by(rmujer) weight(1) vce(robust) nodetail
*Estructura de ecuacion segun la predominancia de ingresos de mujeres
oaxaca lnr6  $Zs , by(rmujer) weight(0) vce(robust) nodetail

*Descomposcion de la brecha salaria segun  genero
oaxaca lnr6 $Zs , by(rmujer) nodetail pooled r


