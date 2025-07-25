
library(DBI)
library(RPostgres)

# Connessione al DB PostgreSQL
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "officina",
                 host = "localhost",
                 port = 5432,
                 user = "tuo_user",
                 password = "tua_password")


tabelle <- c("Cliente", "Automobile", "Officina", "Magazzino", "Pezzo_Ricambio", 
             "Stoccato", "Fornitore", "Fornisce", "Intervento", "Utilizza", "Fattura")

# Funzione per contare i record di una tabella
count_records <- function(tablename) {
  query <- sprintf("SELECT COUNT(*) AS cnt FROM %s;", tablename)
  res <- dbGetQuery(con, query)
  return(res$cnt)
}

# Ciclo per stampare le quantità per ogni tabella
for (tab in tabelle) {
  cat(sprintf("Tabella '%s' ha %d record\n", tab, count_records(tab)))
}


# Lista chiavi primarie per tabella in forma di vettore o lista di colonne
chiavi_primarie <- list(
  Cliente = c("Codice_Fiscale"),
  Automobile = c("Targa"),
  Officina = c("Nome_Officina"),
  Magazzino = c("ID_MG", "Nome_Officina"),
  Pezzo_Ricambio = c("Codice_Pezzo"),
  Stoccato = c("ID_MG", "Nome_Officina", "Codice_Pezzo"),
  Fornitore = c("PIVA"),
  Fornisce = c("PIVA", "Codice_Pezzo", "Data_Consegna", "ID_MG", "Nome_Officina"),
  Intervento = c("Nome_Officina", "Numero_Intervento"),
  Utilizza = c("Nome_Officina", "Numero_Intervento", "Codice_Pezzo"),
  Fattura = c("Numero_Fattura")
)

# Lista per salvare i dataset caricati
dataset_chiavi <- list()

for (tab in names(chiavi_primarie)) {
  colonne <- paste(chiavi_primarie[[tab]], collapse = ", ")
  query <- sprintf("SELECT %s FROM %s LIMIT 100;", colonne, tab)  # O togli LIMIT per tutto
  dataset_chiavi[[tab]] <- dbGetQuery(con, query)
  
  cat(sprintf("\nDati chiave primaria di tabella '%s':\n", tab))
  print(dataset_chiavi[[tab]])
}
