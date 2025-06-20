
-- =========================
-- DOMINI
-- =========================
CREATE DOMAIN Telefono AS VARCHAR(15) CHECK (VALUE ~ '^[0-9+]{6,15}$');
CREATE DOMAIN AnnoAuto AS INT CHECK (VALUE BETWEEN 1900 AND 2025);
CREATE DOMAIN Costo AS NUMERIC(10, 2) CHECK (VALUE > 0);
CREATE DOMAIN OrePositive AS NUMERIC(5, 2) CHECK (VALUE > 0);
CREATE DOMAIN Targa_Auto AS VARCHAR(7) CHECK (VALUE ~ '^[A-Z]{2}[0-9]{3}[A-Z]{2}$');

CREATE DOMAIN Codice_Fisc AS VARCHAR(16) 
CHECK (VALUE ~ '^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[0-9]Z[0-9]{3}$'); 


CREATE DOMAIN PIVA AS VARCHAR(11) CHECK (VALUE ~ '^[A-Z]{3}[A-Z]{3}[0-9]{5}$');

CREATE DOMAIN CAP AS CHAR(5) CHECK (VALUE ~ '^[0-9]{5}$'); 
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
('Z408', 'Perù', 'America'),
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

INSERT INTO Citta_FVG (Nome) VALUES
('Trieste'),
('Udine'),
('Gorizia'),
('Pordenone'),
('Monfalcone'),
('Cividale del Friuli'),
('Aquileia'),
('Lignano Sabbiadoro'),
('Sauris'),
('Forni di Sopra'),
('Villa Santina'),
('Aptia'),
('Tavagnacco'),
('Adegliaco'),
('San Daniele del Friuli'),
('Buttrio'),
('Latisana'),
('Codroipo'),
('Tricesimo'),
('Spilimbergo');

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
    Anno INT NOT NULL,
    Modello_Marca VARCHAR(50) NOT NULL,
    Codice_Fiscale Codice_Fisc NOT NULL
    Chilometraggio INT NOT NULL
   FOREIGN KEY (Codice_Fiscale) REFERENCES Cliente(Codice_Fiscale) ON DELETE CASCADE

);


CREATE TABLE Officina (
    Nome_Officina VARCHAR(50) PRIMARY KEY,  
    Indirizzo VARCHAR(100) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    CAP CAP NOT NULL,
    Telefono Telefono NOT NULL,
    Numero_Interventi INT DEFAULT 0,
    FOREIGN KEY (Citta) REFERENCES Citta_FVG(Nome)
);

CREATE TABLE Magazzino (
    ID_MG SERIAL,
    Nome_Officina VARCHAR(50) NOT NULL,
    Capacita INT NOT NULL,
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
    Quantita INT NOT NULL,
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
    Telefono Telefono NOT NULL
);

CREATE TABLE Fornisce (
    PIVA PIVA NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INT NOT NULL,
    Data_Consegna DATE NOT NULL,
    ID_MG INT NOT NULL,
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
    Stato VARCHAR(20) NOT NULL DEFAULT 'Inizio' CHECK (Stato IN ('Inizio', 'In Corso', 'Sospeso', 'Annullato', 'Concluso')),
    Tipologia VARCHAR(50) NOT NULL,
    Costo_Orario Costo NOT NULL,
    Ore_Manodopera OrePositive NOT NULL,
    Descrizione TEXT,
    PRIMARY KEY (Nome_Officina, Numero_Intervento),
    FOREIGN KEY (Nome_Officina) REFERENCES Officina(Nome_Officina) ON DELETE CASCADE,
    FOREIGN KEY (Targa) REFERENCES Automobile(Targa) ON DELETE CASCADE
);

CREATE TABLE Utilizza (
    Nome_Officina VARCHAR(50) NOT NULL,
    Numero_Intervento VARCHAR(10) NOT NULL,
    Codice_Pezzo VARCHAR(10) NOT NULL,
    Quantita INT NOT NULL,
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
    FOREIGN KEY (Codice_Fiscale) REFERENCES Cliente(Codice_Fiscale)
);

-- =========================
-- PEZZI DI RICAMBIO PREDEFINITI
-- =========================

INSERT INTO Pezzo_Ricambio (Codice_Pezzo, Nome, Categoria, Costo_Unitario)
VALUES
('PR001', 'Filtro dell''olio', 'Motore', 10.00),
('PR002', 'Filtro dell''aria', 'Motore', 8.00),
('PR003', 'Filtro del carburante', 'Motore', 12.00),
('PR004', 'Pastiglie dei freni', 'Freni', 25.00),
('PR005', 'Dischi dei freni', 'Freni', 60.00),
('PR006', 'Batteria', 'Elettricità', 120.00),
('PR007', 'Cinghia di distribuzione', 'Motore', 50.00),
('PR008', 'Cinghia dei servizi', 'Motore', 30.00),
('PR009', 'Candele di accensione', 'Motore', 15.00),
('PR010', 'Ammortizzatori', 'Sospensione', 80.00),
('PR011', 'Bracci oscillanti', 'Sospensione', 45.00),
('PR012', 'Giunti sferici', 'Sospensione', 35.00),
('PR013', 'Radiatore', 'Raffreddamento', 90.00),
('PR014', 'Termostato', 'Raffreddamento', 20.00),
('PR015', 'Pompa dell''acqua', 'Raffreddamento', 40.00),
('PR016', 'Alternatore', 'Elettricità', 150.00),
('PR017', 'Motorino di avviamento', 'Elettricità', 130.00),
('PR018', 'Sensore ossigeno', 'Motore', 20.00),
('PR019', 'Bobina di accensione', 'Motore', 25.00),
('PR020', 'Filtro dell''abitacolo', 'Climatizzazione', 10.00);

-- =========================
-- FINE DDL.SQL
-- =========================

