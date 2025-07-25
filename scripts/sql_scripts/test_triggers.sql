
INSERT INTO Cliente VALUE ('RSSMRA80A012Z107', 'Mario', 'Rossi', 'Via Garibldi', 'Udine', '33100', '0432123456');
---ERRORE:  un valore chiave duplicato viola il vincolo univoco "cliente_pkey"
--DETAIL:  La chiave (codice_fiscale)=(RSSMRA80A012Z107) esiste già.   
--cliente unici

INSERT INTO Intervento (Nome_Officina, Numero_Intervento, Targa, Data_Inizio, Stato, Tipologia, Costo_Orario, Ore_Manodopera, Descrizione)
VALUES ('Officina Udine', 'INT010', 'AB123CD', CURRENT_DATE, 'In Corso', 'Controllo', 45, 2.5, 'Controllo generale');

--ERRORE:  la INSERT o l'UPDATE sulla tabella "intervento" viola il vincolo di chiave esterna "intervento_targa_fkey"
---DETAIL:  La chiave (targa)=(AB123CD) non è presente nella tabella "automobile".  
---  non possiamo mettere un intervento a cui non c'è automobile;

DELETE FROM Cliente WHERE Codice_Fiscale = 'RSSMRA80A012Z107';
---ERRORE:  Impossibile eliminare cliente: possiede ancora delle auto. CONTEXT:  funzione PL/pgSQL verifica_automobili_cliente_delete() riga 4 a RAISE
-- dovrebbe fallire se il cliente ha ancora auto collegate  
--- non i puo eliminare cliente con auto esistente

DELETE FROM Intervento WHERE Numero_Intervento = 'EF300CD';
-- dovrebbe essere bloccato da trigger annulla prima di eliminare


