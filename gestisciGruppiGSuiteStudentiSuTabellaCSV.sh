#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 
FILE_CSV="$BASE_DIR/dati_argo/tabellaCSV/tabellaCSV_20241223.csv"

SQL_FILTRO_ANNI=" AND sz.cl IN (1) " 
# SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "
# SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('idd', 'et', 'tlt') "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# add_to_map "5b_inf_2022_23"  " NO "
# add_to_map "5a_en"   " NO "
# add_to_map "5a_et"   " NO "
add_to_map "5a_inf"  " NO "
# add_to_map "5a_mec"  " NO "
# add_to_map "5a_od"   " NO "
# add_to_map "5b_inf"  " NO "
# add_to_map "5b_mec"  " NO "
# add_to_map "5b_od"   " NO "
# add_to_map "5c_tlc"  " NO "
# add_to_map "5d_tlc"  " NO "
# add_to_map "5f_idd"  " NO "

# Importa il file CSV dei docenti (da workspace) e seleziona 
# # quelli che non esistono in tabella personale_argo
# add_to_map "docenti_esportati_da_cancellare" "
# SELECT csv.email
# FROM tabella_CSV csv 
# WHERE SUBSTR(csv.email, 1, 2) = 'd.'
# AND csv.email NOT IN (
#     SELECT pa.email_gsuite
#     FROM personale_argo_2024_11_28 pa
#     WHERE pa.tipo_personale = 'docente' 
# )"

# add_to_map "tutti" "
# SELECT d.email 
# FROM $TABELLA_CSV d 
# WHERE d.email IS NOT NULL 
# ORDER BY d.name"

# add_to_map "tutti" " NO "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di GSuite su tabella CSV"
    echo "-------------"
    echo "1. Creo la tabella $TABELLA_CSV"
    echo "2. Inporta in tabella i gruppi GSuite"
    echo "3. Importa singolo file CSV nella tabella CSV"
    echo "11. Importa account nella tabella CSV da singolo file"
    echo "4. Salva tabella gruppi specifici su file CSV"
    echo "5. Sospendi utenti dei gruppi specifici"
    echo "6. Cancella gruppi specifici"
    echo "7. Cancella utenti salvati nei gruppi specifici..."

    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Creo la tabella $TABELLA_CSV ..."

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_CSV' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            2)
                echo "Inporta in tabella i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " | $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CSV" - --csv --empty-null
                done
                ;;
            3)
                echo "Importa singolo file CSV nella tabella CSV"
                
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CSV" "$FILE_CSV" --csv --empty-null
                ;;
            5)
                echo "Sospendi account presenti nella tabella CSV"

                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "$nome_gruppo"
                  echo "${gruppi[$nome_gruppo]}"
                  # $RUN_CMD_WITH_QUERY --command suspendUsers --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]};"
                done
                ;;
            6)
                echo "Cancella account presenti nella tabella CSV"

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            7)
                echo "Cancella account presenti nella tabella CSV"

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email from $TABELLA_CSV d WHERE d.email IS NOT NULL ORDER BY d.name;"
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

