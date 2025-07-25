
library(DBI)
library(RPostgres)

# Connessione al DB PostgreSQL
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "officina",
                 host = "localhost",
                 port = 5432,
                 user = "tuo_user",
                 password = "tua_password")


tables <- dbListTables(con)
# Filtra solo le tabelle "vere"
real_tables <- Filter(function(tbl) {
  !grepl("^v_", tbl, ignore.case = TRUE)  # oppure usa pattern delle tue VIEWs
}, tables)

# Ora conta solo per quelle tabelle
row_counts <- sapply(real_tables, function(tbl) {
  query <- paste0("SELECT COUNT(*) AS cnt FROM ", tbl)
  as.numeric(dbGetQuery(con, query)$cnt)
})


# Stampa il riepilogo
df_righe <- data.frame(Tabella = real_tables, Righe = row_counts)
print(df_righe)



# Funzione per ottenere le chiavi primarie di una tabella
get_primary_keys <- function(con, table) {
  query <- sprintf("
    SELECT a.attname
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = '%s'::regclass AND i.indisprimary;
  ", table)
  
  res <- dbGetQuery(con, query)
  return(res$attname)
}

# Leggi solo i campi PK per ogni tabella e stampa
pk_datasets <- lapply(real_tables, function(tbl) {
  pk_fields <- get_primary_keys(con, tbl)
  
  if (length(pk_fields) > 0) {
    query <- paste0("SELECT ", paste(pk_fields, collapse = ", "), " FROM ", tbl)
    df <- dbGetQuery(con, query)
    
    # Stampa preview
    cat("📦 Tabella:", tbl, "| PK:", paste(pk_fields, collapse = ", "), "\n")
    print(head(df, 5))
    
    # Esporta CSV nella directory corrente (setwd)
    file_name <- paste0(tbl, "_pk.csv")
    write.csv(df, file = file_name, row.names = FALSE)
  } else {
    cat("⚠️  Tabella:", tbl, "| Nessuna PK trovata\n")
  }
})


