#!/bin/bash

# shellcheck source=./_environment.sh
source "_environment.sh"

# Importa il file CSV "sezioni_YYYY_YY.csv"
#
# Associa classe e sezione di Argo con il nome della sezione su GSuite
# 
# Esempio:
# +----+--------+-----------+----------+------------+----------------+
# | cl | letter | addr_argo | sez_argo | sez_gsuite | sezione_gsuite |
# +----+--------+-----------+----------+------------+----------------+
# | 1  | A      | en        | Aen      | A_en       | 1A_en          |
# | 1  | A      | in        | Ain      | A_inf      | 1A_inf         |

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# File CSV sezioni.csv
FILE_CSV_SEZIONI="$BASE_DIR/dati_argo/$TABELLA_SEZIONI.csv"

# Ricreo la tabella Argo "sezioni" 
# TODO replace sezione_gsuite with classe_gsuite
$SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_SEZIONI';"
$SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_SEZIONI' (cl NUMERIC, letter VARCHAR(200), addr_argo VARCHAR(200), sez_argo VARCHAR(200), sez_gsuite VARCHAR(200), sezione_gsuite VARCHAR(200));"

# Importa il file CSV nella tabella sezioni
## --skip 1: se la tabella esiste, non importa la prima riga del file CSV
#$SQLITE_CMD studenti.db ".import --csv --skip 1 $FILE_CSV_SEZIONI sezioni"

# Importa il file CSV nella tabella sezioni
$SQLITE_UTILS_CMD insert studenti.db $TABELLA_SEZIONI  "$FILE_CSV_SEZIONI"  --csv --empty-null

# Esporta il file sezioni_2023_24.csv
$SQLITE_CMD -header -table studenti.db "SELECT DISTINCT cl, letter, addr_argo, sez_argo, sez_gsuite, sezione_gsuite FROM $TABELLA_SEZIONI ORDER BY cl, sez_argo" # > "$TABELLA_SEZIONI.csv"
