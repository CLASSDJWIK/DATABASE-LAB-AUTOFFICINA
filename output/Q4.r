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


#🏭 4. Top 10 Officine per Fatturato (senza linea rossa)

df_fatture <- read_view("v_officine_fatturato")

top10 <- df_fatture %>%
  filter(!is.na(fatturato_totale)) %>%
  arrange(desc(fatturato_totale)) %>%
  head(10)

ggplot(top10, aes(x = reorder(nome_officina, fatturato_totale), 
                  y = fatturato_totale,
                  fill = nome_officina)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_y_continuous(labels = function(x) paste0("€", format(x, big.mark = ".", decimal.mark = ","))) +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Top 10 Officine per Fatturato",
       x = "Officina", y = "€ Fatturato") +
  theme_minimal() +
  theme(legend.position = "none")
