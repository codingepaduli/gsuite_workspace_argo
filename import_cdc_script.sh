#!/bin/bash

# shellcheck source=./_environment.sh
source "_environment.sh"

# Importa il file CSV "Cdc_YYYY_MM_DD.csv" nella
# tabella "Cdc_YYYY_MM_DD" del database.
#
# Contiene i dati dei docenti presenti su Argo
#
# Esempio:
# docente,materie,classi
# Tizio Caio,italiano,3Cm
#
# Preparazione file Excel:
# - Controllare i campi della prima riga di intestazione rispetto al comando di CREATE TABLE
# - Salvare in CSV
#
# Preparazione file CSV
# - Trasformare la prima riga in minuscolo
# - python3 csvReaderUtil.py Cdc_YYYY_MM_DD.csv > Cdc_2024_09_20_parse.csv
# - Cancella tutte le righe vuote cercando la stringa ',,,,,,'

# Tabella docenti versionata alla data indicata
TABELLA_CDC_ARGO="Cdc_2024_09_20"

# File CSV 
FILE_CDC_ARGO_CSV="$BASE_DIR/dati_argo/Cdc/$TABELLA_CDC_ARGO.csv"

# Creo la tabella "docenti_argo"
$SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_CDC_ARGO';"

$SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_CDC_ARGO' (docente VARCHAR(200), materie  VARCHAR(200), classi VARCHAR(200));"

# Importa CSV dati
$SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CDC_ARGO" "$FILE_CDC_ARGO_CSV" --csv --empty-null

$SQLITE_CMD studenti.db "UPDATE $TABELLA_CDC_ARGO 
SET docente = TRIM(UPPER(docente)),
    materie = TRIM(UPPER(materie)),
    classi = SUBSTR(classi, 1, INSTR(classi,' ')-1);"

# test estrazione dati con
$SQLITE_CMD -header -table studenti.db "SELECT docente, materie, classi, SUBSTR(classi, 1, INSTR(classi,' ')-1) FROM $TABELLA_CDC_ARGO ORDER BY docente;"
