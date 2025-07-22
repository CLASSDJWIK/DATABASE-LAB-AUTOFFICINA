
-- =========================
-- DOMINI
-- =========================
CREATE DOMAIN Telefono AS VARCHAR(15) CHECK (VALUE ~ '^[0-9+]{6,15}$');
CREATE DOMAIN AnnoAuto AS INT CHECK (VALUE BETWEEN 1970 AND 2025);
CREATE DOMAIN Costo AS NUMERIC(10, 2) CHECK (VALUE > 0);
CREATE DOMAIN OrePositive AS NUMERIC(5, 2) CHECK (VALUE > 0);
CREATE DOMAIN Targa_Auto AS VARCHAR(7) CHECK (VALUE ~ '^[A-Z]{2}[0-9]{3}[A-Z]{2}$');
CREATE DOMAIN Codice_Fisc AS VARCHAR(16)
   CHECK (VALUE ~ '^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[0-9]Z[0-9]{3}$');
CREATE DOMAIN stato_intervento AS VARCHAR(20)
    CHECK (VALUE IN ('Inizio', 'In Corso', 'Sospeso', 'Concluso'));
CREATE DOMAIN PIVA AS VARCHAR(11) CHECK (VALUE ~ '^[A-Z]{3}[0-9]{5}$');
CREATE DOMAIN CAP AS CHAR(5) CHECK (VALUE ~ '^[0-9]{5}$');
CREATE DOMAIN stato_fattura AS VARCHAR(20)
    CHECK (VALUE IN ('Pagata', 'Non Pagata'));

-- =========================
-- TABELLE DI RIFERIMENTO
-- =========================

CREATE TABLE Nazione (
    Codice VARCHAR(4) PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Continente VARCHAR(20) NOT NULL
);

INSERT INTO Nazione (Codice, Nome, Continente) VALUES
-- Europa
('Z100', 'Albania', 'Europa'),
('Z105', 'Croazia', 'Europa'),
('Z107', 'Italia', 'Europa'),
('Z112', 'Svizzera', 'Europa'),
('Z118', 'Slovenia', 'Europa'),
('Z120', 'Germania', 'Europa'),
('Z121', 'Austria', 'Europa'),
('Z122', 'Francia', 'Europa'),
('Z123', 'Spagna', 'Europa'),
('Z124', 'Portogallo', 'Europa'),
('Z125', 'Regno Unito', 'Europa'),
('Z126', 'Grecia', 'Europa'),
('Z127', 'Belgio', 'Europa'),
('Z128', 'Paesi Bassi', 'Europa'),
('Z129', 'Svezia', 'Europa'),
('Z130', 'Norvegia', 'Europa'),
('Z131', 'Danimarca', 'Europa'),
('Z132', 'Finlandia', 'Europa'),
('Z133', 'Polonia', 'Europa'),
('Z134', 'Romania', 'Europa'),
('Z135', 'Ungheria', 'Europa'),
('Z136', 'Repubblica Ceca', 'Europa'),
('Z137', 'Slovacchia', 'Europa'),
-- Africa
('Z301', 'Ghana', 'Africa'),
('Z302', 'Nigeria', 'Africa'),
('Z303', 'Sudafrica', 'Africa'),
('Z304', 'Egitto', 'Africa'),
('Z305', 'Senegal', 'Africa'),
('Z306', 'Marocco', 'Africa'),
('Z307', 'Algeria', 'Africa'),
('Z308', 'Kenya', 'Africa'),
('Z309', 'Tunisia', 'Africa'),
('Z310', 'Etiopia', 'Africa'),
('Z311', 'Camerun', 'Africa'),
('Z312', 'Costa d Avorio', 'Africa'),
('Z313', 'Mali', 'Africa'),
('Z314', 'Capo Verde', 'Africa'),
('Z315', 'Burkina Faso', 'Africa'),
('Z316', 'Guinea Equatoriale', 'Africa'),
('Z317', 'Repubblica Centrafricana', 'Africa'),
('Z318', 'Gabon', 'Africa'),
-- Asia
('Z201', 'Cina', 'Asia'),
('Z202', 'India', 'Asia'),
('Z203', 'Giappone', 'Asia'),
('Z204', 'Corea del Sud', 'Asia'),
('Z205', 'Pakistan', 'Asia'),
('Z206', 'Filippine', 'Asia'),
('Z207', 'Arabia Saudita', 'Asia'),
('Z208', 'Bangladesh', 'Asia'),
('Z209', 'Emirati Arabi Uniti', 'Asia'),
('Z210', 'Turchia', 'Asia'),
('Z211', 'Indonesia', 'Asia'),
('Z212', 'Thailandia', 'Asia'),
('Z213', 'Vietnam', 'Asia'),
('Z214', 'Malaysia', 'Asia'),
-- America
('Z401', 'USA', 'America'),
('Z402', 'Brasile', 'America'),
('Z403', 'Argentina', 'America'),
('Z404', 'Canada', 'America'),
('Z405', 'Messico', 'America'),
('Z406', 'Cile', 'America'),
('Z407', 'Colombia', 'America'),
('Z408', 'Peru', 'America'),
('Z409', 'Cuba', 'America'),
('Z410', 'Bolivia', 'America'),
-- Oceania
('Z501', 'Australia', 'Oceania'),
('Z502', 'Nuova Zelanda', 'Oceania'),
('Z503', 'Figi', 'Oceania'),
('Z504', 'Papua Nuova Guinea', 'Oceania');

CREATE TABLE Citta_FVG (
    Nome VARCHAR(50) PRIMARY KEY
);

-- Inserting data into Citta_FVG table
INSERT INTO Citta_FVG (Nome) VALUES
('Trieste'), ('Udine'), ('Pordenone'), ('Gorizia'), ('Monfalcone'), ('Aquileia'), ('Codroipo'),
('Cividale del Friuli'), ('Tolmezzo'), ('Maniago'), ('Codroipo'), ('San Daniele del Friuli'),
('Palmanova'), ('Sacile'), ('Latisana'), ('Gemona'), ('Spilimbergo'), ('Tricesimo'), ('Tavagnacco'),
('Adegliaco'), ('Tarvisio'), ('Cervignano del Friuli'), ('Azzano Decimo'), ('San Vito al Tagliamento'),
('Lignano Sabbiadoro'), ('Fagagna'), ('Buttrio'), ('Pasian di Prato'), ('San Giorgio di Nogaro');

-- =========================
-- TABELLE PRINCIPALI
-- =========================

CREATE TABLE Cliente (
    Codice_Fiscale Codice_Fisc PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Cognome VARCHAR(50) NOT NULL,
    Indirizzo VARCHAR(100) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    CAP CAP NOT NULL,
    Telefono Telefono NOT NULL
);


CREATE TABLE Automobile (
    Targa Targa_Auto PRIMARY KEY,
    Anno AnnoAuto NOT NULL,
    Modello_Marca VARCHAR(50) NOT NULL,
    Codice_Fiscale Codice_Fisc NOT NULL,
    Chilometraggio INT NOT NULL,
    FOREIGN KEY (Codice_Fiscale) REFERENCES Cliente(Codice_Fiscale) ON DELETE CASCADE
);


CREATE TABLE Officina (
    Nome_Officina VARCHAR(50) PRIMARY KEY,  
    Indirizzo VARCHAR(100) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    CAP CAP NOT NULL,
    Telefono Telefono NOT NULL,
    Numero_Interventi INTEGER NOT NULL DEFAULT 0 CHECK (Numero_Interventi >= 0),
    FOREIGN KEY (Citta) REFERENCES Citta_FVG(Nome)
);

CREATE TABLE Magazzino (
    ID_MG SERIAL,
    Nome_Officina VARCHAR(50) NOT NULL,
    Capacita INTEGER NOT NULL CHECK (Capacita > 0),
    PRIMARY KEY (ID_MG, Nome_Officina),
    FOREIGN KEY (Nome_Officina) REFERENCES Officina(Nome_Officina) ON DELETE CASCADE
);

CREATE TABLE Pezzo_Ricambio (
    Codice_Pezzo VARCHAR(10) PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Categoria VARCHAR(50) NOT NULL,
    Costo_Unitario Costo NOT NULL
);

CREATE TABLE Stoccato (
    ID_MG INT NOT NULL,
    Nome_Officina VARCHAR(50) NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INTEGER NOT NULL CHECK (Quantita >= 0),
    PRIMARY KEY (ID_MG, Nome_Officina, Codice_Pezzo),
    FOREIGN KEY (ID_MG, Nome_Officina) REFERENCES Magazzino(ID_MG, Nome_Officina) ON DELETE CASCADE,
    FOREIGN KEY (Codice_Pezzo) REFERENCES Pezzo_Ricambio(Codice_Pezzo) ON DELETE CASCADE
);

CREATE TABLE Fornitore (
    PIVA PIVA PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Indirizzo VARCHAR(100) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    CAP CAP NOT NULL,
    Prefisso VARCHAR(4) NOT NULL,
    FOREIGN KEY (Prefisso) REFERENCES Nazione(Codice)
);

CREATE TABLE Fornisce (
    PIVA PIVA NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INTEGER NOT NULL CHECK (Quantita > 0),
    Data_Consegna DATE NOT NULL,
    ID_MG INTEGER NOT NULL,
    Nome_Officina VARCHAR(50) NOT NULL,
    PRIMARY KEY (PIVA, Codice_Pezzo, Data_Consegna, ID_MG, Nome_Officina),
    FOREIGN KEY (PIVA) REFERENCES Fornitore(PIVA) ON DELETE CASCADE,
    FOREIGN KEY (Codice_Pezzo) REFERENCES Pezzo_Ricambio(Codice_Pezzo) ON DELETE CASCADE,
    FOREIGN KEY (ID_MG, Nome_Officina) REFERENCES Magazzino(ID_MG, Nome_Officina) ON DELETE CASCADE
);

CREATE TABLE Intervento (
    Nome_Officina VARCHAR(50) NOT NULL,
    Numero_Intervento VARCHAR(10) NOT NULL,
    Targa Targa_Auto NOT NULL,
    Data_Inizio DATE NOT NULL,
    Data_Fine DATE,
    Stato stato_intervento NOT NULL DEFAULT 'Inizio',
    Tipologia VARCHAR(50) NOT NULL,
    Costo_Orario Costo NOT NULL,
    Ore_Manodopera OrePositive NOT NULL,
    Descrizione TEXT,
    PRIMARY KEY (Nome_Officina, Numero_Intervento),
    FOREIGN KEY (Nome_Officina) REFERENCES Officina(Nome_Officina) ON DELETE CASCADE,
    FOREIGN KEY (Targa) REFERENCES Automobile(Targa) ON DELETE CASCADE,
    CONSTRAINT check_stato_data_fine CHECK (
        (Stato = 'Concluso' AND Data_Fine IS NOT NULL) OR
        (Stato IN ('In Corso', 'Sospeso', 'Inizio') AND Data_Fine IS NULL)
    )
);



CREATE TABLE Utilizza (
    Nome_Officina VARCHAR(50) NOT NULL,
    Numero_Intervento VARCHAR(10) NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INTEGER NOT NULL CHECK (Quantita > 0),
    PRIMARY KEY (Nome_Officina, Numero_Intervento, Codice_Pezzo),
    FOREIGN KEY (Nome_Officina, Numero_Intervento) REFERENCES Intervento(Nome_Officina, Numero_Intervento) ON DELETE CASCADE,
    FOREIGN KEY (Codice_Pezzo) REFERENCES Pezzo_Ricambio(Codice_Pezzo) ON DELETE CASCADE
);

CREATE TABLE Fattura (
    Numero_Fattura SERIAL PRIMARY KEY,
    Data_Emissione DATE NOT NULL,
    Importo Costo NOT NULL,
    Nome_Officina VARCHAR(50) NOT NULL,
    Numero_Intervento VARCHAR(10) NOT NULL,
    Codice_Fiscale Codice_Fisc NOT NULL,
    Stato VARCHAR(20) NOT NULL CHECK (Stato IN ('Pagata', 'Non Pagata')),
    Data_Pagamento DATE,
    FOREIGN KEY (Nome_Officina, Numero_Intervento) REFERENCES Intervento(Nome_Officina, Numero_Intervento) ON DELETE CASCADE,
    FOREIGN KEY (Codice_Fiscale) REFERENCES Cliente(Codice_Fiscale),
    CONSTRAINT check_data_pagamento CHECK (
        (Stato = 'Pagata' AND Data_Pagamento IS NOT NULL) OR
        (Stato = 'Non Pagata' AND Data_Pagamento IS NULL)
    )
);

-- =========================
-- PEZZI DI RICAMBIO PREDEFINITI
-- =========================

INSERT INTO Pezzo_Ricambio (Codice_Pezzo, Nome, Categoria, Costo_Unitario) VALUES
('PR001', 'Filtro olio', 'Motore', 12.00),
('PR002', 'Filtro aria', 'Motore', 10.00),
('PR003', 'Filtro carburante', 'Motore', 15.00),
('PR004', 'Pastiglie freno', 'Freni', 25.00),
('PR005', 'Dischi freno', 'Freni', 60.00),
('PR006', 'Batteria', 'Elettrico', 110.00),
('PR007', 'Cinghia distribuzione', 'Motore', 55.00),
('PR008', 'Cinghia servizi', 'Motore', 30.00),
('PR009', 'Candela accensione', 'Motore', 9.00),
('PR010', 'Ammortizzatore', 'Sospensioni', 80.00),
('PR011', 'Braccio oscillante', 'Sospensioni', 45.00),
('PR012', 'Giunto sferico', 'Sospensioni', 35.00),
('PR013', 'Radiatore', 'Raffreddamento', 90.00),
('PR014', 'Termostato', 'Raffreddamento', 20.00),
('PR015', 'Pompa acqua', 'Raffreddamento', 40.00),
('PR016', 'Alternatore', 'Elettrico', 150.00),
('PR017', 'Motorino avviamento', 'Elettrico', 130.00),
('PR018', 'Sensore ossigeno', 'Motore', 22.00),
('PR019', 'Bobina accensione', 'Motore', 28.00),
('PR020', 'Filtro abitacolo', 'Climatizzazione', 13.00),
('PR021', 'Pompa carburante', 'Motore', 85.00),
('PR022', 'Faro anteriore', 'Carrozzeria', 65.00),
('PR023', 'Specchietto retrovisore', 'Carrozzeria', 40.00),
('PR024', 'Paraurti', 'Carrozzeria', 110.00),
('PR025', 'Centralina motore', 'Elettronica', 210.00),
('PR026', 'Kit frizione', 'Trasmissione', 180.00),
('PR027', 'Volano', 'Trasmissione', 120.00),
('PR028', 'Mozzo ruota', 'Ruote', 60.00),
('PR029', 'Cuscinetto ruota', 'Ruote', 25.00),
('PR030', 'Tirante sterzo', 'Sterzo', 35.00),
('PR031', 'Testina sterzo', 'Sterzo', 18.00),
('PR032', 'Sonda lambda', 'Scarico', 75.00),
('PR033', 'Marmitta', 'Scarico', 140.00),
('PR034', 'Catalizzatore', 'Scarico', 220.00),
('PR035', 'Tubo scarico', 'Scarico', 55.00),
('PR036', 'Ventola radiatore', 'Raffreddamento', 45.00),
('PR037', 'Compressore clima', 'Climatizzazione', 160.00),
('PR038', 'Evaporatore', 'Climatizzazione', 120.00),
('PR039', 'Resistenza ventola', 'Climatizzazione', 35.00),
('PR040', 'Serbatoio carburante', 'Alimentazione', 200.00),
('PR041', 'Iniettore', 'Alimentazione', 95.00),
('PR042', 'Pompa freno', 'Freni', 55.00),
('PR043', 'Pinza freno', 'Freni', 70.00),
('PR044', 'Tubo freno', 'Freni', 18.00),
('PR045', 'Sensore ABS', 'Freni', 40.00),
('PR046', 'Cavo candela', 'Motore', 8.00),
('PR047', 'Valvola EGR', 'Motore', 110.00),
('PR048', 'Carter olio', 'Motore', 65.00),
('PR049', 'Coperchio punterie', 'Motore', 55.00),
('PR050', 'Guarnizione testata', 'Motore', 45.00);





-- Table for managing supply requests
CREATE TABLE Richiesta_Fornitura (
    ID_Richiesta SERIAL PRIMARY KEY,
    Nome_Officina VARCHAR(50) NOT NULL,
    Numero_Intervento VARCHAR(10) NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INTEGER NOT NULL,
    Stato VARCHAR(20) NOT NULL DEFAULT 'Non Soddisfatta',
    Data_Richiesta TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ID_MG INTEGER NOT NULL,
    FOREIGN KEY (Codice_Pezzo) REFERENCES Pezzo_Ricambio(Codice_Pezzo),
    FOREIGN KEY (ID_MG, Nome_Officina) REFERENCES Magazzino(ID_MG, Nome_Officina)
);



-- =========================
-- FINE DDL.SQL
-- =========================
