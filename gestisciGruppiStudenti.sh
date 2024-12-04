#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# Tabella in cui importo i CSV
TABELLA_CSV="tabella_CSV"

# SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt') " 
# SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "

SQL_FILTRO_ANNI=" AND sz.cl IN (1) " 
# SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('idd', 'et', 'tlt') "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

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

# add_to_map "docenti" "select d.email_gsuite from docenti_2024_25 d WHERE d.email_gsuite IS NOT NULL"
# add_to_map "5b_inf_2022_23"  " NO "
# add_to_map "5a_en"   " NO "
# add_to_map "5a_et"   " NO "
# add_to_map "5a_inf"  " NO "
# add_to_map "5a_mec"  " NO "
# add_to_map "5a_od"   " NO "
# add_to_map "5b_inf"  " NO "
# add_to_map "5b_mec"  " NO "
# add_to_map "5b_od"   " NO "
# add_to_map "5c_tlc"  " NO "
# add_to_map "5d_tlc"  " NO "
# add_to_map "5f_idd"  " NO "

add_to_map "tutti" " NO "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi su GSuite"
    echo "-------------"
    echo "1. Backup gruppi specifici su CSV"
    echo "2. Creo la tabella $TABELLA_CSV dei gruppi specifici"
    echo "3. Inporta in tabella i gruppi specifici da file CSV"
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
                echo "Backup gruppi specifici su CSV"
                mkdir -p "$EXPORT_DIR_DATE"

                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo specifico $nome_gruppo su CSV...!"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
                done
                ;;
            2)
                echo "Creo la tabella dei gruppi specifici $TABELLA_CSV ..."

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_CSV' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            3)
                echo "Importa account appartenenti ai gruppi specifici nella tabella CSV"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    # Importa CSV dati
                    $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CSV" "$EXPORT_DIR_DATE/$nome_gruppo.csv" --csv --empty-null
                done
                ;;
            4)
                echo "Salva tabella gruppi specifici su file CSV..."

                mkdir -p "$EXPORT_DIR_DATE"

                $SQLITE_CMD studenti.db -header -csv "select * from $TABELLA_CSV c ORDER BY c.name;" > "$EXPORT_DIR_DATE/gruppo.csv"
                ;;
            5)
                echo "Sospendi account appartenenti ai gruppi specifici..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select d.email from $TABELLA_CSV d WHERE d.email IS NOT NULL ORDER BY d.name;"
                ;;
            6)
                echo "Cancella gruppi specifici da GSuite..."

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            7)
                echo "Cancella utenti salvati nei gruppi specifici..."

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

