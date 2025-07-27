# Carica la vista con modello + continente
df_marche_cont <- read_view("v_marcheautoconti")

# Calcola le top 5 marche per numero auto
top5_marche <- df_marche_cont %>%
  mutate(num_auto = as.numeric(num_auto)) %>%
  group_by(modello_marca, continente) %>%
  summarise(num_auto = sum(num_auto), .groups = "drop") %>%
  arrange(desc(num_auto)) %>%
  slice_head(n = 5)

# Definisci i colori
colori_continente <- c(
  "Africa"  = "#2ECC71",
  "Europa"  = "#FF6666",
  "America" = "#9B59B6",
  "Asia"    = "#F4D03F",
  "Oceania" = "#3498DB"
)

# Grafico
ggplot(top5_marche, aes(x = reorder(modello_marca, num_auto),
                        y = num_auto,
                        fill = continente)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = colori_continente) +
  labs(title = "Top 5 Marche Auto Più Presenti",
       subtitle = "Colorate per Continente di Origine",
       x = "Marca", y = "Numero Auto") +
  theme_minimal()
