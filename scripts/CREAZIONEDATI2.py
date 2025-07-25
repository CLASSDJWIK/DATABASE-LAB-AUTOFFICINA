## libreria per generare causalmente dati per le mie regole di popolamento
pip install faker  


import random
import string
from faker import Faker
from datetime import datetime, timedelta

# Inizializzazione di Faker con localizzazioni compatibili con UTF-8
fake = Faker(['it_IT', 'en_US', 'fr_FR', 'de_DE', 'es_AR', 'pt_BR'])

# File di output per gli INSERT SQL
output_file = "popolamento_officina.sql"

# Funzioni di utilità per generare codici
def generate_codice_fiscale(nazione_codice):
    letters = ''.join(random.choices(string.ascii_uppercase, k=6))
    numbers = ''.join(random.choices(string.digits, k=2)) + random.choice(string.ascii_uppercase) + ''.join(random.choices(string.digits, k=2)) + random.choice(string.digits)
    return f"{letters}{numbers}Z{nazione_codice[1:]}"

def generate_targa(targhe_usate):
    while True:
        letters = ''.join(random.choices(string.ascii_uppercase, k=2))
        numbers = ''.join(random.choices(string.digits, k=3))
        letters_end = ''.join(random.choices(string.ascii_uppercase, k=2))
        targa = f"{letters}{numbers}{letters_end}"
        if targa not in targhe_usate:
            targhe_usate.add(targa)
            return targa

def generate_piva():
    letters = ''.join(random.choices(string.ascii_uppercase, k=3))
    numbers = ''.join(random.choices(string.digits, k=5))
    return f"{letters}{numbers}"

def generate_numero_intervento():
    letters = ''.join(random.choices(string.ascii_uppercase, k=3))
    numbers = ''.join(random.choices(string.digits, k=4))
    return f"{letters}{numbers}"

def generate_richiesta_fornitura():
    letters = ''.join(random.choices(string.ascii_uppercase, k=3))
    numbers = ''.join(random.choices(string.digits, k=4))
    return f"RF{letters}{numbers}"

# Funzione per rimuovere caratteri non-ASCII
def remove_non_ascii(text):
    return ''.join(c for c in text if ord(c) < 128)

# Dati per nazioni e continenti
nazioni = [
    ('Z100', 'Albania', 'Europa'), ('Z105', 'Croazia', 'Europa'), ('Z107', 'Italia', 'Europa'),
    ('Z112', 'Svizzera', 'Europa'), ('Z118', 'Slovenia', 'Europa'), ('Z120', 'Germania', 'Europa'),
    ('Z121', 'Austria', 'Europa'), ('Z122', 'Francia', 'Europa'), ('Z123', 'Spagna', 'Europa'),
    ('Z124', 'Portogallo', 'Europa'), ('Z125', 'Regno Unito', 'Europa'), ('Z126', 'Grecia', 'Europa'),
    ('Z127', 'Belgio', 'Europa'), ('Z128', 'Paesi Bassi', 'Europa'), ('Z129', 'Svezia', 'Europa'),
    ('Z130', 'Norvegia', 'Europa'), ('Z131', 'Danimarca', 'Europa'), ('Z132', 'Finlandia', 'Europa'),
    ('Z133', 'Polonia', 'Europa'), ('Z134', 'Romania', 'Europa'), ('Z135', 'Ungheria', 'Europa'),
    ('Z136', 'Repubblica Ceca', 'Europa'), ('Z137', 'Slovacchia', 'Europa'),
    ('Z301', 'Ghana', 'Africa'), ('Z302', 'Nigeria', 'Africa'), ('Z303', 'Sudafrica', 'Africa'),
    ('Z304', 'Egitto', 'Africa'), ('Z305', 'Senegal', 'Africa'), ('Z306', 'Marocco', 'Africa'),
    ('Z307', 'Algeria', 'Africa'), ('Z308', 'Kenya', 'Africa'), ('Z309', 'Tunisia', 'Africa'),
    ('Z310', 'Etiopia', 'Africa'), ('Z311', 'Camerun', 'Africa'), ('Z312', 'Costa d Avorio', 'Africa'),
    ('Z313', 'Mali', 'Africa'), ('Z314', 'Capo Verde', 'Africa'), ('Z315', 'Burkina Faso', 'Africa'),
    ('Z316', 'Guinea Equatoriale', 'Africa'), ('Z317', 'Repubblica Centrafricana', 'Africa'),
    ('Z318', 'Gabon', 'Africa'),
    ('Z201', 'Cina', 'Asia'), ('Z202', 'India', 'Asia'), ('Z203', 'Giappone', 'Asia'),
    ('Z204', 'Corea del Sud', 'Asia'), ('Z205', 'Pakistan', 'Asia'), ('Z206', 'Filippine', 'Asia'),
    ('Z207', 'Arabia Saudita', 'Asia'), ('Z208', 'Bangladesh', 'Asia'), ('Z209', 'Emirati Arabi Uniti', 'Asia'),
    ('Z210', 'Turchia', 'Asia'), ('Z211', 'Indonesia', 'Asia'), ('Z212', 'Thailandia', 'Asia'),
    ('Z213', 'Vietnam', 'Asia'), ('Z214', 'Malaysia', 'Asia'),
    ('Z401', 'USA', 'America'), ('Z402', 'Brasile', 'America'), ('Z403', 'Argentina', 'America'),
    ('Z404', 'Canada', 'America'), ('Z405', 'Messico', 'America'), ('Z406', 'Cile', 'America'),
    ('Z407', 'Colombia', 'America'), ('Z408', 'Peru', 'America'), ('Z409', 'Cuba', 'America'),
    ('Z410', 'Bolivia', 'America'),
    ('Z501', 'Australia', 'Oceania'), ('Z502', 'Nuova Zelanda', 'Oceania'), ('Z503', 'Figi', 'Oceania'),
    ('Z504', 'Papua Nuova Guinea', 'Oceania')
]

# Marche e modelli per continente
marche_modelli = {
    'Europa': {
        'Italia': {
            'Fiat': ['Panda', '500', 'Punto', 'Tipo', 'Bravo', '124 Spider'],
            'Alfa Romeo': ['Giulia', 'Stelvio', 'Giulietta', '4C', 'Mito'],
            'Lancia': ['Ypsilon', 'Delta', 'Thema', 'Flavia'],
            'Maserati': ['Ghibli', 'Quattroporte', 'Levante', 'GranTurismo'],
            'Ferrari': ['F8 Tributo', '488 GTB', 'Portofino', 'Roma', 'SF90 Stradale'],
            'Lamborghini': ['Huracán', 'Aventador', 'Urus'],
            'Iveco': ['Daily', 'Eurocargo']
        },
        'Germania': {
            'Volkswagen': ['Golf', 'Passat', 'Tiguan', 'Polo', 'Arteon', 'Touareg'],
            'Audi': ['A3', 'A4', 'A6', 'Q5', 'Q7', 'TT'],
            'BMW': ['Serie 1', 'Serie 3', 'Serie 5', 'X3', 'X5', 'i8'],
            'Mercedes-Benz': ['Classe A', 'Classe C', 'Classe E', 'GLC', 'GLE', 'S-Class'],
            'Opel': ['Corsa', 'Astra', 'Insignia', 'Mokka']
        },
        'Francia': {
            'Peugeot': ['208', '308', '3008', '508', 'Rifter'],
            'Renault': ['Clio', 'Megane', 'Captur', 'Kadjar'],
            'Citroën': ['C3', 'C4', 'C5 Aircross']
        },
        'Romania': {'Dacia': ['Duster', 'Sandero', 'Logan']},
        'Svezia': {'Volvo': ['XC40', 'XC60', 'XC90', 'S60']},
        'Repubblica Ceca': {'Skoda': ['Octavia', 'Superb', 'Fabia']},
        'Spagna': {'Seat': ['Ibiza', 'Leon', 'Ateca']},
        'Regno Unito': {
            'Jaguar': ['XE', 'XF', 'F-PACE'],
            'Land Rover': ['Discovery', 'Range Rover Evoque', 'Defender']
        }
    },
    'Africa': {
        'Marocco': {'Laraki': ['Fulgura', 'Epitome']},
        'Ghana': {'Kantanka': ['Amoah', 'Onante']},
        'Kenya': {'Mobius Motors': ['Mobius One', 'Mobius Two']},
        'Tunisia': {'Wallyscar': ['Clarity', 'Izis']},
        'Burkina Faso': {'Burkina Faso Motors': ['Tracker', 'Sentinel']},
        'Algeria': {
            'SNVI': ['Tarek', 'Kama'],
            'Algeria Auto': ['Nova']
        }
    },
    'Asia': {
        'Giappone': {
            'Toyota': ['Corolla', 'Camry', 'RAV4', 'Prius'],
            'Nissan': ['Altima', 'Sentra', 'Rogue', 'Leaf'],
            'Honda': ['Civic', 'Accord', 'CR-V', 'Jazz'],
            'Suzuki': ['Swift', 'Vitara'],
            'Mazda': ['3', 'CX-5', 'MX-5']
        },
        'Corea del Sud': {
            'Hyundai': ['i30', 'Tucson', 'Santa Fe', 'Kona'],
            'Kia': ['Rio', 'Sportage', 'Ceed']
        },
        'India': {'Tata Motors': ['Nexon', 'Harrier']},
        'Cina': {
            'Geely': ['Emgrand', 'Coolray'],
            'Great Wall Motors': ['Haval H6', 'Ora Good Cat'],
            'BYD': ['Tang', 'Qin']
        }
    },
    'America': {
        'USA': {
            'Ford': ['Fiesta', 'Focus', 'Mustang', 'Explorer', 'F-150'],
            'Chevrolet': ['Cruze', 'Malibu', 'Camaro', 'Silverado'],
            'Dodge': ['Charger', 'Challenger', 'Ram'],
            'Tesla': ['Model S', 'Model 3', 'Model X'],
            'Jeep': ['Wrangler', 'Grand Cherokee', 'Compass'],
            'Cadillac': ['CTS', 'Escalade'],
            'Chrysler': ['Pacifica', '300']
        }
    },
    'Oceania': {
        'Australia': {'Holden': ['Commodore', 'Trax'], 'Ford Australia': ['Falcon', 'Territory']}
    }
}

# Mappa nazioni a marchi disponibili
nazione_to_marche = {
    'Italia': ['Fiat', 'Alfa Romeo', 'Lancia', 'Maserati', 'Ferrari', 'Lamborghini', 'Iveco'],
    'Germania': ['Volkswagen', 'Audi', 'BMW', 'Mercedes-Benz', 'Opel'],
    'Francia': ['Peugeot', 'Renault', 'Citroën'],
    'Romania': ['Dacia'],
    'Svezia': ['Volvo'],
    'Repubblica Ceca': ['Skoda'],
    'Spagna': ['Seat'],
    'Regno Unito': ['Jaguar', 'Land Rover'],
    'Marocco': ['Laraki'],
    'Ghana': ['Kantanka'],
    'Kenya': ['Mobius Motors'],
    'Tunisia': ['Wallyscar'],
    'Burkina Faso': ['Burkina Faso Motors'],
    'Algeria': ['SNVI', 'Algeria Auto'],
    'Giappone': ['Toyota', 'Nissan', 'Honda', 'Suzuki', 'Mazda'],
    'Corea del Sud': ['Hyundai', 'Kia'],
    'India': ['Tata Motors'],
    'Cina': ['Geely', 'Great Wall Motors', 'BYD'],
    'USA': ['Ford', 'Chevrolet', 'Dodge', 'Tesla', 'Jeep', 'Cadillac', 'Chrysler'],
    'Australia': ['Holden', 'Ford Australia']
}

# Città FVG
citta_fvg = [
    'Trieste', 'Udine', 'Pordenone', 'Gorizia', 'Monfalcone', 'Aquileia', 'Codroipo',
    'Cividale del Friuli', 'Tolmezzo', 'Maniago', 'San Daniele del Friuli', 'Palmanova',
    'Sacile', 'Latisana', 'Gemona', 'Spilimbergo', 'Tricesimo', 'Tavagnacco', 'Adegliaco',
    'Tarvisio', 'Cervignano del Friuli', 'Azzano Decimo', 'San Vito al Tagliamento',
    'Lignano Sabbiadoro', 'Fagagna', 'Buttrio', 'Pasian di Prato', 'San Giorgio di Nogaro'
]

# Pezzi di ricambio
pezzi = [
    ('PR001', 'Filtro olio', 'Motore', 12.00), ('PR002', 'Filtro aria', 'Motore', 10.00),
    ('PR003', 'Filtro carburante', 'Motore', 15.00), ('PR004', 'Pastiglie freno', 'Freni', 25.00),
    ('PR005', 'Dischi freno', 'Freni', 60.00), ('PR006', 'Batteria', 'Elettrico', 110.00),
    ('PR007', 'Cinghia distribuzione', 'Motore', 55.00), ('PR008', 'Cinghia servizi', 'Motore', 30.00),
    ('PR009', 'Candela accensione', 'Motore', 9.00), ('PR010', 'Ammortizzatore', 'Sospensioni', 80.00),
    ('PR011', 'Braccio oscillante', 'Sospensioni', 45.00), ('PR012', 'Giunto sferico', 'Sospensioni', 35.00),
    ('PR013', 'Radiatore', 'Raffreddamento', 90.00), ('PR014', 'Termostato', 'Raffreddamento', 20.00),
    ('PR015', 'Pompa acqua', 'Raffreddamento', 40.00), ('PR016', 'Alternatore', 'Elettrico', 150.00),
    ('PR017', 'Motorino avviamento', 'Elettrico', 130.00), ('PR018', 'Sensore ossigeno', 'Motore', 22.00),
    ('PR019', 'Bobina accensione', 'Motore', 28.00), ('PR020', 'Filtro abitacolo', 'Climatizzazione', 13.00),
    ('PR021', 'Pompa carburante', 'Motore', 85.00), ('PR022', 'Faro anteriore', 'Carrozzeria', 65.00),
    ('PR023', 'Specchietto retrovisore', 'Carrozzeria', 40.00), ('PR024', 'Paraurti', 'Carrozzeria', 110.00),
    ('PR025', 'Centralina motore', 'Elettronica', 210.00), ('PR026', 'Kit frizione', 'Trasmissione', 180.00),
    ('PR027', 'Volano', 'Trasmissione', 120.00), ('PR028', 'Mozzo ruota', 'Ruote', 60.00),
    ('PR029', 'Cuscinetto ruota', 'Ruote', 25.00), ('PR030', 'Tirante sterzo', 'Sterzo', 35.00),
    ('PR031', 'Testina sterzo', 'Sterzo', 18.00), ('PR032', 'Sonda lambda', 'Scarico', 75.00),
    ('PR033', 'Marmitta', 'Scarico', 140.00), ('PR034', 'Catalizzatore', 'Scarico', 220.00),
    ('PR035', 'Tubo scarico', 'Scarico', 55.00), ('PR036', 'Ventola radiatore', 'Raffreddamento', 45.00),
    ('PR037', 'Compressore clima', 'Climatizzazione', 160.00), ('PR038', 'Evaporatore', 'Climatizzazione', 120.00),
    ('PR039', 'Resistenza ventola', 'Climatizzazione', 35.00), ('PR040', 'Serbatoio carburante', 'Alimentazione', 200.00),
    ('PR041', 'Iniettore', 'Alimentazione', 95.00), ('PR042', 'Pompa freno', 'Freni', 55.00),
    ('PR043', 'Pinza freno', 'Freni', 70.00), ('PR044', 'Tubo freno', 'Freni', 18.00),
    ('PR045', 'Sensore ABS', 'Freni', 40.00), ('PR046', 'Cavo candela', 'Motore', 8.00),
    ('PR047', 'Valvola EGR', 'Motore', 110.00), ('PR048', 'Carter olio', 'Motore', 65.00),
    ('PR049', 'Coperchio punterie', 'Motore', 55.00), ('PR050', 'Guarnizione testata', 'Motore', 45.00)
]

# Tipologie di intervento
tipologie_intervento = [
    'Tagliando', 'Sostituzione freni', 'Riparazione motore', 'Sostituzione batteria',
    'Sostituzione sospensioni', 'Riparazione climatizzatore', 'Sostituzione marmitta',
    'Riparazione carrozzeria', 'Sostituzione gomme', 'Diagnostica elettronica'
]

# Distribuzione clienti per continente
distribuzione_clienti = {
    'Europa': 900,  # 50% di 1800
    'Africa': 360,  # 20%
    'Asia': 270,    # 15%
    'America': 180, # 10%
    'Oceania': 90   # 5%
}

# Apertura file SQL
with open(output_file, 'w', encoding='utf-8') as f:
    f.write("-- Popolamento database officina\n\n")

    # 1. Popolamento Cliente
    f.write("-- Inserimento Clienti\n")
    clienti = []
    for continente, num_clienti in distribuzione_clienti.items():
        nazioni_continente = [n for n in nazioni if n[2] == continente]
        for _ in range(num_clienti):
            nazione = random.choice(nazioni_continente)
            codice_fiscale = generate_codice_fiscale(nazione[0])
            fake.seed_instance(codice_fiscale)
            if continente == 'Asia':
                fake_local = Faker('en_US')
            elif continente == 'Africa':
                fake_local = Faker(['en_US', 'fr_FR'])
            else:
                fake_local = fake
            nome = remove_non_ascii(fake_local.first_name().replace("'", "''"))[:50]
            cognome = remove_non_ascii(fake_local.last_name().replace("'", "''"))[:50]
            citta = remove_non_ascii(fake_local.city().replace("'", "''"))[:50] if continente != 'Europa' else random.choice(citta_fvg)
            indirizzo = remove_non_ascii(fake_local.street_address().replace("'", "''"))[:100]
            cap = ''.join(random.choices(string.digits, k=5))
            telefono = f"+{''.join(random.choices(string.digits, k=random.randint(5, 12)))}"
            clienti.append((codice_fiscale, nome, cognome, indirizzo, citta, cap, telefono, nazione[0]))
            f.write(f"INSERT INTO Cliente (Codice_Fiscale, Nome, Cognome, Indirizzo, Citta, CAP, Telefono) "
                    f"VALUES ('{codice_fiscale}', '{nome}', '{cognome}', '{indirizzo}', '{citta}', '{cap}', '{telefono}');\n")
    f.write("\n")

    # 2. Popolamento Automobile
    f.write("-- Inserimento Automobili\n")
    auto = []
    targhe_usate = set()
    num_auto_target = 2200
    clienti_con_3_auto = random.sample(clienti, 200)
    clienti_rimanenti = [c for c in clienti if c not in clienti_con_3_auto]
    clienti_con_2_auto = random.sample(clienti_rimanenti, 400)
    clienti_con_1_auto = [c for c in clienti_rimanenti if c not in clienti_con_2_auto]

    for cliente in clienti_con_3_auto:
        codice_fiscale = cliente[0]
        nazione = next(n[1] for n in nazioni if n[0] == cliente[7])
        continente = next(n[2] for n in nazioni if n[0] == cliente[7])
        for _ in range(3):
            if len(auto) >= num_auto_target:
                break
            targa = generate_targa(targhe_usate)
            marche_disponibili = nazione_to_marche.get(nazione, [])
            if not marche_disponibili:
                marche_disponibili = sum([list(m.keys()) for m in marche_modelli[continente].values()], [])
            marca = random.choice(marche_disponibili)
            modelli = None
            for naz in marche_modelli[continente]:
                if marca in marche_modelli[continente][naz]:
                    modelli = marche_modelli[continente][naz][marca]
                    break
            modello = random.choice(modelli) if modelli else 'Generic'
            modello_marca = f"{marca} {modello}"[:50]
            anno = random.randint(1970, 2025)
            chilometraggio = random.randint(6000, 300000)
            auto.append((targa, codice_fiscale, modello_marca, anno, chilometraggio))
            f.write(f"INSERT INTO Automobile (Targa, Codice_Fiscale, Modello_Marca, Anno, Chilometraggio) "
                    f"VALUES ('{targa}', '{codice_fiscale}', '{modello_marca}', {anno}, {chilometraggio});\n")

    for cliente in clienti_con_2_auto:
        codice_fiscale = cliente[0]
        nazione = next(n[1] for n in nazioni if n[0] == cliente[7])
        continente = next(n[2] for n in nazioni if n[0] == cliente[7])
        for _ in range(2):
            if len(auto) >= num_auto_target:
                break
            targa = generate_targa(targhe_usate)
            marche_disponibili = nazione_to_marche.get(nazione, [])
            if not marche_disponibili:
                marche_disponibili = sum([list(m.keys()) for m in marche_modelli[continente].values()], [])
            marca = random.choice(marche_disponibili)
            modelli = None
            for naz in marche_modelli[continente]:
                if marca in marche_modelli[continente][naz]:
                    modelli = marche_modelli[continente][naz][marca]
                    break
            modello = random.choice(modelli) if modelli else 'Generic'
            modello_marca = f"{marca} {modello}"[:50]
            anno = random.randint(1970, 2025)
            chilometraggio = random.randint(6000, 300000)
            auto.append((targa, codice_fiscale, modello_marca, anno, chilometraggio))
            f.write(f"INSERT INTO Automobile (Targa, Codice_Fiscale, Modello_Marca, Anno, Chilometraggio) "
                    f"VALUES ('{targa}', '{codice_fiscale}', '{modello_marca}', {anno}, {chilometraggio});\n")

    for cliente in clienti_con_1_auto:
        if len(auto) >= num_auto_target:
            break
        codice_fiscale = cliente[0]
        nazione = next(n[1] for n in nazioni if n[0] == cliente[7])
        continente = next(n[2] for n in nazioni if n[0] == cliente[7])
        targa = generate_targa(targhe_usate)
        marche_disponibili = nazione_to_marche.get(nazione, [])
        if not marche_disponibili:
            marche_disponibili = sum([list(m.keys()) for m in marche_modelli[continente].values()], [])
        marca = random.choice(marche_disponibili)
        modelli = None
        for naz in marche_modelli[continente]:
            if marca in marche_modelli[continente][naz]:
                modelli = marche_modelli[continente][naz][marca]
                break
        modello = random.choice(modelli) if modelli else 'Generic'
        modello_marca = f"{marca} {modello}"[:50]
        anno = random.randint(1970, 2025)
        chilometraggio = random.randint(6000, 300000)
        auto.append((targa, codice_fiscale, modello_marca, anno, chilometraggio))
        f.write(f"INSERT INTO Automobile (Targa, Codice_Fiscale, Modello_Marca, Anno, Chilometraggio) "
                f"VALUES ('{targa}', '{codice_fiscale}', '{modello_marca}', {anno}, {chilometraggio});\n")
    f.write("\n")

    # 3. Popolamento Officina e Magazzino
    f.write("-- Inserimento Officine e Magazzini\n")
    officine = []
    magazzini = []
    for i, citta in enumerate(citta_fvg, 1):
        nome_officina = f"Officina {citta}"[:50]
        indirizzo = remove_non_ascii(fake.street_address().replace("'", "''"))[:100]
        cap = ''.join(random.choices(string.digits, k=5))
        telefono = f"+39{''.join(random.choices(string.digits, k=9))}"
        officine.append((nome_officina, citta, cap, telefono))
        f.write(f"INSERT INTO Officina (Nome_Officina, Indirizzo, Citta, CAP, Telefono, Numero_Interventi) "
                f"VALUES ('{nome_officina}', '{indirizzo}', '{citta}', '{cap}', '{telefono}', 0);\n")
        capacita = random.randint(15000, 100000)
        magazzini.append((i, nome_officina, capacita))
        f.write(f"INSERT INTO Magazzino (ID_MG, Nome_Officina, Capacita) "
                f"VALUES ({i}, '{nome_officina}', {capacita});\n")
    f.write("\n")

    # 4. Popolamento Fornitore
    f.write("-- Inserimento Fornitori\n")
    fornitori = []
    amazon_piva = generate_piva()
    fornitori.append((amazon_piva, 'Amazon', remove_non_ascii(fake.street_address().replace("'", "''"))[:100], random.choice(citta_fvg), ''.join(random.choices(string.digits, k=5)), 'Z107'))
    f.write(f"INSERT INTO Fornitore (PIVA, Nome, Indirizzo, Citta, CAP, Prefisso) "
            f"VALUES ('{amazon_piva}', 'Amazon', '{fornitori[0][2]}', '{fornitori[0][3]}', '{fornitori[0][4]}', 'Z107');\n")
    for i in range(25):
        nazione = random.choice(nazioni)
        nome = remove_non_ascii(fake.company().replace("'", "''"))[:50]
        indirizzo = remove_non_ascii(fake.street_address().replace("'", "''"))[:100]
        citta = remove_non_ascii(fake.city().replace("'", "''"))[:50] if nazione[2] != 'Europa' else random.choice(citta_fvg)
        piva = generate_piva()
        cap = ''.join(random.choices(string.digits, k=5))
        fornitori.append((piva, nome, indirizzo, citta, cap, nazione[0]))
        f.write(f"INSERT INTO Fornitore (PIVA, Nome, Indirizzo, Citta, CAP, Prefisso) "
                f"VALUES ('{piva}', '{nome}', '{indirizzo}', '{citta}', '{cap}', '{nazione[0]}');\n")
    f.write("\n")

    # 5. Popolamento Fornisce
    f.write("-- Inserimento Fornisce (genera scorte in Stoccato tramite trigger)\n")
    scorte_per_officina = {o[0]: {} for o in officine}
    for magazzino in magazzini:
        id_mg, nome_officina, capacita = magazzino
        citta_officina = next(o[1] for o in officine if o[0] == nome_officina)
        num_pezzi = random.randint(41, 46)
        pezzi_selezionati = random.sample(pezzi, num_pezzi)
        for pezzo in pezzi_selezionati:
            if amazon_piva and citta_officina in ['Udine', 'Tricesimo']:
                quantita = 30
                piva_fornitore = amazon_piva
            elif amazon_piva and citta_officina == 'Trieste':
                quantita = 15
                piva_fornitore = amazon_piva
            else:
                quantita = random.randint(50, 110)
                piva_fornitore = random.choice([f[0] for f in fornitori if f[0] != amazon_piva])
            data_consegna = (datetime(2025, 7, 24) - timedelta(days=random.randint(1, 30))).strftime('%Y-%m-%d')
            f.write(f"INSERT INTO Fornisce (PIVA, Codice_Pezzo, Quantita, Data_Consegna, ID_MG, Nome_Officina) "
                    f"VALUES ('{piva_fornitore}', '{pezzo[0]}', {quantita}, '{data_consegna}', {id_mg}, '{nome_officina}');\n")
            if pezzo[0] in scorte_per_officina[nome_officina]:
                scorte_per_officina[nome_officina][pezzo[0]] += quantita
            else:
                scorte_per_officina[nome_officina][pezzo[0]] = quantita
    f.write("\n")

    # 6. Popolamento Intervento (inizialmente tutti Inizio)
    f.write("-- Inserimento Interventi (tutti Inizio)\n")
    interventi = []
    num_interventi = 2200
    start_date = datetime(2025, 7, 24)
    giorni_totali = 30
    interventi_per_giorno = [num_interventi // giorni_totali + (1 if i < num_interventi % giorni_totali else 0) for i in range(giorni_totali)]

    id_intervento = 0
    auto_disponibili = auto.copy()
    random.shuffle(auto_disponibili)
    for giorno, num_interventi_giorno in enumerate(interventi_per_giorno):
        data_giorno = (start_date - timedelta(days=giorno)).strftime('%Y-%m-%d')
        for _ in range(num_interventi_giorno):
            if id_intervento >= num_interventi or not auto_disponibili:
                break
            targa = auto_disponibili.pop()[0]
            nome_officina = random.choice(officine)[0]
            numero_intervento = generate_numero_intervento()
            data_inizio = data_giorno
            stato = 'Inizio'
            tipologia = random.choice(tipologie_intervento)
            costo_orario = round(random.uniform(20.00, 60.00), 2)
            ore_manodopera = round(random.uniform(1.0, 8.0), 2)
            interventi.append((nome_officina, numero_intervento, targa, data_inizio, None, stato, tipologia, costo_orario, ore_manodopera))
            f.write(f"INSERT INTO Intervento (Nome_Officina, Numero_Intervento, Targa, Data_Inizio, Data_Fine, Stato, Tipologia, Costo_Orario, Ore_Manodopera) "
                    f"VALUES ('{nome_officina}', '{numero_intervento}', '{targa}', '{data_inizio}', NULL, '{stato}', '{tipologia}', {costo_orario}, {ore_manodopera});\n")
            id_intervento += 1
    f.write("\n")

    # 7. Aggiornamento Interventi a In Corso e popolamento Utilizza (1:1)
    f.write("-- Aggiornamento Interventi a In Corso e Inserimento Utilizza (1:1)\n")
    utilizza = []
    pezzi_per_officina = {o[0]: {'pezzi': set(), 'quantita_totale': 0} for o in officine}
    for intervento in interventi:
        nome_officina, numero_intervento, targa, data_inizio, _, _, tipologia, costo_orario, ore_manodopera = intervento
        f.write(f"UPDATE Intervento SET Stato = 'In Corso', Data_Fine = NULL "
                f"WHERE Nome_Officina = '{nome_officina}' AND Numero_Intervento = '{numero_intervento}';\n")
        # Seleziona solo pezzi con scorte positive
        pezzi_disponibili = [p for p in pezzi if p[0] in scorte_per_officina[nome_officina] and scorte_per_officina[nome_officina][p[0]] > 0]
        if pezzi_disponibili:
            pezzo = random.choice(pezzi_disponibili)
            quantita = random.randint(1, min(5, scorte_per_officina[nome_officina][pezzo[0]]))
            utilizza.append((nome_officina, numero_intervento, pezzo[0], quantita))
            pezzi_per_officina[nome_officina]['pezzi'].add(pezzo[0])
            pezzi_per_officina[nome_officina]['quantita_totale'] += quantita
            scorte_per_officina[nome_officina][pezzo[0]] -= quantita
            f.write(f"INSERT INTO Utilizza (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita) "
                    f"VALUES ('{nome_officina}', '{numero_intervento}', '{pezzo[0]}', {quantita});\n")
    f.write("\n")

    # 8. Aggiornamento Interventi: 80% Concluso, 20% Sospeso con Richieste_Fornitura
    f.write("-- Aggiornamento Interventi: 80% Concluso, 20% Sospeso con Richieste_Fornitura\n")
    interventi_conclusi = random.sample(interventi, int(0.8 * num_interventi))  # 1760 Concluso
    interventi_sospesi = [i for i in interventi if i not in interventi_conclusi]  # 440 Sospeso
    richieste_fornitura = []
    richieste_usate = set()

    # Interventi Concluso
    for intervento in interventi_conclusi:
        nome_officina, numero_intervento, targa, data_inizio, _, _, tipologia, costo_orario, ore_manodopera = intervento
        data_fine = data_inizio
        f.write(f"UPDATE Intervento SET Stato = 'Concluso', Data_Fine = '{data_fine}' "
                f"WHERE Nome_Officina = '{nome_officina}' AND Numero_Intervento = '{numero_intervento}';\n")

    # Interventi Sospeso con Richieste_Fornitura
    for intervento in interventi_sospesi:
        nome_officina, numero_intervento, targa, data_inizio, _, _, tipologia, costo_orario, ore_manodopera = intervento
        f.write(f"UPDATE Intervento SET Stato = 'Sospeso', Data_Fine = NULL "
                f"WHERE Nome_Officina = '{nome_officina}' AND Numero_Intervento = '{numero_intervento}';\n")
        # Se l'intervento non ha ancora una riga in Utilizza, aggiungi una riga con quantità elevata
        if not any(u[0] == nome_officina and u[1] == numero_intervento for u in utilizza):
            pezzi_disponibili = [p for p in pezzi if p[0] in scorte_per_officina[nome_officina]]
            if pezzi_disponibili:
                pezzo = random.choice(pezzi_disponibili)
                quantita = random.randint(10, 20)  # Quantità elevata per simulare mancanza
                utilizza.append((nome_officina, numero_intervento, pezzo[0], quantita))
                pezzi_per_officina[nome_officina]['pezzi'].add(pezzo[0])
                pezzi_per_officina[nome_officina]['quantita_totale'] += quantita
                scorte_per_officina[nome_officina][pezzo[0]] -= quantita
                f.write(f"INSERT INTO Utilizza (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita) "
                        f"VALUES ('{nome_officina}', '{numero_intervento}', '{pezzo[0]}', {quantita});\n")
                # Creazione richiesta di fornitura
                id_richiesta = generate_richiesta_fornitura()
                while id_richiesta in richieste_usate:
                    id_richiesta = generate_richiesta_fornitura()
                richieste_usate.add(id_richiesta)
                piva_fornitore = random.choice([f[0] for f in fornitori])
                data_richiesta = data_inizio
                richieste_fornitura.append((id_richiesta, nome_officina, pezzo[0], quantita, data_richiesta, piva_fornitore))
                f.write(f"INSERT INTO Richieste_Fornitura (ID_Richiesta, Nome_Officina, Codice_Pezzo, Quantita, Data_Richiesta, PIVA) "
                        f"VALUES ('{id_richiesta}', '{nome_officina}', '{pezzo[0]}', {quantita}, '{data_richiesta}', '{piva_fornitore}');\n")
    f.write("\n")

    # 9. Bilanciamento Utilizza per raggiungere 41-46 pezzi distinti per officina
    f.write("-- Bilanciamento Utilizza per raggiungere 41-46 pezzi distinti per officina\n")
    for nome_officina, dati in pezzi_per_officina.items():
        pezzi_usati = dati['pezzi']
        quantita_totale = dati['quantita_totale']
        target_pezzi = random.randint(41, 46)
        pezzi_disponibili = [p for p in pezzi if p[0] in scorte_per_officina[nome_officina] and scorte_per_officina[nome_officina][p[0]] > 0 and p[0] not in pezzi_usati]
        interventi_conclusi_officina = [i for i in interventi_conclusi if i[0] == nome_officina]
        while len(pezzi_usati) < target_pezzi and pezzi_disponibili and interventi_conclusi_officina:
            pezzo = random.choice(pezzi_disponibili)
            pezzi_usati.add(pezzo[0])
            pezzi_disponibili.remove(pezzo)
            quantita = random.randint(1, min(5, scorte_per_officina[nome_officina][pezzo[0]]))
            numero_intervento = random.choice([i[1] for i in interventi_conclusi_officina])
            # Verifica che l'intervento non abbia già una riga in Utilizza
            if not any(u[0] == nome_officina and u[1] == numero_intervento for u in utilizza):
                utilizza.append((nome_officina, numero_intervento, pezzo[0], quantita))
                quantita_totale += quantita
                scorte_per_officina[nome_officina][pezzo[0]] -= quantita
                f.write(f"INSERT INTO Utilizza (Nome_Officina, Numero_Intervento, Codice_Pezzo, Quantita) "
                        f"VALUES ('{nome_officina}', '{numero_intervento}', '{pezzo[0]}', {quantita});\n")
    f.write("\n")

print(f"Script SQL generato: {output_file}")
