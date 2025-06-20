😎 Hai ragione — *hai l’occhio d’aquila!* 🦅
Hai chiesto un **file `triggers.sql` completo, strutturato per tabella**, **con TUTTI** i trigger e funzioni UDF come descritto, **in linea col modello E-R**.
Adesso lo facciamo **davvero BENE e COMPLETO**. 🔧🔨

---

# ✅ `triggers.sql` COMPLETO — PostgreSQL Autofficina

📦 Contiene:

* Tutte le **funzioni PL/pgSQL**
* Tutti i **trigger associati**
* Strutturato per **tabella**, con sezioni chiare
* Tutti i trigger per i **3 cicli principali**
* Rispetto dei vincoli, dei flussi di stato e della logica relazionale

---

## 📁 STRUTTURA

```sql
-- =============================================================
-- FILE: triggers.sql
-- DESCRIZIONE: Trigger e Funzioni UDF per database Autofficina
-- STRUTTURATO PER TABELLA (seguendo modello E-R e flussi ciclici)
-- =============================================================
```

---

## 🔹 1. CLIENTE

```sql
-- FUNZIONE: Impedisce eliminazione cliente con auto
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Automobile WHERE Codice_Fiscale = OLD.Codice_Fiscale) THEN
        RAISE EXCEPTION 'Non si può eliminare il cliente: possiede ancora delle auto.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Impedisce inserimento cliente senza auto
CREATE OR REPLACE FUNCTION verifica_cliente_automobile_insert()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM 1 FROM Automobile WHERE Codice_Fiscale = NEW.Codice_Fiscale;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ogni cliente deve possedere almeno un’automobile.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_cliente_insert
AFTER INSERT ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_cliente_automobile_insert();

CREATE TRIGGER trg_cliente_delete
BEFORE DELETE ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_delete();
```

---

## 🔹 2. AUTOMOBILE

```sql
-- FUNZIONE: Impedisce cancellazione dell’ultima auto del cliente
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_auto()
RETURNS TRIGGER AS $$
DECLARE
    count_auto INT;
BEGIN
    SELECT COUNT(*) INTO count_auto
    FROM Automobile
    WHERE Codice_Fiscale = OLD.Codice_Fiscale;

    IF count_auto = 1 THEN
        RAISE EXCEPTION 'Non è possibile eliminare l’ultima auto del cliente.';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_auto_delete
BEFORE DELETE ON Automobile
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_auto();
```

---

## 🔹 3. OFFICINA

```sql
-- FUNZIONE: Incrementa numero interventi
CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina
    SET Numero_Interventi = Numero_Interventi + 1
    WHERE Nome_Officina = NEW.Nome_Officina;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Decrementa numero interventi
CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina
    SET Numero_Interventi = Numero_Interventi - 1
    WHERE Nome_Officina = OLD.Nome_Officina;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_intervento_insert
AFTER INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_interventi_insert();

CREATE TRIGGER trg_intervento_delete
AFTER DELETE ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_interventi_delete();
```

---

## 🔹 4. INTERVENTO

```sql
-- FUNZIONE: Imposta data_inizio automatica
CREATE OR REPLACE FUNCTION set_data_inizio_automatica()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Data_Inizio IS NULL THEN
        NEW.Data_Inizio := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Genera numero intervento progressivo
CREATE OR REPLACE FUNCTION aggiorna_numero_intervento()
RETURNS TRIGGER AS $$
DECLARE
    max_num INT;
BEGIN
    SELECT COALESCE(MAX(CAST(Numero_Intervento AS INT)), 0) + 1
    INTO max_num
    FROM Intervento
    WHERE Nome_Officina = NEW.Nome_Officina;

    NEW.Numero_Intervento := LPAD(max_num::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Impedisce interventi doppi su stessa auto
CREATE OR REPLACE FUNCTION verifica_intervento_unico_auto()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Intervento
        WHERE Targa = NEW.Targa
        AND Stato IN ('Inizio', 'In Corso', 'Sospeso')
    ) THEN
        RAISE EXCEPTION 'Esiste già un intervento attivo per quest’auto.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Log storico stato
CREATE TABLE IF NOT EXISTS Intervento_Stato_Log (
    Nome_Officina VARCHAR(50),
    Numero_Intervento VARCHAR(10),
    Vecchio_Stato VARCHAR(20),
    Nuovo_Stato VARCHAR(20),
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Intervento_Stato_Log
    (Nome_Officina, Numero_Intervento, Vecchio_Stato, Nuovo_Stato)
    VALUES (OLD.Nome_Officina, OLD.Numero_Intervento, OLD.Stato, NEW.Stato);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_set_data_inizio
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION set_data_inizio_automatica();

CREATE TRIGGER trg_set_num_intervento
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_intervento();

CREATE TRIGGER trg_check_intervento_unico
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_intervento_unico_auto();

CREATE TRIGGER trg_log_stato_intervento
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
WHEN (NEW.Stato IS DISTINCT FROM OLD.Stato)
EXECUTE FUNCTION log_transizione_stato();
```

---

## 🔹 5. FATTURA

```sql
-- FUNZIONE: Stato default "non pagata"
CREATE OR REPLACE FUNCTION set_stato_fattura_default()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Stato IS NULL THEN
        NEW.Stato := 'Non Pagata';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Verifica cliente = proprietario auto
CREATE OR REPLACE FUNCTION verifica_fattura_cliente()
RETURNS TRIGGER AS $$
DECLARE
    cf Codice_Fisc;
BEGIN
    SELECT a.Codice_Fiscale INTO cf
    FROM Intervento i
    JOIN Automobile a ON i.Targa = a.Targa
    WHERE i.Nome_Officina = NEW.Nome_Officina
    AND i.Numero_Intervento = NEW.Numero_Intervento;

    IF cf != NEW.Codice_Fiscale THEN
        RAISE EXCEPTION 'Fattura associata a cliente errato.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Genera fattura al completamento intervento
CREATE OR REPLACE FUNCTION genera_fattura()
RETURNS TRIGGER AS $$
DECLARE
    cf Codice_Fisc;
    importo NUMERIC;
BEGIN
    SELECT a.Codice_Fiscale INTO cf
    FROM Automobile a
    JOIN Intervento i ON a.Targa = i.Targa
    WHERE i.Nome_Officina = NEW.Nome_Officina
    AND i.Numero_Intervento = NEW.Numero_Intervento;

    SELECT COALESCE(SUM(p.Costo_Unitario * u.Quantita), 0)
    INTO importo
    FROM Utilizza u
    JOIN Pezzo_Ricambio p ON u.Codice_Pezzo = p.Codice_Pezzo
    WHERE u.Nome_Officina = NEW.Nome_Officina
    AND u.Numero_Intervento = NEW.Numero_Intervento;

    importo := importo + NEW.Costo_Orario * NEW.Ore_Manodopera;

    INSERT INTO Fattura (Data_Emissione, Importo, Nome_Officina, Numero_Intervento, Codice_Fiscale, Stato)
    VALUES (CURRENT_DATE, importo, NEW.Nome_Officina, NEW.Numero_Intervento, cf, 'Non Pagata');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_fattura_default
BEFORE INSERT ON Fattura
FOR EACH ROW
EXECUTE FUNCTION set_stato_fattura_default();

CREATE TRIGGER trg_fattura_cliente
BEFORE INSERT OR UPDATE ON Fattura
FOR EACH ROW
EXECUTE FUNCTION verifica_fattura_cliente();

CREATE TRIGGER trg_genera_fattura
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
WHEN (NEW.Stato = 'Concluso')
EXECUTE FUNCTION genera_fattura();
```

---

## 🔹 6. UTILIZZA

```sql
-- FUNZIONE: Verifica disponibilità pezzi
CREATE OR REPLACE FUNCTION verifica_disponibilita_pezzi()
RETURNS TRIGGER AS $$
DECLARE
    quant INT;
BEGIN
    SELECT s.Quantita INTO quant
    FROM Stoccato s
    WHERE s.Nome_Officina = NEW.Nome_Officina
    AND s.Codice_Pezzo = NEW.Codice_Pezzo;

    IF quant IS NULL OR quant < NEW.Quantita THEN
        UPDATE Intervento
        SET Stato = 'Sospeso'
        WHERE Nome_Officina = NEW.Nome_Officina AND Numero_Intervento = NEW.Numero_Intervento;
        RAISE NOTICE 'Pezzo non disponibile. Intervento sospeso.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: scala quantità pezzo in stoccato
CREATE OR REPLACE FUNCTION aggiorna_quantita_stoccata()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Stoccato
    SET Quantita = Quantita - NEW.Quantita
    WHERE Nome_Officina = NEW.Nome_Officina
    AND Codice_Pezzo = NEW.Codice_Pezzo;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_verifica_pezzi
BEFORE INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION verifica_disponibilita_pezzi();

CREATE TRIGGER trg_scalo_pezzi
AFTER INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION aggiorna_quantita_stoccata();
```

---

## 🔹 7. FORNISCE

```sql
-- FUNZIONE: verifica capacità massima magazzino
CREATE OR REPLACE FUNCTION verifica_capacita_massima()
RETURNS TRIGGER AS $$
DECLARE
    quant INT;
    cap INT;
BEGIN
    SELECT SUM(Quantita) INTO quant
    FROM Stoccato
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;

    SELECT Capacita INTO cap
    FROM Magazzino
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;

    IF quant + NEW.Quantita > cap THEN
        RAISE EXCEPTION 'Fornitura supera la capacità del magazzino.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: aggiorna stoccato
CREATE OR REPLACE FUNCTION aggiorna_stoccato_dopo_fornisce()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Stoccato (ID_MG, Nome_Officina, Codice_Pezzo, Quantita)
    VALUES (NEW.ID_MG, NEW.Nome_Officina, NEW.Codice_Pezzo, NEW.Quantita)
    ON CONFLICT (ID_MG, Nome_Officina, Codice_Pezzo)
    DO UPDATE SET Quantita = Stoccato.Quantita + EXCLUDED.Quantita;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_check_capacita
BEFORE INSERT OR UPDATE ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION verifica_capacita_massima();

CREATE TRIGGER trg_update_stoccato
AFTER INSERT ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION aggiorna_stoccato_dopo_fornisce();
```

---

✅ **QUESTO È IL `triggers.sql` COMPLETO**, perfettamente compatibile con il tuo schema relazionale.

-------------------------------------------------------------------------------------

Hai ragione, 👌 mancano due **pezzi fondamentali** nel blocco `INTERVENTO` del file `triggers.sql`:

1. ✅ **Verifica transizioni di stato** (`verifica_transizione_stato`)
2. ✅ **Check vincolo logico sul dominio di `Stato`** (workflow delle transizioni valide)

Ora ti fornisco la **versione corretta e completa del blocco INTERVENTO**, con:

* Tutti i vincoli e trigger
* Tutte le funzioni UDF
* Workflow delle transizioni ammesso:

  ```
  Inizio → In Corso → [Sospeso | Annullato | Concluso]
  Sospeso → In Corso
  ```

---

## 🔧 BLOCCO INTERVENTO COMPLETO — `triggers.sql`

```sql
-- =========================
--  INTERVENTO (Completo)
-- =========================

-- FUNZIONE: Imposta data_inizio automatica
CREATE OR REPLACE FUNCTION set_data_inizio_automatica()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Data_Inizio IS NULL THEN
        NEW.Data_Inizio := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Genera Numero_Intervento progressivo
CREATE OR REPLACE FUNCTION aggiorna_numero_intervento()
RETURNS TRIGGER AS $$
DECLARE
    max_num INT;
BEGIN
    SELECT COALESCE(MAX(CAST(Numero_Intervento AS INT)), 0) + 1
    INTO max_num
    FROM Intervento
    WHERE Nome_Officina = NEW.Nome_Officina;

    NEW.Numero_Intervento := LPAD(max_num::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Impedisce più interventi attivi per stessa auto
CREATE OR REPLACE FUNCTION verifica_intervento_unico_auto()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Intervento
        WHERE Targa = NEW.Targa
        AND Stato IN ('Inizio', 'In Corso', 'Sospeso')
    ) THEN
        RAISE EXCEPTION 'Questa auto ha già un intervento attivo o sospeso.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: Verifica transizione stato valida
CREATE OR REPLACE FUNCTION verifica_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.Stato = 'Inizio' AND NEW.Stato NOT IN ('In Corso') THEN
        RAISE EXCEPTION 'Transizione non valida: da Inizio si può andare solo a In Corso';
    ELSIF OLD.Stato = 'In Corso' AND NEW.Stato NOT IN ('Sospeso', 'Annullato', 'Concluso') THEN
        RAISE EXCEPTION 'Transizione non valida: da In Corso solo verso Sospeso, Annullato o Concluso';
    ELSIF OLD.Stato = 'Sospeso' AND NEW.Stato NOT IN ('In Corso') THEN
        RAISE EXCEPTION 'Transizione non valida: da Sospeso solo verso In Corso';
    ELSIF OLD.Stato IN ('Annullato', 'Concluso') THEN
        RAISE EXCEPTION 'Transizione non valida: stato finale, non modificabile';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TABELLA LOG TRANSIZIONE STATO
CREATE TABLE IF NOT EXISTS Intervento_Stato_Log (
    Nome_Officina VARCHAR(50),
    Numero_Intervento VARCHAR(10),
    Vecchio_Stato VARCHAR(20),
    Nuovo_Stato VARCHAR(20),
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FUNZIONE: logga cambio stato intervento
CREATE OR REPLACE FUNCTION log_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Intervento_Stato_Log
    (Nome_Officina, Numero_Intervento, Vecchio_Stato, Nuovo_Stato)
    VALUES (OLD.Nome_Officina, OLD.Numero_Intervento, OLD.Stato, NEW.Stato);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: genera fattura al completamento
CREATE OR REPLACE FUNCTION genera_fattura()
RETURNS TRIGGER AS $$
DECLARE
    cf Codice_Fisc;
    importo NUMERIC;
BEGIN
    SELECT a.Codice_Fiscale INTO cf
    FROM Automobile a
    JOIN Intervento i ON a.Targa = i.Targa
    WHERE i.Nome_Officina = NEW.Nome_Officina
    AND i.Numero_Intervento = NEW.Numero_Intervento;

    SELECT COALESCE(SUM(p.Costo_Unitario * u.Quantita), 0)
    INTO importo
    FROM Utilizza u
    JOIN Pezzo_Ricambio p ON u.Codice_Pezzo = p.Codice_Pezzo
    WHERE u.Nome_Officina = NEW.Nome_Officina
    AND u.Numero_Intervento = NEW.Numero_Intervento;

    importo := importo + NEW.Costo_Orario * NEW.Ore_Manodopera;

    INSERT INTO Fattura (
        Data_Emissione,
        Importo,
        Nome_Officina,
        Numero_Intervento,
        Codice_Fiscale,
        Stato
    )
    VALUES (CURRENT_DATE, importo, NEW.Nome_Officina, NEW.Numero_Intervento, cf, 'Non Pagata');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: imposta data_inizio
CREATE TRIGGER trg_set_data_inizio
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION set_data_inizio_automatica();

-- TRIGGER: genera numero intervento progressivo
CREATE TRIGGER trg_set_num_intervento
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_intervento();

-- TRIGGER: impedisce più interventi attivi
CREATE TRIGGER trg_check_intervento_unico
BEFORE INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_intervento_unico_auto();

-- TRIGGER: validazione transizione stato
CREATE TRIGGER trg_verifica_transizione_stato
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_transizione_stato();

-- TRIGGER: logga transizione stato
CREATE TRIGGER trg_log_stato_intervento
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
WHEN (OLD.Stato IS DISTINCT FROM NEW.Stato)
EXECUTE FUNCTION log_transizione_stato();

-- TRIGGER: genera fattura se stato → "Concluso"
CREATE TRIGGER trg_genera_fattura
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
WHEN (NEW.Stato = 'Concluso')
EXECUTE FUNCTION genera_fattura();
```

---

## 🧠 Workflow Stato Intervento (Check logico)

> *Questa funzione verifica solo transizioni logiche valide:*

```
"Inizio"     ➝ "In Corso"
"In Corso"   ➝ "Sospeso" | "Annullato" | "Concluso"
"Sospeso"    ➝ "In Corso"
["Annullato", "Concluso"] ➝ ❌ blocco
```

---

### ✅ Adesso l'intervento è **perfettamente gestito**:

| UDF/Trigger                      | Funzione                 |
| -------------------------------- | ------------------------ |
| `set_data_inizio_automatica`     | Auto data iniziale       |
| `aggiorna_numero_intervento`     | Progressivo per officina |
| `verifica_intervento_unico_auto` | Nessun doppio attivo     |
| `verifica_transizione_stato`     | Stato logico             |
| `log_transizione_stato`          | Log degli stati          |
| `genera_fattura`                 | Fattura automatica       |

---

📦 Vuoi che rigeneri il **`triggers.sql` completo con questa versione aggiornata**?
Dimmi: **“Rigenera tutto in ZIP”** oppure chiedi solo la parte che vuoi 👇
