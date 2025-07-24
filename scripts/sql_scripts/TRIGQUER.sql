-- =============================================================
-- FILE: TRIGDML.sql
-- DESCRIZIONE: Trigger e Funzioni per Database Autofficina
-- STRUTTURATO PER TABELLA secondo modello E-R
-- ===========================================================

-- =================== CLIENTE ===================
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Automobile WHERE Codice_Fiscale = OLD.Codice_Fiscale) THEN
        RAISE EXCEPTION 'Impossibile eliminare cliente: possiede ancora delle auto.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cliente_delete
BEFORE DELETE ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_delete();

-- =================== AUTOMOBILE ===================
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_auto()
RETURNS TRIGGER AS $$
DECLARE
    num_auto INT;
    num_non_conclusi INT;
BEGIN
    SELECT COUNT(*) INTO num_auto FROM Automobile WHERE Codice_Fiscale = OLD.Codice_Fiscale;
    IF num_auto = 1 THEN
        RAISE EXCEPTION 'Non si può eliminare l''ultima auto del cliente.';
    END IF;
    SELECT COUNT(*) INTO num_non_conclusi FROM Intervento WHERE Targa = OLD.Targa AND Stato != 'Concluso';
    IF num_non_conclusi > 0 THEN
        RAISE EXCEPTION 'Non puoi eliminare un''auto con interventi non conclusi.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_delete
BEFORE DELETE ON Automobile
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_auto();

-- Trigger to verify that a car is associated with an existing client
CREATE OR REPLACE FUNCTION verifica_cliente_automobile_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE Codice_Fiscale = NEW.Codice_Fiscale) THEN
        RAISE EXCEPTION 'Impossibile inserire l''automobile perché il cliente associato non esiste.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_insert
BEFORE INSERT ON Automobile
FOR EACH ROW
EXECUTE FUNCTION verifica_cliente_automobile_insert();

-- =================== OFFICINA ===================
CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina SET Numero_Interventi = Numero_Interventi + 1
    WHERE Nome_Officina = NEW.Nome_Officina;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_intervento_insert
AFTER INSERT ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_interventi_insert();

CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina SET Numero_Interventi = Numero_Interventi - 1
    WHERE Nome_Officina = OLD.Nome_Officina;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_intervento_delete
AFTER DELETE ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_interventi_delete();

CREATE OR REPLACE FUNCTION verifica_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.Stato = 'Inizio' AND NEW.Stato <> 'In Corso' THEN
        RAISE EXCEPTION 'Da Inizio solo a In Corso.';
    ELSIF OLD.Stato = 'In Corso' AND NEW.Stato NOT IN ('Sospeso', 'Concluso', 'Annullato') THEN
        RAISE EXCEPTION 'Da In Corso solo verso Sospeso/Concluso/Annullato.';
    ELSIF OLD.Stato = 'Sospeso' AND NEW.Stato <> 'In Corso' THEN
        RAISE EXCEPTION 'Da Sospeso solo a In Corso.';
    ELSIF OLD.Stato IN ('Concluso', 'Annullato') AND NEW.Stato <> OLD.Stato THEN
        RAISE EXCEPTION 'Non puoi modificare uno stato finale.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifica_transizione_stato
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_transizione_stato();

-- =================== UTILIZZA & SCORTE ===================
CREATE OR REPLACE FUNCTION aggiorna_quantita_stoccata()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Stoccato
    SET Quantita = Quantita - NEW.Quantita
    WHERE Nome_Officina = NEW.Nome_Officina AND Codice_Pezzo = NEW.Codice_Pezzo;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_aggiorna_quantita_stoccata
AFTER INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION aggiorna_quantita_stoccata();

-- =================== GESTIONE FATTURE ===================
CREATE OR REPLACE FUNCTION verifica_fattura_cliente()
RETURNS TRIGGER AS $$
DECLARE
    cf_auto VARCHAR(16);
BEGIN
    SELECT a.Codice_Fiscale INTO cf_auto
    FROM Intervento i
    JOIN Automobile a ON i.Targa = a.Targa
    WHERE i.Nome_Officina = NEW.Nome_Officina
      AND i.Numero_Intervento = NEW.Numero_Intervento;
    IF cf_auto IS DISTINCT FROM NEW.Codice_Fiscale THEN
        RAISE EXCEPTION 'La fattura deve essere associata al cliente proprietario dell''auto';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifica_fattura_cliente
BEFORE INSERT OR UPDATE ON Fattura
FOR EACH ROW
EXECUTE FUNCTION verifica_fattura_cliente();

-- =================== GESTIONE FORNISCE / MAGAZZINO ===================
CREATE OR REPLACE FUNCTION verifica_capacita_massima()
RETURNS TRIGGER AS $$
DECLARE
    capacita_attuale INT;
    capacita_max INT;
BEGIN
    SELECT SUM(Quantita) INTO capacita_attuale FROM Stoccato
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;
    SELECT Capacita INTO capacita_max FROM Magazzino
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;
    IF capacita_attuale + NEW.Quantita > capacita_max THEN
        RAISE EXCEPTION 'Superata capacità magazzino';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifica_capacita_massima
BEFORE INSERT OR UPDATE ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION verifica_capacita_massima();

CREATE OR REPLACE FUNCTION aggiorna_stoccato_dopo_fornisce()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Stoccato WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina AND Codice_Pezzo = NEW.Codice_Pezzo
    ) THEN
        UPDATE Stoccato
        SET Quantita = Quantita + NEW.Quantita
        WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina AND Codice_Pezzo = NEW.Codice_Pezzo;
    ELSE
        INSERT INTO Stoccato (ID_MG, Nome_Officina, Codice_Pezzo, Quantita)
        VALUES (NEW.ID_MG, NEW.Nome_Officina, NEW.Codice_Pezzo, NEW.Quantita);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_aggiorna_stoccato_dopo_fornisce
AFTER INSERT ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION aggiorna_stoccato_dopo_fornisce();

-- =================== FUNZIONE REINTEGRO INTERVENTI SOSPESI ===================
CREATE OR REPLACE FUNCTION genera_lista_pezzi_necessari()
RETURNS TABLE (Nome_Officina VARCHAR, Codice_Pezzo VARCHAR, Quantita INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT r.Nome_Officina, r.Codice_Pezzo, SUM(r.Quantita)::INTEGER as Quantita
    FROM Richiesta_Fornitura r
    WHERE r.Stato = 'Non Soddisfatta'
    GROUP BY r.Nome_Officina, r.Codice_Pezzo;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inserisci_pezzi_necessari()
RETURNS VOID AS $$
DECLARE
    pezzo RECORD;
    piva_valida VARCHAR(11);
BEGIN
    FOR pezzo IN SELECT * FROM genera_lista_pezzi_necessari() LOOP
        -- Seleziona una PIVA valida dalla tabella Fornitore per ogni pezzo
        SELECT PIVA INTO piva_valida
        FROM Fornitore
        ORDER BY RANDOM()
        LIMIT 1;

        -- Inserisci i pezzi nel magazzino con una quantità extra di 15
        INSERT INTO Fornisce (PIVA, Codice_Pezzo, Quantita, Data_Consegna, ID_MG, Nome_Officina)
        VALUES (piva_valida, pezzo.Codice_Pezzo, pezzo.Quantita + 15, CURRENT_DATE,
                (SELECT ID_MG FROM Magazzino WHERE Nome_Officina = pezzo.Nome_Officina),
                pezzo.Nome_Officina);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION riattiva_interventi_pezzi_soddisfatti()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM Richiesta_Fornitura WHERE Stato = 'Non Soddisfatta' LOOP
        -- Verifica se i pezzi sono disponibili nel magazzino
        PERFORM 1 FROM Stoccato
        WHERE Nome_Officina = rec.Nome_Officina
        AND Codice_Pezzo = rec.Codice_Pezzo
        AND Quantita >= rec.Quantita;

        IF FOUND THEN
            -- Riattiva l'intervento
            UPDATE Intervento
            SET Stato = 'In Corso'
            WHERE Nome_Officina = rec.Nome_Officina
            AND Numero_Intervento = rec.Numero_Intervento
            AND Stato = 'Sospeso';

            -- Marca la richiesta come soddisfatta
            UPDATE Richiesta_Fornitura
            SET Stato = 'Soddisfatta'
            WHERE ID_Richiesta = rec.ID_Richiesta;

            -- Inserisci l'utilizzo del pezzo di ricambio
            INSERT INTO Utilizza (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita)
            VALUES (rec.Nome_Officina, rec.Numero_Intervento, rec.Codice_Pezzo, rec.Quantita);

            -- Aggiorna lo stato dell'intervento a "Concluso" se tutti i pezzi necessari sono stati utilizzati
            UPDATE Intervento
            SET Stato = 'Concluso',
                Data_Fine = CURRENT_DATE
            WHERE Nome_Officina = rec.Nome_Officina
            AND Numero_Intervento = rec.Numero_Intervento;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gestisci_fine_giornata()
RETURNS VOID AS $$
BEGIN
    -- Inserisci i pezzi necessari nel magazzino
    PERFORM inserisci_pezzi_necessari();

    -- Riattiva gli interventi sospesi
    PERFORM riattiva_interventi_pezzi_soddisfatti();
END;
$$ LANGUAGE plpgsql;

-- Funzione per calcolare l'importo della fattura
CREATE OR REPLACE FUNCTION calcola_importo_fattura(p_numero_intervento VARCHAR, p_nome_officina VARCHAR)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    importo DECIMAL(10, 2);
    costo_orario DECIMAL(10, 2);
    ore_manodopera DECIMAL(10, 2);
    costo_pezzi DECIMAL(10, 2);
BEGIN
    SELECT i.Costo_Orario INTO costo_orario
    FROM Intervento i
    WHERE i.Numero_Intervento = p_numero_intervento AND i.Nome_Officina = p_nome_officina;

    SELECT i.Ore_Manodopera INTO ore_manodopera
    FROM Intervento i
    WHERE i.Numero_Intervento = p_numero_intervento AND i.Nome_Officina = p_nome_officina;

    SELECT COALESCE(SUM(p.Costo_Unitario * u.Quantita), 0) INTO costo_pezzi
    FROM Utilizza u
    JOIN Pezzo_Ricambio p ON u.Codice_Pezzo = p.Codice_Pezzo
    WHERE u.Numero_Intervento = p_numero_intervento AND u.Nome_Officina = p_nome_officina;

    importo := costo_orario * ore_manodopera + costo_pezzi;
    RETURN importo;
END;
$$ LANGUAGE plpgsql;

-- Trigger per gestire il flusso degli interventi
CREATE OR REPLACE FUNCTION gestisci_flusso_intervento()
RETURNS TRIGGER AS $$
DECLARE
    q INT;
BEGIN
    SELECT Quantita INTO q
    FROM Stoccato
    WHERE Nome_Officina = NEW.Nome_Officina
    AND Codice_Pezzo = NEW.Codice_Pezzo;

    IF q IS NOT NULL AND q >= NEW.Quantita THEN
        UPDATE Intervento
        SET Stato = 'Concluso',
            Data_Fine = CURRENT_DATE
        WHERE Nome_Officina = NEW.Nome_Officina
        AND Numero_Intervento = NEW.Numero_Intervento;

        UPDATE Stoccato
        SET Quantita = Quantita - NEW.Quantita
        WHERE Nome_Officina = NEW.Nome_Officina
        AND Codice_Pezzo = NEW.Codice_Pezzo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gestisci_flusso_intervento
AFTER INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION gestisci_flusso_intervento();

-- Trigger per la generazione automatica della fattura
CREATE OR REPLACE FUNCTION genera_fattura()
RETURNS TRIGGER AS $$
DECLARE
    importo DECIMAL(10, 2);
BEGIN
    IF NEW.Stato = 'Concluso' THEN
        importo := calcola_importo_fattura(NEW.Numero_Intervento, NEW.Nome_Officina);
        INSERT INTO Fattura (Data_Emissione, Stato, Importo, Nome_Officina, Numero_Intervento, Codice_Fiscale)
        VALUES (CURRENT_DATE, 'Non Pagata', importo, NEW.Nome_Officina, NEW.Numero_Intervento,
                (SELECT Codice_Fiscale FROM Automobile WHERE Targa = NEW.Targa));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_genera_fattura
AFTER UPDATE ON Intervento
FOR EACH ROW
WHEN (OLD.Stato IS DISTINCT FROM NEW.Stato AND NEW.Stato = 'Concluso')
EXECUTE FUNCTION genera_fattura();

-- Trigger per gestire la richiesta di pezzi mancanti
CREATE OR REPLACE FUNCTION trigger_richiesta_pezzo_mancante()
RETURNS TRIGGER AS $$
DECLARE
    q INT;
    id_mg_value INTEGER;
BEGIN
    SELECT Quantita INTO q
    FROM Stoccato
    WHERE Nome_Officina = NEW.Nome_Officina
    AND Codice_Pezzo = NEW.Codice_Pezzo;

    SELECT ID_MG INTO id_mg_value
    FROM Magazzino
    WHERE Nome_Officina = NEW.Nome_Officina;

    IF q IS NULL OR q < NEW.Quantita THEN
        UPDATE Intervento
        SET Stato = 'Sospeso'
        WHERE Nome_Officina = NEW.Nome_Officina
        AND Numero_Intervento = NEW.Numero_Intervento;

        INSERT INTO Richiesta_Fornitura (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita, ID_MG, Stato, Data_Richiesta)
        VALUES (NEW.Nome_Officina, NEW.Numero_Intervento, NEW.Codice_Pezzo, NEW.Quantita, id_mg_value, 'Non Soddisfatta', CURRENT_TIMESTAMP);

        RAISE WARNING 'Pezzo di ricambio non disponibile in quantità sufficiente. Intervento sospeso e richiesta generata.';
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_richiesta_pezzo_mancante
BEFORE INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION trigger_richiesta_pezzo_mancante();
