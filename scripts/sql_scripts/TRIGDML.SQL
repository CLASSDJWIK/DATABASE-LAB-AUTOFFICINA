

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
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cliente_delete
BEFORE DELETE ON Cliente
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_delete();

-- =================== AUTOMOBILE ===================
CREATE OR REPLACE FUNCTION verifica_automobili_cliente_auto()
RETURNS TRIGGER AS $$
DECLARE num_auto INT; num_non_conclusi INT;
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
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_delete
BEFORE DELETE ON Automobile
FOR EACH ROW
EXECUTE FUNCTION verifica_automobili_cliente_auto();

-- =================== OFFICINA ===================
CREATE OR REPLACE FUNCTION aggiorna_numero_interventi_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Officina SET Numero_Interventi = Numero_Interventi + 1
    WHERE Nome_Officina = NEW.Nome_Officina;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

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
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_intervento_delete
AFTER DELETE ON Intervento
FOR EACH ROW
EXECUTE FUNCTION aggiorna_numero_interventi_delete();

-- =================== INTERVENTO: vincoli sui flussi ===================
CREATE OR REPLACE FUNCTION check_max10_interventi_giorno()
RETURNS TRIGGER AS $$
DECLARE cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM Intervento
    WHERE Nome_Officina = NEW.Nome_Officina
      AND Data_Inizio = NEW.Data_Inizio
      AND Stato IN ('In Corso', 'Sospeso');
    IF cnt >= 10 THEN
        RAISE EXCEPTION 'Limite giornaliero raggiunto per questa officina.';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_max10_interventi_giorno
BEFORE INSERT OR UPDATE ON Intervento
FOR EACH ROW
WHEN (NEW.Stato IN ('In Corso', 'Sospeso'))
EXECUTE FUNCTION check_max10_interventi_giorno();

CREATE OR REPLACE FUNCTION verifica_transizione_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.Stato = 'inizio' AND NEW.Stato <> 'in corso' THEN
        RAISE EXCEPTION 'Da inizio solo a in corso.';
    ELSIF OLD.Stato = 'in corso' AND NEW.Stato NOT IN ('sospeso','concluso','annullato') THEN
        RAISE EXCEPTION 'Da in corso solo verso sospeso/concluso/annullato.';
    ELSIF OLD.Stato = 'sospeso' AND NEW.Stato <> 'in corso' THEN
        RAISE EXCEPTION 'Da sospeso solo a in corso.';
    ELSIF OLD.Stato IN ('concluso','annullato') AND NEW.Stato <> OLD.Stato THEN
        RAISE EXCEPTION 'Non puoi modificare uno stato finale.';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifica_transizione_stato
BEFORE UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION verifica_transizione_stato();

-- =================== UTILIZZA & SCORTE ===================
CREATE OR REPLACE FUNCTION trigger_richiesta_pezzo_mancante()
RETURNS TRIGGER AS $$
DECLARE q int;
BEGIN
    SELECT Quantita INTO q FROM Stoccato
    WHERE Nome_Officina = NEW.Nome_Officina AND Codice_Pezzo = NEW.Codice_Pezzo;
    IF q IS NULL OR q < NEW.Quantita THEN
        UPDATE Intervento SET Stato = 'sospeso'
        WHERE Nome_Officina = NEW.Nome_Officina AND Numero_Intervento = NEW.Numero_Intervento;
        INSERT INTO Richiesta_Fornitura
            (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita, Soddisfatta)
        VALUES
            (NEW.Nome_Officina, NEW.Numero_Intervento, NEW.Codice_Pezzo, NEW.Quantita, FALSE);
        RAISE EXCEPTION 'Pezzo mancante — richiesta generata e intervento sospeso!';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_richiesta_pezzo_mancante
BEFORE INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION trigger_richiesta_pezzo_mancante();

CREATE OR REPLACE FUNCTION aggiorna_quantita_stoccata()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Stoccato
    SET Quantita = Quantita - NEW.Quantita
    WHERE Nome_Officina = NEW.Nome_Officina AND Codice_Pezzo = NEW.Codice_Pezzo;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_aggiorna_quantita_stoccata
AFTER INSERT ON Utilizza
FOR EACH ROW
EXECUTE FUNCTION aggiorna_quantita_stoccata();

-- =================== GESTIONE FATTURE ===================
CREATE OR REPLACE FUNCTION calcola_importo_fattura(
    p_numero_intervento VARCHAR, p_nome_officina VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    importo NUMERIC;
    costo_pezzi NUMERIC;
BEGIN
    SELECT COALESCE(SUM(p.Costo_Unitario * u.Quantita), 0)
    INTO costo_pezzi
    FROM Utilizza u
    JOIN Pezzo_Ricambio p ON u.Codice_Pezzo = p.Codice_Pezzo
    WHERE u.Numero_Intervento = p_numero_intervento
      AND u.Nome_Officina = p_nome_officina;
    SELECT Ore_Manodopera * Costo_Orario + costo_pezzi INTO importo
    FROM Intervento
    WHERE Numero_Intervento = p_numero_intervento
      AND Nome_Officina = p_nome_officina;
    RETURN importo;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION genera_fattura()
RETURNS TRIGGER AS $$
DECLARE
    importo NUMERIC;
    cf VARCHAR(16);
    costo_pezzi NUMERIC;
BEGIN
    IF NEW.Stato = 'Concluso' AND OLD.Stato != 'Concluso' THEN
        -- Calcola pezzi di ricambio
        SELECT COALESCE(SUM(pr.Costo_Unitario * u.quantita), 0)
        INTO costo_pezzi
        FROM Utilizza u
        JOIN Pezzo_Ricambio pr ON u.Codice_Pezzo = pr.Codice_Pezzo
        WHERE u.Nome_Officina = NEW.Nome_Officina
          AND u.Numero_Intervento = NEW.Numero_Intervento;

        -- Calcola totale (manodopera + ricambi)
        importo := (NEW.Ore_Manodopera * NEW.Costo_Orario) + costo_pezzi;

        -- Recupera codice fiscale cliente
        SELECT a.Codice_Fiscale INTO cf
        FROM Automobile a
        WHERE a.Targa = NEW.Targa;

        -- Inserisce la fattura
        INSERT INTO Fattura (Data_Emissione, Nome_Officina, Numero_Intervento, Importo_Totale, Codice_Fiscale, Stato)
        VALUES (CURRENT_DATE, NEW.Nome_Officina, NEW.Numero_Intervento, importo, cf, 'Non Pagata');
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;


CREATE TRIGGER trg_genera_fattura
AFTER UPDATE OF Stato ON Intervento
FOR EACH ROW
EXECUTE FUNCTION genera_fattura();

CREATE OR REPLACE FUNCTION verifica_fattura_cliente()
RETURNS TRIGGER AS $$
DECLARE cf_auto VARCHAR(16);
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
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifica_fattura_cliente
BEFORE INSERT OR UPDATE ON Fattura
FOR EACH ROW
EXECUTE FUNCTION verifica_fattura_cliente();

-- =================== GESTIONE FORNISCE / MAGAZZINO ===================
CREATE OR REPLACE FUNCTION verifica_capacita_massima()
RETURNS TRIGGER AS $$
DECLARE capacita_attuale INT; capacita_max INT;
BEGIN
    SELECT SUM(Quantita) INTO capacita_attuale FROM Stoccato
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;
    SELECT Capacita INTO capacita_max FROM Magazzino
    WHERE ID_MG = NEW.ID_MG AND Nome_Officina = NEW.Nome_Officina;
    IF capacita_attuale + NEW.Quantita > capacita_max THEN
        RAISE EXCEPTION 'Superata capacità magazzino';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

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
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_aggiorna_stoccato_dopo_fornisce
AFTER INSERT ON Fornisce
FOR EACH ROW
EXECUTE FUNCTION aggiorna_stoccato_dopo_fornisce();

-- =================== FUNZIONE REINTEGRO INTERVENTI SOSPESI ===================
CREATE OR REPLACE FUNCTION riattiva_interventi_pezzi_soddisfatti()
RETURNS VOID AS $$
DECLARE rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM Richiesta_Fornitura WHERE Soddisfatta = FALSE LOOP
        PERFORM 1 FROM Stoccato
        WHERE Nome_Officina = rec.Nome_Officina
        AND Codice_Pezzo = rec.Codice_Pezzo
        AND Quantita >= rec.Quantita;
        IF FOUND THEN
            UPDATE Intervento
            SET Stato = 'in corso'
            WHERE Nome_Officina = rec.Nome_Officina
              AND Numero_Intervento = rec.Numero_Intervento
              AND Stato = 'sospeso';
            UPDATE Richiesta_Fornitura SET Soddisfatta = TRUE WHERE ID = rec.ID;
        END IF;
    END LOOP;
END; $$ LANGUAGE plpgsql;

-- =================== BATCH: PAGA FATTURE DOPO 1 SETTIMANA ===================
CREATE OR REPLACE FUNCTION batch_paga_fatture()
RETURNS VOID AS $$
DECLARE fattura RECORD;
BEGIN
    FOR fattura IN
        SELECT Numero_Fattura
        FROM Fattura
        WHERE Stato = 'Non Pagata'
          AND Data_Emissione < (CURRENT_DATE - INTERVAL '7 days')
          AND random() < 0.5
    LOOP
        UPDATE Fattura
        SET Stato = 'Pagata', Data_Pagamento = CURRENT_DATE
        WHERE Numero_Fattura = fattura.Numero_Fattura;
    END LOOP;
END; $$ LANGUAGE plpgsql;
