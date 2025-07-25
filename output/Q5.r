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

##🌍 5. Pezzi Forniti per Continente (5 Colori + Linea Media)

df_forn_cont <- df_forn %>%
  group_by(continente) %>%
  summarise(totale_pezzi = sum(totale_pezzi_consegnati)) %>%
  arrange(desc(totale_pezzi))

media_cont <- mean(df_forn_cont$totale_pezzi)

ggplot(df_forn_cont, aes(x = reorder(continente, totale_pezzi),
                         y = totale_pezzi,
                         fill = continente)) +
  geom_col() +
  coord_flip() +
  scale_fill_brewer(palette = "Dark2") +
  labs(
    title = "Quantità Totale Pezzi Forniti per Continente",
    subtitle = paste("Media Globale =", round(media_cont)),
    x = "Continente", y = "Totale Pezzi Forniti"
  ) +
  theme_minimal()


ggsave("grafico_pie_nazioni.png", width = 8, height = 6)
