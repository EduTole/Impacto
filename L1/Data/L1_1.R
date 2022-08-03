rm(list=ls())
library(vars)
#library(forecast)
library(foreign)
library(readr)
library(tidyverse)
library(readxl)

library(xtable)
library(arm)
library(pastecs)
#install.packages("DataCombine")
library(DataCombine)
library(janitor)

setwd("D:/Dropbox/Docencia/Impacto/L1/Data")

# Pregunta 02 -------

data_1 <- read_excel("Ajuste_rmv.xlsx")
base_1 <- ts(data_1,start = c(1950,1),freq=1)

# 2.1 Calculo del capital ------

tasa_1 = 0.025
delta = 0.05

base_1 = data.frame(base_1)
base_1$K = NA
base_1$K[1] = base_1$IBI[1]/(tasa_1+delta)
for(i in 2:nrow(base_1)) {
  base_1$K[i]= base_1$IBI[i]+(1-delta)*base_1$K[i-1]
}

base_1 <- base_1 %>% 
  mutate(kmil = K/1000,
         tasak =(kmil/lag(kmil,1)-1)*100,
         tasaibi =(IBI/lag(IBI,1)-1)*100)

# 2.2 Calculo de la tasa de crecimiento del PBI ------

base_1 <- base_1 %>% 
  mutate(tasapbi=(pbi/lag(pbi,1)-1)*100)
base_1 %>%  head(n=9)

# 2.3 Calculo de la PEA Ocupada ------

data_2 <- read_excel("peao_rmv.xlsx")
base_2 <- ts(data_2,start = c(2004,1),freq=1)
base_2 = data.frame(base_2)
base_2 <-base_2 %>% 
  mutate(tasapeao = (peao/lag(peao,1)-1)*100)

# 2.4 Filtros e Union de bases de datos -------
# Filtros
info_1 <- subset(base_1,year>=2009)
info_2 <- subset(base_2,...1>=2009)
info_2 <- info_2 %>% 
  mutate(year=...1) %>% 
  select(peao,tasapeao, year)
info_2 <- info_2[, c("year", "peao", "tasapeao")]


# Union de bases
rmv_1 <- merge(info_1, info_2, by.x="year",
               by.y = "year")

# 2.5 variacion % de RMV -----
alpha = 0.51 
rmv_1 <- rmv_1 %>% 
  mutate(tasaptf = tasapbi-alpha*tasak - (1-alpha)*tasapeao)
rmv_1 %>% head(n=5)
rmv_1 %>% tail(n=5)

# Grafico de la PTF
g0 <- ggplot(data=rmv_1, aes(x=year, y=tasaptf)) +
  geom_bar(stat="identity", fill="steelblue") +
  labs(x="", y="Var %")+
  ggtitle("Tasa PTF 2009-2020")
g0
ggsave("Imagen/figura_ptf.png")

barplot(rmv_1$tasaptf)

# 2.6 cargamos la informacion inflacion subyacente -----

data_3 <- read_excel("ipcsub_rmv.xlsx")
base_3 <- ts(data_3,start = c(2002,1),freq=1)
base_3

# filtro solo desde el 2009
base_3 <- data.frame(base_3)
info_3 <- subset(base_3, year>=2009)

# 2.7 agregamos el valor RMV ------
data_4 <- read_excel("rmv_rmv.xlsx")
base_4 <- ts(data_4,start = c(2009,1),freq=1)
base_4
base_4 <- data.frame(base_4)

# 2.8 Base final para calculos ------
# Union 
rmv_2 <- merge(rmv_1, info_3, by.x="year", by.y="year")

# Filtro de las variables ipc subyacente y tasa PTF
rmv_2 <- rmv_2[, c("year", "tasaptf","ipcsub", "tasapeao",
                   "peao","tasak","K","tasaibi","IBI","tasapbi", "pbi")]
rmv_2 %>% head(n=5)
rmv_2 %>% tail(n=5)

# Union rmv 
rmv_3 <- merge(rmv_2, base_4, by.x="year", by.y="year")
rmv_3 %>% tail(n=5)

# exportar informacion de excel
# install.packages("writexl")
library(writexl)
write_xlsx(rmv_3, "rmv_calculos.xlsx")

# Agregar la informacion 2021
info_2021 <- c(2021,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA)
info_2022 <- c(2022,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA)
rmv_3 <- rbind(rmv_3, info_2021)
rmv_3 <- rbind(rmv_3, info_2022)

rmv_3$tasapeao[13]=13.1
rmv_3$tasaibi[13]=20
rmv_3$tasapbi[13]=13.0
rmv_3$tasak[13]=5.0
rmv_3$tasaptf[13]=rmv_3$tasapbi[13]-alpha*rmv_3$tasak[13]-(1-alpha)*rmv_3$tasapeao[13]

# Proyeccion de Inflacion subyacente
rmv_3$ipcsub[13]=3.1
rmv_3$ipcsub[14]=3.1

# Variacion de ipc 
var_ipcsub  = rmv_3$ipcsub[13]+rmv_3$ipcsub[14]
# Variacion de ptf
var_ptf = rmv_3$tasaptf[13]
# Variacion de RMV
var_rmv = var_ptf+ var_ipcsub

# Aumento de la RMV
rmv_3$rmv[13]=rmv_3$rmv[12]+((var_rmv/100)*rmv_3$rmv[12])

rmv_3 %>% tail(n=5)

# Grafico de la RMV
g1 <- ggplot(data=rmv_3, aes(x=year, y=rmv)) +
  geom_line(size=1.4, color='red') +
  theme_light()+
  labs(x="", y="S/.")+
  ggtitle("RMV Nominal 2009-2020")
g1
ggsave("Imagen/figura_rmv.png")

rmv_3 %>% tail(n=4)

# Grafico de RMV
rmv_q0 <- subset(rmv_3, year==2021)

T_1 <- rmv_q0 %>%
  mutate(variable = "2021") %>% 
  group_by(variable) %>%
  summarise(RMV = max(rmv),
            PBI = max(tasapbi),
            K = max(tasak),
            L = mean(tasapeao),
            Pi = mean(ipcsub),
            PTF = mean(tasaptf))
T_1
# Cuadro en Latex
xt1<-xtable(T_1, align='lccccccc')
names(xt1) <- c('Horizonte','RMV','PBI','Capital', 'Trabajo', 'Inflacion', 'PTF'  )
print(xt1, type = "latex", file ="Tablas/T-1.tex")
