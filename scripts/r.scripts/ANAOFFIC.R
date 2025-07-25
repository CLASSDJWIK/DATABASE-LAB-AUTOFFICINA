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

# 1. Carica dati dalla vista (che contiene: cliente, nazione, continente)
df_cont <- read_view("v_clienti_auto_nazione")

# 2. Calcola numero clienti per Nazione + Continente
naz_cont_counts <- df_cont %>%
  group_by(continente, nazione) %>%
  summarise(Clienti = n(), .groups = "drop")

# 3. Calcola totale per continente
cont_totali <- naz_cont_counts %>%
  group_by(continente) %>%
  summarise(Clienti_Totali = sum(Clienti), .groups = "drop")

# 4. Trova nazione top per ogni continente
naz_top_per_cont <- naz_cont_counts %>%
  group_by(continente) %>%
  slice_max(order_by = Clienti, n = 1) %>%
  select(continente, nazione_top = nazione)

# 5. Unisci label continentale + nazione
cont_etichettate <- cont_totali %>%
  left_join(naz_top_per_cont, by = "continente") %>%
  mutate(label = paste0(continente, " (", nazione_top, ")"))

# 6. Se ci sono più di 5, unisci gli altri in "Altri"
top5 <- cont_etichettate %>% slice_max(Clienti_Totali, n = 5)
altri_totale <- sum(cont_etichettate$Clienti_Totali) - sum(top5$Clienti_Totali)

df_pie_finale <- bind_rows(
  top5,
  data.frame(continente = "Altri", Clienti_Totali = altri_totale, nazione_top = "", label = "Altri")
)

# 7. Grafico pie chart
ggplot(df_pie_finale, aes(x = "", y = Clienti_Totali, fill = label)) +
  geom_bar(width = 1, stat = "identity", color = "white") +
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Pastel1") +
  labs(title = "Distribuzione Clienti per Continente (con Nazione Dominante)") +
  theme_void()


## PER NAZIONE E CONTINENTE

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


