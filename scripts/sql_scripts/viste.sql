---- Vista 1: Auto con Continente ClienteQuesta vista collega ogni automobile al continente del cliente, utile per analisi demografiche.---



CREATE OR REPLACE VIEW V_AutoClienteContinente AS
SELECT
    a.Targa,
    a.Modello_Marca,
    a.Anno,
    a.Chilometraggio,
    c.Codice_Fiscale,
    n.Continente
FROM Automobile a
JOIN Cliente c ON a.Codice_Fiscale = c.Codice_Fiscale
JOIN Nazione n ON SUBSTRING(c.Codice_Fiscale FROM 13 FOR 4) = n.Codice;

---Vista 2: Interventi con Geo e ContinenteQuesta vista fornisce dettagli sugli interventi, inclusi città e continente del cliente.---

CREATE OR REPLACE VIEW V_InterventiDettaglio AS
SELECT
    i.Nome_Officina,
    o.Citta,
    i.Numero_Intervento,
    c.Nome AS Cliente,
    n.Continente,
    i.Stato,
    i.Tipologia,
    i.Data_Inizio,
    i.Data_Fine
FROM Intervento i
JOIN Officina o ON i.Nome_Officina = o.Nome_Officina
JOIN Automobile a ON i.Targa = a.Targa
JOIN Cliente c ON a.Codice_Fiscale = c.Codice_Fiscale
JOIN Nazione n ON SUBSTRING(c.Codice_Fiscale FROM 13 FOR 4) = n.Codice;


---Vista 3: Distribuzione Marche Auto per ContinenteQuesta vista mostra la distribuzione delle marche di auto per continente.---

CREATE OR REPLACE VIEW V_MarcheAutoCont AS
SELECT
    n.Continente,
    a.Modello_Marca,
    COUNT(*) AS Num_Auto
FROM Automobile a
JOIN Cliente c ON a.Codice_Fiscale = c.Codice_Fiscale
JOIN Nazione n ON SUBSTRING(c.Codice_Fiscale FROM 13 FOR 4) = n.Codice
GROUP BY n.Continente, a.Modello_Marca;


---Vista 4: Interventi per Officina e StatoQuesta vista riassume il numero di interventi per stato e officina.---

CREATE OR REPLACE VIEW V_StatoInterventiPerOfficina AS
SELECT
    i.Nome_Officina,
    o.Citta,
    i.Stato,
    COUNT(*) AS Num_Interventi
FROM Intervento i
JOIN Officina o ON i.Nome_Officina = o.Nome_Officina
GROUP BY i.Nome_Officina, o.Citta, i.Stato;


---Vista 5: Utilizzo Pezzi Ricambio per OfficinaQuesta vista mostra la quantità totale di pezzi usati per officina.---

CREATE OR REPLACE VIEW V_UtilizzoPezziOfficina AS
SELECT
    u.Nome_Officina,
    u.Codice_Pezzo,
    SUM(u.Quantita) AS Qta_Usata
FROM Utilizza u
GROUP BY u.Nome_Officina, u.Codice_Pezzo;


---Nuova Vista 6: Richieste di Fornitura per Officina Questa nuova vista è specifica per analizzare le Richieste_Fornitura, mostrando i dettagli delle richieste di pezzi per officina, incluso il fornitore e lo stato delle scorte.---

CREATE OR REPLACE VIEW V_RichiesteFornituraDettaglio AS
SELECT
    rf.ID_Richiesta,
    rf.Nome_Officina,
    o.Citta,
    rf.Codice_Pezzo,
    p.Nome AS Nome_Pezzo,
    p.Categoria,
    rf.Quantita AS Quantita_Richiesta,
    rf.Data_Richiesta,
    f.Nome AS Nome_Fornitore,
    COALESCE(s.Quantita, 0) AS Quantita_Stoccata
FROM Richiesta_Fornitura rf
JOIN Officina o ON rf.Nome_Officina = o.Nome_Officina
JOIN Pezzo_Ricambio p ON rf.Codice_Pezzo = p.Codice_Pezzo
LEFT JOIN Stoccato s ON rf.Nome_Officina = s.Nome_Officina AND rf.Codice_Pezzo = s.Codice_Pezzo
LEFT JOIN Fornisce fn ON 
    rf.Codice_Pezzo = fn.Codice_Pezzo 
    AND rf.Nome_Officina = fn.Nome_Officina 
    AND rf.ID_MG = fn.ID_MG
LEFT JOIN Fornitore f ON fn.PIVA = f.PIVA;

--🧾 V1. V_Clienti_Auto_Nazione
--Clienti, auto associate e nazione dedotta dal codice fiscale

CREATE OR REPLACE VIEW V_Clienti_Auto_Nazione AS
SELECT 
  c.Codice_Fiscale,
  c.Nome,
  c.Cognome,
  a.Targa,
  a.Modello_Marca,
  n.Nome AS Nazione,
  n.Continente
FROM Cliente c
JOIN Automobile a ON c.Codice_Fiscale = a.Codice_Fiscale
JOIN Nazione n ON SUBSTRING(c.Codice_Fiscale FROM 13 FOR 4) = n.Codice;


--🛠️ V2. V_Interventi_Stato_Fattura
-- Dettaglio interventi + fatture se già concluse
CREATE OR REPLACE VIEW V_Interventi_Stato_Fattura AS
SELECT
  i.Nome_Officina,
  i.Numero_Intervento,
  i.Targa,
  i.Stato  AS Stato_Intervento,
  f.Numero_Fattura,
  f.Importo,
  f.Stato AS Stato
FROM Intervento i
LEFT JOIN Fattura f ON i.Nome_Officina = f.Nome_Officina
                   AND i.Numero_Intervento = f.Numero_Intervento;


--🏪 V3. V_Pezzi_Utilizzati_Totali
--Pezzi di ricambio usati totali per officina

CREATE OR REPLACE VIEW V_Pezzi_Utilizzati_Totali AS
SELECT 
  u.Nome_Officina,
  u.Codice_Pezzo,
  p.Nome AS Nome_Pezzo,
  SUM(u.Quantita) AS Totale_Utilizzati
FROM Utilizza u
JOIN Pezzo_Ricambio p ON u.Codice_Pezzo = p.Codice_Pezzo
GROUP BY u.Nome_Officina, u.Codice_Pezzo, p.Nome;

--🧯 V4. V_Interventi_Sospesi_Richiesta
--Interventi sospesi con dettaglio della richiesta di pezzi

CREATE OR REPLACE VIEW V_Interventi_Sospesi_Richiesta AS
SELECT 
  i.Nome_Officina,
  i.Numero_Intervento,
  r.Codice_Pezzo,
  r.Quantita,
  r.Stato,
  r.Data_Richiesta
FROM Intervento i
JOIN Richiesta_Fornitura r ON i.Numero_Intervento = r.Numero_Intervento
WHERE i.Stato = 'Sospeso';


--🛒 V5. V_Top_Fornitori
-- Fornitori che hanno fornito più pezzi in totale
CREATE OR REPLACE VIEW V_Top_Fornitori AS
SELECT 
  f.PIVA,
  f.Nome,
  SUM(fr.Quantita) AS Totale_Pezzi_Consegnati 
FROM Fornitore f
JOIN Fornisce fr ON f.PIVA = fr.PIVA
GROUP BY f.PIVA, f.Nome
ORDER BY Totale_Pezzi_Consegnati DESC;


--💰 V6. V_Officine_Fatturato
-- Fatturato per officina (solo fatture pagate)

CREATE OR REPLACE VIEW V_Officine_Fatturato AS
SELECT 
  i.Nome_Officina,
  SUM(f.Importo) AS Fatturato_Totale
FROM Fattura f
JOIN Intervento i ON f.Numero_Intervento = i.Numero_Intervento
WHERE f.Stato = ' Non Pagata'
GROUP BY i.Nome_Officina
ORDER BY Fatturato_Totale DESC;



--- quanti pezzi ci sono in ogni officina
CREATE OR REPLACE VIEW V_UtilizzoPezziPerOfficinaCrosstab AS
SELECT *
FROM crosstab(
    $$
    SELECT u.Codice_Pezzo, u.Nome_Officina, COALESCE(SUM(u.Quantita), 0) AS Quantita_Totale
    FROM Utilizza u
    GROUP BY u.Codice_Pezzo, u.Nome_Officina
    ORDER BY u.Codice_Pezzo, u.Nome_Officina
    $$,
    $$
    SELECT DISTINCT Nome_Officina FROM Officina ORDER BY Nome_Officina
    $$
) AS pivot (
    Codice_Pezzo VARCHAR(10),
    "Officina Adegliaco" INTEGER,
    "Officina Aquileia" INTEGER,
    "Officina Azzano Decimo" INTEGER,
    "Officina Buttrio" INTEGER,
    "Officina Cervignano del Friuli" INTEGER,
    "Officina Cividale del Friuli" INTEGER,
    "Officina Codroipo" INTEGER,
    "Officina Fagagna" INTEGER,
    "Officina Gemona" INTEGER,
    "Officina Gorizia" INTEGER,
    "Officina Latisana" INTEGER,
    "Officina Lignano Sabbiadoro" INTEGER,
    "Officina Maniago" INTEGER,
    "Officina Monfalcone" INTEGER,
    "Officina Palmanova" INTEGER,
    "Officina Pasian di Prato" INTEGER,
    "Officina Pordenone" INTEGER,
    "Officina Sacile" INTEGER,
    "Officina San Daniele del Friuli" INTEGER,
    "Officina San Giorgio di Nogaro" INTEGER,
    "Officina San Vito al Tagliamento" INTEGER,
    "Officina Spilimbergo" INTEGER,
    "Officina Tarvisio" INTEGER,
    "Officina Tavagnacco" INTEGER,
    "Officina Tolmezzo" INTEGER,
    "Officina Tricesimo" INTEGER,
    "Officina Trieste" INTEGER,
    "Officina Udine" INTEGER
);
