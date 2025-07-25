Perfetto! Il file `TRIGDML (1).SQL` contiene **molti trigger e funzioni**. Per testare **correttamente** questi trigger e verificarne il comportamento, possiamo procedere in modo strutturato.

Ti preparo **una batteria di test SQL**, suddivisa in **blocchi logici**, per **verificare** che i trigger e le funzioni stiano lavorando come previsto.

---

## ✅ **CHECKLIST dei trigger da testare**

| Trigger / Funzione               | Azione da testare                                | Test presente più sotto |
| -------------------------------- | ------------------------------------------------ | ----------------------- |
| `trg_cliente_delete`             | Non si può eliminare un cliente con auto         | ✅                       |
| `trg_auto_delete`                | Non si può eliminare un’auto attiva              | ✅                       |
| `trg_auto_insert`                | L’auto non può essere associata a CF inesistente | ✅                       |
| `trg_intervento_insert`          | Aumento `Numero_Interventi` officina             | ✅                       |
| `trg_intervento_delete`          | Diminuzione `Numero_Interventi` officina         | ✅                       |
| `trg_verifica_transizione_stato` | Validazione stato interventi                     | ✅                       |
| `trigger_verifica_disponibilita` | Blocca uso pezzi se non ci sono                  | ✅                       |
| `trg_aggiorna_quantita_stoccata` | Scala la quantità in `Stoccato`                  | ✅                       |
| `trg_richiesta_pezzo_mancante`   | Inserisce in `Richiesta_Fornitura`               | ✅                       |
| `trg_gestisci_flusso_intervento` | Conclude intervento se uso pezzo va bene         | ✅                       |
| `trg_genera_fattura`             | Genera fattura se intervento → `Concluso`        | ✅                       |
| `trg_verifica_fattura_cliente`   | Solo il cliente proprietario può avere fattura   | ✅                       |

---

## 🔧 **Batteria di test SQL (puoi lanciarli in psql o PgAdmin)**

### 1. Inserimento cliente e auto (base)

```sql
-- Cliente
INSERT INTO Cliente VALUES ('RSSMRA80A01Z123K', 'Mario', 'Rossi', 'Via Roma 1', 'Udine', '33100', '0432123456');

-- Auto associata
INSERT INTO Automobile VALUES ('AB123CD', 2020, 'Fiat Panda', 'RSSMRA80A01Z123K', 150000);
```

### 2. Test inserimento auto con CF non valido (trigger `trg_auto_insert`)

```sql
-- Deve fallire
INSERT INTO Automobile VALUES ('ZZ123ZZ', 2021, 'Opel Corsa', 'XXXXXXXXXXXXXXX', 1000);
```

### 3. Inserimento officina e magazzino

```sql
INSERT INTO Officina (Nome_Officina, Citta, Capacita_Magazzino, Numero_Interventi) VALUES ('Officina Udine', 'Udine', 100, 0);
INSERT INTO Magazzino VALUES (1, 'Officina Udine', 100);
```

### 4. Inserimento pezzo e fornitore + stock iniziale

```sql
INSERT INTO Pezzo_Ricambio VALUES ('PR001', 'Filtro Olio', 'Motore', 10.00);
INSERT INTO Fornitore VALUES ('RICUDI00001', 'RicambiUdine', 'Udine', 'Via Pezzi 12');
-- Inserimento stock via fornitura (attiva `aggiorna_stoccato_dopo_fornisce`)
INSERT INTO Fornisce (PIVA, Codice_Pezzo, Quantita, Data_Consegna, ID_MG, Nome_Officina)
VALUES ('RICUDI00001', 'PR001', 10, CURRENT_DATE, 1, 'Officina Udine');
```

### 5. Inserimento intervento

```sql
INSERT INTO Intervento (Nome_Officina, Numero_Intervento, Targa, Data_Inizio, Stato, Tipologia, Costo_Orario, Ore_Manodopera, Descrizione)
VALUES ('Officina Udine', '001', 'AB123CD', CURRENT_DATE, 'inizio', 'Cambio Olio', 50.0, 2.0, 'Cambio olio motore');
```

### 6. Transizione corretta stato (inizio → in corso)

```sql
UPDATE Intervento
SET Stato = 'in corso'
WHERE Numero_Intervento = '001' AND Nome_Officina = 'Officina Udine';
```

### 7. Inserimento utilizzo pezzo (testa: `verifica_disponibilita_pezzi`, `aggiorna_quantita_stoccata`, `trg_gestisci_flusso_intervento`)

```sql
INSERT INTO Utilizza (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita)
VALUES ('Officina Udine', '001', 'PR001', 2);
```

### 8. Verifica fattura (trigger `genera_fattura` automatico)

```sql
SELECT * FROM Fattura WHERE Numero_Intervento = '001' AND Nome_Officina = 'Officina Udine';
```

### 9. Tentativo eliminazione auto con intervento non concluso (deve fallire)

```sql
-- reset intervento sospeso per test
UPDATE Intervento SET Stato = 'in corso' WHERE Numero_Intervento = '001' AND Nome_Officina = 'Officina Udine';

-- tenta DELETE auto (dovrebbe bloccare)
DELETE FROM Automobile WHERE Targa = 'AB123CD';
```

### 10. Tentativo eliminazione cliente con auto (deve fallire)

```sql
DELETE FROM Cliente WHERE Codice_Fiscale = 'RSSMRA80A01Z123K';
```

---

## 📊 Vuoi anche script SQL per:

* **Reset database tra i test**?
* **Visualizzazioni con viste** da usare poi in R o Grafana?
* **Script automatizzati per testing (es. script `.sh` o psql)**?

Posso fornirli!
Fammi sapere se ti preparo anche il file `.sql` con **tutti i test sopra pronti da eseguire** ✔️

🔨🤖🔧
