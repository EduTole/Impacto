# Limpia todos los archivos anteriores a rm
rm(list=ls())
# Librerias : foreign versiones solo de <13
library(foreign)
# libreria de STATA
# install.packages("readstata13")
# install.packages("tidyverse")
# install.packages("haven")
library(readstata13)
library(tidyverse)
library(haven)

ruta_1 <- "D:/Dropbox/Docencia/Impacto/L2/Data"
setwd(ruta_1)

data <- read_dta("_Data_teletrabajo_2020.dta")

# Descripcion de la data
data %>% glimpse()

base <- data %>% 
  select(-FIRST_IDDP, -rDpto)
base %>% names()
base <- base %>% scale()
base %>% glimpse()

# https://www.statology.org/principal-components-analysis-in-r/
# Con todas estas librerias podemos tener la informacion de PCA en R
#install.packages("FactoMineR")
#install.packages("rpca")
#install.packages("factoextra")
library(tidyverse)
library(factoextra)
library(rpca)
library(FactoMineR)

# 02 Metodo de ACP ---------------
#----------------------------------------
PCA_res = PCA(base %>% 
                 data.frame() %>% 
                 select(rwh,
                        L4,L7,L8,L9,L12,L13,L14,L15,L16 ) %>% 
                 as.matrix())
# presenta un objeto de lista
names(PCA_res)
names(PCA_res$ind)
PCA_res$ind$coord %>% head(n=25)

# ACPR
#---------------------------------------
RPCA_res = rpca(base %>% 
                  data.frame() %>% 
                  select(rwh,
                         L4,L7,L8,L9,L12,L13,L14,L15,L16 ) %>% 
                  as.matrix(), 
                 trace = F)
names(RPCA_res)
L_matrix = data.frame(RPCA_res$L)
names(L_matrix) = paste0("Dim",1:ncol(L_matrix))
rownames(L_matrix) = paste0(data$rDpto)

RPCA_res$L %>% head()
RPCA_res$S %>% head()


# 03 Graficos de CLUSTER ------------------
# Grafico del número de Clsuter (K means)
# Grafico de silueta
fviz_nbclust(PCA_res$ind$coord, kmeans) # numero de correo 2 

PCA_KM2 = eclust(PCA_res$ind$coord, "kmeans", 2, nboot = 20, graph = F, seed = 123)
fviz_cluster(PCA_KM2, L_matrix)

RPCA_KM2 = eclust(L_matrix, "kmeans", 2, nboot = 20, graph = F, seed = 123)
fviz_cluster(RPCA_KM2, L_matrix)

# 04 Uniendo la data con todas las variables y los cluster ---------
data <- data %>% 
  mutate(ClusterPCA=paste0(PCA_KM2$cluster),
         ClusterRPCA = paste0(RPCA_KM2$cluster))

data %>%  names()
data %>%  str()
# Visualizacion de la informacion 
# Mostrando la informacion en mapas

# Cargando las librerias
#install.packages("sp")
#install.packages("sf")
library(sp) # Datos geograficos
library(sf)
tx <- st_read("D:/Dropbox/Mapas/Departamental/Departamentos.shp", stringsAsFactors=FALSE)
tx %>% names()
tx %>% str()

# Uniendo la informacion 
mapa_data<- inner_join(tx, data)

# Realizando el grafico
ggplot(mapa_data)+
  geom_sf(aes(fill=ClusterRPCA)) +
  ggtitle("Robust Principal Component  (k-Medias): Regiones")+
  scale_fill_discrete(name="Cluster de Teletrabajo",
                      breaks=c("1", "2"),
                      labels=c("Alta", "Baja"))
ggsave("f_cluster_1.png")

# Grafico iteractivo
#Graficos
#install.packages("rjson")
#install.packages("tidyverse")
#install.packages("highcharter")
#install.packages("stringi")
#install.packages("viridisLite")
#install.packages("scales")
library(rjson)
library(tidyverse)
library(highcharter)
library(stringi)
library(viridisLite)
library(scales)

# Agregando los nombres 
data <- data %>% 
  mutate(NOMBDEP= paste0(mapa_data$NOMBDEP))
data %>% names()

rename_map = function(x){
  x$properties$NOMBDEP=stri_trans_toupper(stri_trans_general(x$properties$NOMBDEP,"Latin-ASCII"))
  return(x)
}

peru = fromJSON(file = "https://raw.githubusercontent.com/juaneladio/peru-geojson/master/peru_departamental_simple.geojson")
peru$features = lapply(peru$features,rename_map)

# FIRST_IDDP
data$NOMBDEP = stri_trans_toupper(stri_trans_general(data$NOMBDEP,"Latin-ASCII"))
#corona_peru$FIRST_IDDP[corona_peru$PROVINCIA=="SANTO DOMINGO"] = "SANTO DOMINGO DE LOS TSACHILAS"
data$ClusterPCA = factor(data$ClusterPCA)
data$ClusterRPCA = factor(data$ClusterRPCA)

data$Teletrabajo = round(data$rwh, 2)
data$Informalidad = paste0(round(data$L6, 2),"%")
data$Pobreza = paste0(round(data$L19,2)," %")


# Mapa interactivo
hc_map_per =highchart(type = "map") %>% 
  hc_plotOptions(map = list(
    borderColor="white",
    allAreas = FALSE,
    joinBy = c("NOMBDEP", "NOMBDEP"),
    mapData = peru,
    dataLabels = list(enabled = TRUE,
                      format = '{point.NOMBDEP}'))) %>% 
  hc_title(text = "<b>2020: Grupos de pobreza, informalidad y cantidad de teletrabajadores, matriz L</b>",
           margin = 20, align = "center",
           style = list(color = "black", useHTML = TRUE)) %>%
#  hc_add_series(name = "Baja", data = corona_peru %>% filter(ClusterRPCA=="3"), color = "yellow") %>% 
  hc_add_series(name = "Alta", data = data %>% filter(ClusterRPCA=="1"), color = "orange") %>%
  hc_add_series(name = "Baja", data = data %>% filter(ClusterRPCA=="2"), color = "brown") %>%
  hc_add_series(name = "Sin dato", data = data %>% filter(is.na(ClusterRPCA)), color = "gray") %>%
  hc_tooltip(followPointer =  FALSE, useHTML=TRUE,
             pointFormat="{point.NOMBDEP} <br>
                          <b> {point.Teletrabajo} </b> personas.  <br>
                          <b> {point.Informalidad} </b> de informalidad.  <br>
                          <b> {point.Pobreza} </b> de personas bajo la pobreza") %>%
  hc_add_theme(hc_theme_economist()) 
hc_map_per

