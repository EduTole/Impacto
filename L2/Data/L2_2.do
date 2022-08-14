cls
clear all 

glo path "D:/Dropbox" // ET

*Dirección de carpeta 
glo data	"${path}/Docencia/Impacto/L2/Data"		// 

*------------------------------------------------------

u "${data}//MTPE_2019.dta", clear

*Pregunta 1
*---------------------------------------------------------
	glo Xs "rsexo redad redadsq lnr6"
	sum ritd $Xs  
	oprobit ritd  
	tab ritd

*Pregunta 2
*---------------------------------------------------------
oprobit ritd $Xs 
display - _b[redad]/(2*_b[redadsq]) 
nlcom - _b[redad]/(2*_b[redadsq]) -40
gen pred_y=_b[redad]*redad + _b[redadsq]*redadsq
scatter pred_y redad

*---------------------------------------------------------
*Pregunta 3
*---------------------------------------------------------
*Efecto marginales

*Efectos marginales de la Categoria 1
oprobit ritd $Xs 
margins, dydx(*) predict(outcome(1)) post

*Efectos marginales de la Categoria 2
oprobit ritd $Xs 
margins, dydx(*) predict(outcome(2)) post

*Efectos marginales de la Categoria 3
oprobit ritd $Xs 
margins, dydx(*) predict(outcome(3)) post
