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

# 📊 1. Pie Chart: Clienti per Nazione (Top 5 + Altri)
df_naz <- read_view("v_clienti_auto_nazione")

# Raggruppa
naz_counts <- df_naz %>%
  group_by(nazione) %>%
  summarise(Clienti = n()) %>%
  arrange(desc(Clienti))

# Top 5 + altri
naz_top5 <- naz_counts %>% slice_head(n = 5)
naz_other <- sum(naz_counts$Clienti) - sum(naz_top5$Clienti)

df_pie <- bind_rows(naz_top5, data.frame(nazione = "Altri", Clienti = naz_other))

# Pie chart
ggplot(df_pie, aes(x = "", y = Clienti, fill = nazione)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Paired") +
  labs(title = "Distribuzione Clienti per Nazione (Top 5 + Altri)") +
  theme_void()
