#!/bin/bash

# shellcheck source=./_environment.sh
source "_environment.sh"

# Importa il file CSV "studenti_argo_YYYY_MM_DD.csv" nella
# tabella "studenti_argo_YYYY_MM_DD" del database.
#
# Contiene i dati degli studenti presenti su Argo
#
# Esempio:
# cognome,nome,cod_fisc,cl,sez,e_mail,email_pa,email_ma,email_gen,e_mail_argo
# Tizio,Caio,CF_CF_CF,1,Z,mail@mail,mail_pa@mail,mail_ma@mail,mail_gen@mail
#
# Preparazione file Excel:
# - Controllare i campi della prima riga di intestazione rispetto al comando di CREATE TABLE
# - Aggiungere la colonna "e_mail_argo"
# - Salvare in CSV
#
# Preparazione file CSV
# - Trasformare la prima riga in minuscolo
# - Bonifica tutti gli spazi del file CSV sostituendo ' ,' con ','
# - Cancella tutte le righe vuote cercando la stringa ',,,,,,,,,'

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_09_06"

# File CSV 
FILE_CSV_STUDENTI="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI.csv"

# Creo la tabella "studenti_argo"
$SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_STUDENTI';"
$SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_STUDENTI' ( cognome VARCHAR(200), nome VARCHAR(200), cod_fisc VARCHAR(200), cl NUMERIC, sez VARCHAR(200), e_mail VARCHAR(200), email_pa VARCHAR(200), email_ma VARCHAR(200), email_gen VARCHAR(200), matricola VARCHAR(200), codicesidi VARCHAR(200), datan VARCHAR(200), ritira VARCHAR(200), datar VARCHAR(200), email_argo VARCHAR(200));"

# Importa CSV dati
$SQLITE_UTILS_CMD insert studenti.db $TABELLA_STUDENTI $FILE_CSV_STUDENTI --csv --empty-null

# test estrazione dati con
$SQLITE_CMD -header -table studenti.db "SELECT cl, sez, cognome, nome FROM $TABELLA_STUDENTI ORDER BY cl, sez;"
