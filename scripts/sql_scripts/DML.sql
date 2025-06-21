 
---
-- # 🎯 `triggers.sql` — **Sistema Autofficina**


-- =============================================================
-- FILE: triggers.sql
-- DESCRIZIONE: Trigger e Funzioni per Database Autofficina
-- STRUTTURATO PER TABELLA secondo modello E-R
-- ===========================================================

---

--- ## 🔹 1. CLIENTE

-- FUNZIONE: impedisce eliminazione cliente con auto
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Automobile WHERE Codice_Fiscale = OLD.Codice_Fiscale) THEN
        RAISE EXCEPTION 'Impossibile eliminare cliente: possiede ancora delle auto.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: verifica che ogni cliente abbia almeno un'automobile
CREATE OR REPLACE FUNCTION verifica_cliente_automobile()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Automobile
        WHERE Codice_Fiscale = NEW.Codice_Fiscale
    ) THEN
        RAISE EXCEPTION 'Ogni cliente deve possedere almeno un automobile.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_cliente_insert
AFTER INSERT ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_cliente_automobile();

CREATE TRIGGER trg_cliente_delete
BEFORE DELETE ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_delete();


---

-- ## 🔹 2. AUTOMOBILE


-- FUNZIONE: impedisce eliminazione dell’unica auto del cliente
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_auto()
RETURNS TRIGGER AS $$
DECLARE
    count_auto INT;
BEGIN
    SELECT COUNT(*) INTO count_auto
    FROM Automobile
    WHERE Codice_Fiscale = OLD.Codice_Fiscale;

    IF count_auto = 1 THEN
        RAISE EXCEPTION 'Non si può eliminare l ultima auto del cliente.';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_auto_delete
BEFORE DELETE ON Automobile
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_auto();

---

-- ## 🔹 3. OFFICINA


-- FUNZIONE: incrementa numero interventi
CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina
    SET Numero_Interventi = Numero_Interventi + 1
    WHERE Nome_Officina = NEW.Nome_Officina;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: decrementa numero interventi
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


---

-- ## 🔹 4. INTERVENTO


-- FUNZIONE: imposta Data_Inizio = CURRENT_DATE se NULL
CREATE OR REPLACE FUNCTION set_data_inizio_automatica()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Data_Inizio IS NULL THEN
        NEW.Data_Inizio := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: genera numero intervento progressivo
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

-- FUNZIONE: impedisce più interventi attivi per la stessa auto
CREATE OR REPLACE FUNCTION verifica_intervento_unico_auto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Stato IN ('inizio', 'in corso', 'sospeso') THEN
        IF EXISTS (
            SELECT 1 FROM Intervento
            WHERE Targa = NEW.Targa
              AND Stato IN ('inizio', 'in corso', 'sospeso')
              AND (Nome_Officina, Numero_Intervento) <> (NEW.Nome_Officina, NEW.Numero_Intervento)
        ) THEN
            RAISE EXCEPTION 'Esiste già un intervento attivo per l automobile %', NEW.Targa;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TABELLA: log storico delle transizioni
CREATE TABLE IF NOT EXISTS Intervento_Stato_Log (
    Nome_Officina VARCHAR(50),
    Numero_Intervento VARCHAR(10),
    Stato_Precedente VARCHAR(20),
    Stato_Nuovo VARCHAR(20),
    Data_Ora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FUNZIONE: registra la transizione di stato
CREATE OR REPLACE FUNCTION log_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Stato IS DISTINCT FROM OLD.Stato THEN
        INSERT INTO Intervento_Stato_Log (
            Nome_Officina, Numero_Intervento, Stato_Precedente, Stato_Nuovo
        )
        VALUES (
            NEW.Nome_Officina, NEW.Numero_Intervento, OLD.Stato, NEW.Stato
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: verifica transizioni valide
CREATE OR REPLACE FUNCTION verifica_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.Stato = 'inizio' AND NEW.Stato NOT IN ('in corso') THEN
        RAISE EXCEPTION 'Da <inizio> si può passare solo a <in corso>.';
    ELSIF OLD.Stato = 'in corso' AND NEW.Stato NOT IN ('sospeso', 'concluso', 'annullato') THEN
        RAISE EXCEPTION 'Da in corso si può passare solo a sospeso, concluso o annullato.';
    ELSIF OLD.Stato = 'sospeso' AND NEW.Stato NOT IN ('in corso') THEN
        RAISE EXCEPTION 'Da sospeso si può passare solo a in corso.';
    ELSIF OLD.Stato IN ('concluso', 'annullato') AND NEW.Stato != OLD.Stato THEN
        RAISE EXCEPTION 'Intervento già chiuso, non modificabile.';
    END IF;
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

CREATE TRIGGER trg_verifica_intervento_unico_auto
BEFORE INSERT OR UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_intervento_unico_auto();

CREATE TRIGGER trg_verifica_transizione_stato
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_transizione_stato();

CREATE TRIGGER trg_log_transizione_stato
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION log_transizione_stato();


---

-- ## 🔹 5. FATTURA


-- FUNZIONE: stato default 'Non Pagata'
CREATE OR REPLACE FUNCTION set_stato_fattura_default()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Stato IS NULL THEN
        NEW.Stato := 'Non Pagata';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: verifica coerenza cliente ↔ auto
CREATE OR REPLACE FUNCTION verifica_fattura_cliente()
RETURNS TRIGGER AS $$
DECLARE
    cf Codice_Fisc;
BEGIN
    SELECT a.Codice_Fiscale INTO cf
    FROM Automobile a
    JOIN Intervento i ON a.Targa = i.Targa
    WHERE i.Nome_Officina = NEW.Nome_Officina
    AND i.Numero_Intervento = NEW.Numero_Intervento;

    IF cf != NEW.Codice_Fiscale THEN
        RAISE EXCEPTION 'Cliente non coerente con proprietario dell automobile.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNZIONE: genera fattura automatica a chiusura
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
        Data_Emissione, Importo, Nome_Officina,
        Numero_Intervento, Codice_Fiscale, Stato
    ) VALUES (
        CURRENT_DATE, importo, NEW.Nome_Officina,
        NEW.Numero_Intervento, cf, 'Non Pagata'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER trg_stato_fattura
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
WHEN (NEW.Stato = "concluso")
EXECUTE FUNCTION genera_fattura();




---

-- ## 🔨 MODIFICA TABELLA INTERVENTO (se non ancora fatto)


ALTER TABLE Intervento ADD COLUMN Tentativi INT DEFAULT 0;


---

-- ## ✅ 1. Funzione `verifica_pezzi_disponibili(nome_officina, numero_intervento)`


CREATE OR REPLACE FUNCTION verifica_pezzi_disponibili(
    nome_officina VARCHAR, numero_intervento VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    magazzino_id INT;
    pezzo RECORD;
    quantita_magazzino INT;
BEGIN
    SELECT ID_MG INTO magazzino_id
    FROM Magazzino
    WHERE Nome_Officina = nome_officina;

    FOR pezzo IN
        SELECT Codice_Pezzo, Quantita
        FROM Utilizza
        WHERE Nome_Officina = nome_officina
          AND Numero_Intervento = numero_intervento
    LOOP
        SELECT Quantita INTO quantita_magazzino
        FROM Stoccato
        WHERE ID_MG = magazzino_id
          AND Nome_Officina = nome_officina
          AND Codice_Pezzo = pezzo.Codice_Pezzo;

        IF quantita_magazzino IS NULL OR quantita_magazzino < pezzo.Quantita THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


---

-- ## ✅ 2. Funzione `gestisci_tentativi_e_sospensione`


CREATE OR REPLACE FUNCTION gestisci_tentativi_e_sospensione()
RETURNS TRIGGER AS $$
DECLARE
    tentativi_correnti INT;
BEGIN
    -- Solo se si tenta di passare a 'in corso'
    IF NEW.Stato = 'in corso' THEN
        IF NOT verifica_pezzi_disponibili(NEW.Nome_Officina, NEW.Numero_Intervento) THEN
            SELECT Tentativi INTO tentativi_correnti
            FROM Intervento
            WHERE Nome_Officina = NEW.Nome_Officina
              AND Numero_Intervento = NEW.Numero_Intervento;

            IF tentativi_correnti + 1 >= 3 THEN
                NEW.Stato := 'annullato';
            ELSE
                NEW.Stato := 'sospeso';
            END IF;

            -- Aggiorna il contatore tentativi
            UPDATE Intervento
            SET Tentativi = Tentativi + 1
            WHERE Nome_Officina = NEW.Nome_Officina
              AND Numero_Intervento = NEW.Numero_Intervento;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ## ✅ 3. Funzione `verifica_transizione_stato()`


CREATE OR REPLACE FUNCTION verifica_transizione_stato()
RETURNS TRIGGER AS $$
DECLARE
    tentativi_correnti INT;
BEGIN
    -- FINAL STATES
    IF OLD.Stato IN ('annullato', 'concluso') AND NEW.Stato != OLD.Stato THEN
        RAISE EXCEPTION 'Intervento già chiuso (%): non modificabile.', OLD.Stato;
    END IF;

    -- inizio → in corso (permesso)
    IF OLD.Stato = 'inizio' AND NEW.Stato != 'in corso' THEN
        RAISE EXCEPTION 'Da inizio si può passare solo a in corso.';
    END IF;

    -- in corso → concluso/sospeso/annullato
    IF OLD.Stato = 'in corso' AND NEW.Stato NOT IN ('concluso', 'sospeso', 'annullato') THEN
        RAISE EXCEPTION 'Da in corso si può solo passare a concluso, sospeso o annullato.';
    END IF;

    -- sospeso → in corso/concluso/annullato
    IF OLD.Stato = 'sospeso' THEN
        -- verifica se pezzi sono disponibili
        IF NEW.Stato = 'concluso' AND NOT verifica_pezzi_disponibili(NEW.Nome_Officina, NEW.Numero_Intervento) THEN
            RAISE EXCEPTION 'Non puoi concludere: pezzi ancora non disponibili.';
        END IF;

        IF NEW.Stato = 'annullato' THEN
            SELECT Tentativi INTO tentativi_correnti
            FROM Intervento
            WHERE Nome_Officina = NEW.Nome_Officina
              AND Numero_Intervento = NEW.Numero_Intervento;

            IF tentativi_correnti < 3 THEN
                RAISE EXCEPTION 'Non puoi annullare: tentativi non sufficienti (minimo 3 richiesti).';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ## ✅ 4. Trigger associati


-- GESTIONE LOG STATO
CREATE TRIGGER trg_log_stato
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
WHEN (NEW.Stato IS DISTINCT FROM OLD.Stato)
EXECUTE FUNCTION log_transizione_stato();

-- GESTIONE TRANSIZIONE STATI
CREATE TRIGGER trg_verifica_transizione
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_transizione_stato();

-- GESTIONE TENTATIVI E SOSPENSIONE AUTOMATICA
CREATE TRIGGER trg_gestisci_tentativi
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION gestisci_tentativi_e_sospensione();


---

-- ## ✅ 5. Tabella Log


CREATE TABLE IF NOT EXISTS Intervento_Stato_Log (
    Nome_Officina VARCHAR(50),
    Numero_Intervento VARCHAR(10),
    Stato_Precedente VARCHAR(20),
    Stato_Nuovo VARCHAR(20),
    Data_Ora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


---

-- # ✅ `UTILIZZA`

-- ### 🔧 Funzione: `verifica_disponibilita_pezzi()`


-- Verifica se i pezzi richiesti sono sufficienti nel magazzino
CREATE OR REPLACE FUNCTION verifica_disponibilita_pezzi()
RETURNS TRIGGER AS $$
DECLARE
    magazzino_id INT;
    disponibilita INT;
BEGIN
    SELECT ID_MG INTO magazzino_id
    FROM Magazzino
    WHERE Nome_Officina = NEW.Nome_Officina;

    SELECT Quantita INTO disponibilita
    FROM Stoccato
    WHERE ID_MG = magazzino_id
      AND Nome_Officina = NEW.Nome_Officina
      AND Codice_Pezzo = NEW.Codice_Pezzo;

    IF disponibilita IS NULL OR disponibilita < NEW.Quantita THEN
        RAISE EXCEPTION 'Pezzo % non disponibile in quantità sufficiente nel magazzino dell officina %', NEW.Codice_Pezzo, NEW.Nome_Officina;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ### 🔧 Funzione: `aggiorna_quantita_stoccata()`


-- Scala la quantità usata nel magazzino dopo l’uso
CREATE OR REPLACE FUNCTION aggiorna_quantita_stoccata()
RETURNS TRIGGER AS $$
DECLARE
    magazzino_id INT;
BEGIN
    SELECT ID_MG INTO magazzino_id
    FROM Magazzino
    WHERE Nome_Officina = NEW.Nome_Officina;

    UPDATE Stoccato
    SET Quantita = Quantita - NEW.Quantita
    WHERE ID_MG = magazzino_id
      AND Nome_Officina = NEW.Nome_Officina
      AND Codice_Pezzo = NEW.Codice_Pezzo;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ### ⚠️ Trigger su `Utilizza`


-- Verifica pezzi prima di utilizzarli
CREATE TRIGGER trg_verifica_pezzi_utilizza
BEFORE INSERT OR UPDATE ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION verifica_disponibilita_pezzi();

-- Aggiorna magazzino dopo utilizzo
CREATE TRIGGER trg_aggiorna_magazzino_dopo_utilizza
AFTER INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION aggiorna_quantita_stoccata();


---

-- # ✅ `FORNISCE`

-- ### 🔧 Funzione: `verifica_capacita_massima()`


-- Verifica che la fornitura non superi la capacità del magazzino
CREATE OR REPLACE FUNCTION verifica_capacita_massima()
RETURNS TRIGGER AS $$
DECLARE
    cap INT;
    totale INT;
BEGIN
    SELECT Capacita INTO cap
    FROM Magazzino
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;

    SELECT COALESCE(SUM(Quantita), 0) INTO totale
    FROM Stoccato
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;

    IF totale + NEW.Quantita > cap THEN
        RAISE EXCEPTION 'Fornitura (% pezzi) supera capacità disponibile del magazzino (% su %).', NEW.Quantita, totale, cap;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ### 🔧 Funzione: `aggiorna_stoccato_dopo_fornitura()`


-- Inserisce o aggiorna lo stock nel magazzino dopo la fornitura
CREATE OR REPLACE FUNCTION aggiorna_stoccato_dopo_fornitura()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Stoccato (ID_MG, Nome_Officina, Codice_Pezzo, Quantita)
    VALUES (NEW.ID_MG, NEW.Nome_Officina, NEW.Codice_Pezzo, NEW.Quantita)
    ON CONFLICT (ID_MG, Nome_Officina, Codice_Pezzo)
    DO UPDATE SET Quantita = Stoccato.Quantita + EXCLUDED.Quantita;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ### ⚠️ Trigger su `Fornisce`


-- Verifica che il magazzino abbia spazio
CREATE TRIGGER trg_check_capacita_magazzino
BEFORE INSERT OR UPDATE ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION verifica_capacita_massima();

-- Aggiorna Stoccato dopo fornitura
CREATE TRIGGER trg_aggiorna_stoccato_dopo_fornitura
AFTER INSERT ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION aggiorna_stoccato_dopo_fornitura();


---

--# ✅ `STOCCATO`

-- ### 🔧 Funzione: `verifica_stoccato_consistenza()`


-- Controlla se il pezzo esiste e se il magazzino è valido
CREATE OR REPLACE FUNCTION verifica_stoccato_consistenza()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Pezzo_Ricambio WHERE Codice_Pezzo = NEW.Codice_Pezzo
    ) THEN
        RAISE EXCEPTION 'Pezzo ricambio % non esistente', NEW.Codice_Pezzo;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM Magazzino
        WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina
    ) THEN
        RAISE EXCEPTION 'Magazzino ID % dell officina % non valido.', NEW.ID_MG, NEW.Nome_Officina;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---

-- ### ⚠️ Trigger su `Stoccato`


CREATE TRIGGER trg_check_consistenza_stoccato
BEFORE INSERT OR UPDATE ON Stoccato
FOR EACH ROW
EXECUTE FUNCTION verifica_stoccato_consistenza();




