import sys
import pdfplumber
import csv
import argparse

# USAGE: python3 pdfTables2csv.py ./dati_argo/cdc/docenti_classi_2025_26.pdf --skip_duplicate_header --remove_newlines

# Configurazione del parser degli argomenti
parser = argparse.ArgumentParser(description='Estrae le tabelle da un file PDF e salva il contenuto in un file CSV.')
parser.add_argument('pdf_file_path', type=str, help='Percorso del file PDF da elaborare.')
parser.add_argument('--skip_duplicate_header', action='store_true', help='Salta le intestazioni duplicate durante l\'estrazione delle tabelle.')
parser.add_argument('--csv_file_path', type=str, default='-', help='Percorso del file CSV di output.')
parser.add_argument('--remove_newlines', action='store_true', help='Rimuovi i caratteri di "a capo" dalle colonne.')

# Parsing degli argomenti
args = parser.parse_args()

# file PDF di input
pdf_file_path = args.pdf_file_path

# file CSV di output (o STDOUT)
csv_file_path = args.csv_file_path

# Salta header ripetuti (True se presente, False altrimenti)
skip_duplicate_header = args.skip_duplicate_header
header_already_written = False
start_row = 0

# Rimuovi i caratteri di "a capo" (True se presente, False altrimenti)
remove_newlines = args.remove_newlines

# Apri il file PDF
with pdfplumber.open(pdf_file_path) as pdf:
    # Inizializza csv_file come None
    csv_file = None

    if args.csv_file_path == '-':
        # Utilizza STDOUT per scrivere il CSV
        csv_file = sys.stdout
    else:
        # Crea un nuovo file CSV o sovrascrive il file esistente
        csv_file = open(args.csv_file_path, 'w', newline='')

    with csv_file:  # Gestisce automaticamente la chiusura
        writer = csv.writer(csv_file)

        # Itera attraverso le pagine del PDF
        for page in pdf.pages:
            # Estrai le tabelle dalla pagina
            tables = page.extract_tables()

            # Itera attraverso ogni tabella estratta
            for table in tables:

                # Scrive l'intestazione solo la prima volta
                if skip_duplicate_header and not header_already_written:
                    writer.writerow(table[0])
                    header_already_written = True
                    start_row = 1

                # Scrivi le righe della tabella nel file CSV
                for row in table[start_row:]:
                    processed_row = [] 

                    for column in row:  # Itera attraverso le colonne
                        if column is None:
                            column = '' 

                        if args.remove_newlines:
                            column = column.replace('\n', ' ').replace('\r', '')
                        
                        processed_row.append(column)

                    # Scrivi la riga nel CSV
                    writer.writerow(processed_row)
