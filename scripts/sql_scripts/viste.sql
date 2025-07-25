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
