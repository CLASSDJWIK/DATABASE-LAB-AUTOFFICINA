library(DBI)
library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)
library(RColorBrewer)


con <- dbConnect(RPostgres::Postgres(),
                 dbname = "offic",
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "love25")

# Helper per importare una vista
read_view <- function(viewname) {
  dbReadTable(con, viewname)
}


##🚗 2. Marche auto più comuni (Top 5)

df_marche <- read_view("v_marcheautoconti")

top_marche <- df_marche %>%
  group_by(modello_marca) %>%
  summarise(num_auto = sum(num_auto)) %>%
  arrange(desc(num_auto)) %>%
  head(5)

ggplot(top_marche, aes(x = reorder(modello_marca, num_auto), y = num_auto)) +
  geom_col(fill = "orange") +
  coord_flip() +
  labs(title = "Top 5 Marche Auto Più Presenti", x = "Marca", y = "Numero Auto")

