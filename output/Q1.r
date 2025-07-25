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
