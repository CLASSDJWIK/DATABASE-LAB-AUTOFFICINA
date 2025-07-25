---3. Query analitiche significativeLe query fornite nel file DML.sql sono già ben progettate. Le riporto con alcune ottimizzazioni e aggiungo una query specifica per Richieste_Fornitura.
--Query 1: Numero di auto per continente clientesql

SELECT Continente, COUNT(*) AS Numero_Auto
FROM V_AutoClienteContinente
GROUP BY Continente
ORDER BY Numero_Auto DESC;

---Query 2: Numero di interventi per città e continente clientesql

SELECT Citta, Continente, COUNT(*) AS Num_Interventi
FROM V_InterventiDettaglio
GROUP BY Citta, Continente
ORDER BY Citta, Num_Interventi DESC;

---Query 3: Distribuzione delle marche per area geograficasql

SELECT Continente, Modello_Marca, Num_Auto
FROM V_MarcheAutoCont
ORDER BY Continente, Num_Auto DESC;

---Query 4: Interventi per stato e officinasql

SELECT Nome_Officina, Citta, Stato, Num_Interventi
FROM V_StatoInterventiPerOfficina
ORDER BY Citta, Stato;

---Query 5: Utilizzo pezzi di ricambio per officinasql

SELECT Nome_Officina, Codice_Pezzo, Qta_Usata
FROM V_UtilizzoPezziOfficina
ORDER BY Nome_Officina, Codice_Pezzo;

---Query 6: Interventi sospesi, conclusi e annullati per continentesql

SELECT Continente, Stato, COUNT(*) AS Num_Interventi
FROM V_InterventiDettaglio
GROUP BY Continente, Stato
ORDER BY Continente, Stato;

---Query 7: Top 5 clienti con più interventisql

SELECT Cliente, COUNT(*) AS Num_Interventi
FROM V_InterventiDettaglio
GROUP BY Cliente
ORDER BY Num_Interventi DESC
LIMIT 5;

---Nuova Query 8: Pezzi più richiesti nelle richieste di forniturasql

SELECT 
    rf.Codice_Pezzo,
    p.Nome AS Nome_Pezzo,
    p.Categoria,
    SUM(rf.Quantita) AS Quantita_Totale_Richiesta,
    COUNT(DISTINCT rf.ID_Richiesta) AS Numero_Richieste,
    COUNT(DISTINCT rf.Nome_Officina) AS Numero_Officine
FROM Richieste_Fornitura rf
JOIN Pezzo p ON rf.Codice_Pezzo = p.Codice_Pezzo
GROUP BY rf.Codice_Pezzo, p.Nome, p.Categoria
ORDER BY Quantita_Totale_Richiesta DESC
LIMIT 10;

---Utilità:Identifica i pezzi di ricambio più richiesti tramite Richieste_Fornitura.
--Mostra il numero di richieste e officine coinvolte, utile per ottimizzare gli ordini ai fornitori.

---Nuova Query 9: Officine con scorte basse e richieste attivesql

SELECT 
    v.Nome_Officina,
    v.Citta,
    v.Codice_Pezzo,
    v.Nome_Pezzo,
    v.Quantita_Stoccata,
    v.Quantita_Richiesta,
    v.Nome_Fornitore
FROM V_RichiesteFornituraDettaglio v
WHERE v.Quantita_Stoccata < 10
ORDER BY v.Quantita_Stoccata ASC, v.Quantita_Richiesta DESC;

--Utilità:Identifica le officine con scorte basse (meno di 10 unità) che hanno richieste di fornitura attive.
--Aiuta a prioritizzare gli ordini di rifornimento.


