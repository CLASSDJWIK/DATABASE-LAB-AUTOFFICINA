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

##🚛 3. Top 10 Fornitori per Quantità (Colori per Continente)

df_forn <- read_view("v_top_fornitori_continenti")

top10_forn <- df_forn %>%
  arrange(desc(totale_pezzi_consegnati)) %>%
  slice_head(n = 10)

ggplot(top10_forn, aes(x = reorder(nome_fornitore, totale_pezzi_consegnati),
                       y = totale_pezzi_consegnati,
                       fill = continente)) +
  geom_col() +
  coord_flip() +
  labs(title = "Top 10 Fornitori per Quantità Fornita",
       subtitle = "Colori per Continente di Provenienza",
       x = "Fornitore", y = "Quantità Fornita") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2")
