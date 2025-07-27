# DATABASE-LAB-AUTOFFICINA 💡

---

```markdown
# 🚗 Progetto Database "Gestione Officine"

Questo repository contiene il progetto completo per la gestione di una catena di officine, con implementazione in PostgreSQL e analisi tramite R. Include modellazione concettuale, progettazione logica/fisica, popolamento dati e query analitiche.

Il repository contiene:

- `scripts/`: script di creazione tabelle e domini
- `scripts/sql_scripts/triggers/`: funzioni e trigger PL/pgSQL
- `scripts/popolamento/`: funzione python per creare i dati
- `scripts/sql_scripts/viste/`: viste per report e analisi
- `output/`: Risultati ottenuti e analisi su R
- `README.md`: documentazione sintetica

# Architettura del Database

- Tabelle principali: `Cliente`, `Automobile`, `Officina`, `Intervento`, `Magazzino`, `Pezzo_Ricambio`, `Fornitore`, `Fattura`
- Tabelle associative: `Utilizza`, `Fornisce`, `Stoccato`
- Trigger e funzioni per integrità e automazione



## Altre Risorse

- [Link al repository GitHub](https://github.com/CLASSDJWIK/DATABASE-LAB-AUTOFFICINA)
- Documentazione SQL e PL/pgSQL nel folder `triggers`
- Script R per analisi dati e creazione report

# Session Info




## 🔧 Tecnologie

- **PostgreSQL** per la gestione del database relazionale
- **R + ggplot2** per visualizzazione e analisi statistica
- **SQL** (funzioni, trigger, viste)
- **Python**  per il popolamento e  il caricamento dati
- **CSV**  esportare dati

---

## 🧱 Struttura del Database

| Tabella             | Record   | Note                                             |
|---------------------|----------|--------------------------------------------------|
| `clienti`           | 3.654    | Privati e Aziende (via generalizzazione)         |
| `automobili`        | 4.441    | Ogni auto ha un solo proprietario                |
| `fornitori`         | 58       | Classificati per nazione/continente              |
| `officine`          | 30       | Tutte in città FVG, collegate ai magazzini       |
| `magazzini`         | 30       | Relazione 1:1 con officine                       |
| `interventi`        | 4.437    | Stato gestito tramite ENUM                       |
| `pezzi_ricambio`    | 50       | Disponibilità tramite `stoccato` e `fornisce`    |
| `fatture`           | 4.409    | Generate per intervento                          |

---

## 📈 Esempi di Analisi

- Distribuzione clienti per continente e nazione dominante (pie chart)
- Top 10 officine per fatturato (barplot)
- Fornitori per continente (barplot + media)
- Marche auto più comuni (colorate per continente)
- Pezzi di ricambio più richiesti per nazione

✅ Le analisi sono basate su viste SQL e visualizzate tramite script `R`.

---

## 🔄 Popolamento

I dati sono stati generati tramite strumenti programi python che rispettando le regole precise della nostra database e importati tramite:

```sql
-- Inserimento di 5 clienti di esempio
INSERT INTO Cliente (Codice_Fiscale, Nome, Cognome, Indirizzo, Citta, CAP, Telefono) VALUES
('RMNALX80A012Z301', 'Alex', 'Romano', 'Via Roma 1', 'Udine', '33100', '1234567890'),
('BLCFBA90B123Z100', 'Fabiana', 'Blico', 'Via Milano 2', 'Trieste', '34121', '0987654321'),

-- Inserimento di 6 automobili associate ai clienti
INSERT INTO Automobile (Targa, Anno, Modello_Marca, Codice_Fiscale, Chilometraggio) VALUES
('AB102WQ', 2020, 'Fiat 500', 'RMNALX80A012Z301', 12000),
('CD209KI', 2022, 'VW Golf', 'BLCFBA90B123Z100', 5000),


-- Inserimento di 3 fornitori di esempio
INSERT INTO Fornitore (PIVA, Nome, Indirizzo, Citta, CAP, Prefisso) VALUES
('COK00001', 'Conley-Kim', 'Via Export 1', 'Udine', '33100', 'Z107'),
('AEF00002', 'Arajo e Filhos', 'Via Motori 11', 'Trieste', '34121', 'Z107'),

````





## 📌 Requisiti

* PostgreSQL ≥ 13
* R ≥ 4.0 + pacchetti: `DBI`, `dplyr`, `ggplot2`, `scales`, `RPostgres`
* (Opzionale) RShiny per interfaccia interattiva

---

## 👨‍💻 Autori
  @DJANGANG
  @BOLT 
  @LOVEPREET

* Progetto sviluppato nell'ambito del corso di Basi di Dati
* Università degli Studi di \[UDINE]
* A.A. 2024/2025

---

## 📜 Licenza

MIT License. Vedi `LICENSE.md` per dettagli.

```


