#!/bin/bash

source "_environment.sh"

# Importa il file CSV "docenti_argo_YYYY_MM_DD.csv" nella
# tabella "docenti_argo_YYYY_MM_DD" del database.
#
# Contiene i dati dei docenti presenti su Argo
#
# Esempio:
# cognome,nome,cod_fisc,email_personale,tel,email_gsuite
# Tizio,Caio,CF_CF_CF,mail_personale,12345678,
#
# Preparazione file Excel:
# - Controllare i campi della prima riga di intestazione rispetto al comando di CREATE TABLE
# - Salvare in CSV
#
# Preparazione file CSV
# - Trasformare la prima riga in minuscolo
# - Bonifica tutti gli spazi del file CSV sostituendo ' ,' con ','
# - Cancella tutte le righe vuote cercando la stringa ',,,,'

# Tabella docenti versionata alla data indicata
TABELLA_DOCENTI_ARGO="docenti_argo_2024_09_08"

# File CSV 
FILE_DOCENTI_ARGO_CSV="$BASE_DIR/dati_argo/docenti_argo/$TABELLA_DOCENTI_ARGO.csv"

# Creo la tabella "docenti_argo"
$SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_DOCENTI_ARGO';"
$SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_DOCENTI_ARGO' ( cognome VARCHAR(200), nome VARCHAR(200), cod_fisc VARCHAR(200), email_personale VARCHAR(200), tel VARCHAR(200), email_gsuite VARCHAR(200));"

# Importa CSV dati
$SQLITE_UTILS_CMD insert studenti.db $TABELLA_DOCENTI_ARGO $FILE_DOCENTI_ARGO_CSV --csv --empty-null

# test estrazione dati con
$SQLITE_CMD -header -table studenti.db "SELECT cognome, nome FROM $TABELLA_DOCENTI_ARGO ORDER BY cognome;"
