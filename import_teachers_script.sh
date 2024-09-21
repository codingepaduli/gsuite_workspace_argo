#!/bin/bash

# shellcheck source=./_environment.sh
source "_environment.sh"

# Importa il file CSV "docenti_argo_YYYY_MM_DD.csv" nella
# tabella "docenti_argo_YYYY_MM_DD" del database.
#
# Contiene i dati dei docenti presenti su Argo
#
# Esempio:
# cognome,nome,data_nascita,codice_fiscale,telefono,altro_telefono,cellulare,email_personale,email_gsuite,aggiunto_il,coordinatore,sostegno
# Tizio,Caio,31/12/2024,CF_CF_CF,12345678,98765432,91827364,mail_personale,email_gsuite,2024_01_01,4Emec,SI
#
# Preparazione file Excel:
# - Controllare i campi della prima riga di intestazione rispetto al comando di CREATE TABLE
# - Salvare in CSV
#
# Preparazione file CSV
# - Trasformare la prima riga in minuscolo
# - Sostituire gli spazi in prima riga con il trattino basso "_"
# - Bonifica tutti gli spazi del file CSV sostituendo ' ,' con ','
# - Cancella tutte le righe vuote cercando la stringa ',,,,,,'

# Tabella docenti versionata alla data indicata
TABELLA_DOCENTI_ARGO="docenti_argo_2024_09_08"

# File CSV 
FILE_DOCENTI_ARGO_CSV="$BASE_DIR/dati_argo/docenti_argo/$TABELLA_DOCENTI_ARGO.csv"

# Creo la tabella "docenti_argo"
$SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_DOCENTI_ARGO';"

$SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_DOCENTI_ARGO' (cognome VARCHAR(200), nome VARCHAR(200), data_nascita VARCHAR(200), codice_fiscale VARCHAR(200), telefono VARCHAR(200), altro_telefono VARCHAR(200), cellulare VARCHAR(200), email_personale VARCHAR(200),email_gsuite VARCHAR(200), aggiunto_il VARCHAR(200), coordinatore VARCHAR(200), sostegno VARCHAR(200));"

# Importa CSV dati
$SQLITE_UTILS_CMD insert studenti.db "$TABELLA_DOCENTI_ARGO" "$FILE_DOCENTI_ARGO_CSV" --csv --empty-null

$SQLITE_CMD studenti.db "UPDATE $TABELLA_DOCENTI_ARGO 
SET codice_fiscale = TRIM(LOWER(codice_fiscale)),
    email_personale = TRIM(LOWER(email_personale)),
    cognome = TRIM(UPPER(cognome)),
    nome = TRIM(UPPER(nome)) ;"

# test estrazione dati con
$SQLITE_CMD -header -table studenti.db "SELECT cognome, nome FROM $TABELLA_DOCENTI_ARGO ORDER BY cognome;"
