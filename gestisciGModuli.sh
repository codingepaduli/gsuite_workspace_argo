#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# Tabella in cui importo le risposte di Google Moduli da CSV
TABELLA_GMODULI="GModuli"

# File CSV_GMODULI
NOME_FILE_CSV_GMODULI="1_AsseMatematico_quinta (Risposte)"
FILE_CSV_GMODULI="$BASE_DIR/dati_argo/gmoduli/$NOME_FILE_CSV_GMODULI.csv"

# Mappa (array associativo)
declare -A gruppi

# Funzione per aggiungere elementi alla mappa
add_to_map() {
    local key=$1
    local value=$2
    gruppi[$key]=$value
}

# Funzione per ottenere un valore dalla mappa
get_from_map() {
    local key=$1
    echo "${gruppi[$key]}"
}

# Funzione per rimuovere un elemento dalla mappa
remove_from_map() {
    local key=$1
    unset "gruppi[$key]"
}

## comuni
add_to_map "inf"   " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('in', 'idd')"
add_to_map "mec"  " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('m')"
add_to_map "od"  " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('od')"
add_to_map "aer"  " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('tr')"

## BIENNIO
# add_to_map "en"   " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('en')"

## TRIENNIO
add_to_map "et"   " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('et')"
add_to_map "tlc"  " select * FROM $TABELLA_GMODULI sa WHERE sa.addr_argo in ('tlt')"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione risposte di Google Moduli "
    echo "-------------"
    echo "1. Importa un file CSV di risposte di GModuli"
    echo "2. Ricava classe e sezione dalle mail e aggiorna tabella"
    echo "3. Esporta CSV suddivisi per gruppi"
    echo "4. "
    echo "5. "
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Importa un file CSV di risposte di GModuli"

                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_GMODULI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_GMODULI' (data  VARCHAR(200), email_gsuite VARCHAR(200), punteggio VARCHAR(200), D1 VARCHAR(200), D2 VARCHAR(200), D3 VARCHAR(200), D4 VARCHAR(200), D5 VARCHAR(200), D6 VARCHAR(200), D7 VARCHAR(200), D8 VARCHAR(200), D9 VARCHAR(200), D10 VARCHAR(200), D11 VARCHAR(200), D12 VARCHAR(200), D13 VARCHAR(200), D14 VARCHAR(200), D15 VARCHAR(200), D16 VARCHAR(200), D17 VARCHAR(200), D18 VARCHAR(200), D19 VARCHAR(200), D20 VARCHAR(200), D21 VARCHAR(200), D22 VARCHAR(200), D23 VARCHAR(200), D24 VARCHAR(200), D25 VARCHAR(200), D26 VARCHAR(200), D27 VARCHAR(200), D28 VARCHAR(200), D29 VARCHAR(200), D30 VARCHAR(200));"

                # Aggiungo le due colonne per classe e sezione
                $SQLITE_CMD studenti.db "ALTER TABLE $TABELLA_GMODULI ADD COLUMN cl NUMERIC;"
                $SQLITE_CMD studenti.db "ALTER TABLE $TABELLA_GMODULI ADD COLUMN sez VARCHAR(200);"
                $SQLITE_CMD studenti.db "ALTER TABLE $TABELLA_GMODULI ADD COLUMN addr_argo VARCHAR(200);"
                $SQLITE_CMD studenti.db "ALTER TABLE $TABELLA_GMODULI ADD COLUMN sezione_gsuite VARCHAR(200);"

                # Importa CSV dati
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_GMODULI" "$FILE_CSV_GMODULI" --csv --empty-null
                ;;
            2)
                echo "Ricava classe e sezione dalle mail e aggiorna tabella"

                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GMODULI 
                    SET cl = classe,
                    sez = sez_argo,
                    addr_argo = indirizzo,
                    sezione_gsuite = sez_gsuite
                    FROM (
                      SELECT 
                        sa.email_gsuite as email, 
                        sa.cl as classe, 
                        sa.sez as sez_argo,
                        sz.addr_argo as indirizzo,
                        sz.sezione_gsuite as sez_gsuite
                      FROM $TABELLA_STUDENTI sa 
                      INNER JOIN $TABELLA_SEZIONI sz 
                      ON sa.sez = sz.sez_argo AND sa.cl =sz.cl
                    ) as studenti 
                    WHERE LOWER(studenti.email) = LOWER(email_gsuite)"
                ;;
            3)
                echo "3. Esporta CSV suddivisi per gruppi"

                mkdir -p "$EXPORT_DIR_DATE"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "$nome_gruppo" "${gruppi[$nome_gruppo]}"
                    $SQLITE_CMD studenti.db -header -csv "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$NOME_FILE_CSV_GMODULI-$nome_gruppo.csv"
                done
                ;;
            20)
                echo "Arrivederci!"
                exit 0
                ;;
            *)
                echo "Opzione non valida. Per favore, scegli un numero tra 1 e 20."
                sleep 1
                ;;
        esac
        
        # Pausa per permettere all'utente di leggere il risultato
        read -p "Premi Invio per continuare..." dummy
    done
}

# Avvia la funzione principale
main

