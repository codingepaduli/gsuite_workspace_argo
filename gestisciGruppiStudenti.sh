#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_09_20"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# Tabella docenti per anno
TABELLA_DOCENTI="docenti_2024_25"

# Tabella CdC versionata alla data indicata
TABELLA_CDC="Cdc_2024_09_20"

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
add_to_map "test_coo" "select d.email_gsuite from docenti_2024_25 d WHERE d.email_gsuite IS NOT NULL AND d.coordinatore IS NOT NULL"
add_to_map "sostegno" "select d.email_gsuite from docenti_2024_25 d WHERE d.email_gsuite IS NOT NULL AND d.sostegno IS NOT NULL "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi su GSuite"
    echo "-------------"
    echo "1. "
    echo "2. "
    echo "3. "
    echo "4. "
    echo "5. "
    echo "6. "
    echo "7. Cancella gruppi studenti"
    echo "8. Backup gruppi studenti su CSV"
    echo "9. Aggiungi membri a gruppi studenti"
    echo "10. Crea gruppi CdC"
    echo "11. Cancella gruppi CdC"
    echo "12. Aggiungi membri a gruppi CdC"
    echo "13. Backup gruppi CdC su CSV"
    echo "14. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-14): " choice
        
        case $choice in
            6)
                while IFS="," read -r sezione_gsuite; do
                    echo "Creo gruppo $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            7)
                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello gruppo $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            8)
                mkdir -p "$EXPORT_DIR_DATE"
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_argo
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND sa.email_argo IS NOT NULL
                                  ORDER BY sa.email_argo"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
                done
                ;;
            9)
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_argo
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND sa.email_argo IS NOT NULL
                                  ORDER BY sa.email_argo"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}"
                done
                ;;
            10)
                while IFS="," read -r sezione_gsuite; do
                    echo "Creo gruppo CDC_$sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "CDC_$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            11)
                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello gruppo CDC_$sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "CDC_$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            12)
                declare -A gruppi_cdc

                while IFS="," read -r sezione_gsuite; do
                    # SELECT d.email_gsuite, d.codice_fiscale, cdc.docente, cdc.classi, sz.sezione_gsuite 
                    gruppi_cdc[$sezione_gsuite]="SELECT DISTINCT d.email_gsuite
                      FROM $TABELLA_CDC cdc
                        INNER JOIN $TABELLA_SEZIONI sz
                        ON cdc.classi = (sz.cl || sz.sez_argo)
                        INNER JOIN $TABELLA_DOCENTI d
                        ON (d.cognome || ' ' || d.nome) = cdc.docente 
                      WHERE d.email_gsuite is NOT NULL AND d.email_gsuite != '' AND sz.sezione_gsuite = '$sezione_gsuite'
                      ORDER BY docente;"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_cdc[@]}"; do
                    echo creo gruppo "CDC_$nome_gruppo" "${gruppi_cdc[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "CDC_$nome_gruppo" --query "${gruppi_cdc[$nome_gruppo]}"
                done
                ;;
            13)
                mkdir -p "$EXPORT_DIR_DATE"
                declare -A gruppi_cdc

                while IFS="," read -r sezione_gsuite; do
                    # SELECT d.email_gsuite, d.codice_fiscale, cdc.docente, cdc.classi, sz.sezione_gsuite 
                    gruppi_cdc[$sezione_gsuite]="SELECT DISTINCT d.email_gsuite
                      FROM $TABELLA_CDC cdc
                        INNER JOIN $TABELLA_SEZIONI sz
                        ON cdc.classi = (sz.cl || sz.sez_argo)
                        INNER JOIN $TABELLA_DOCENTI d
                        ON (d.cognome || ' ' || d.nome) = cdc.docente 
                      WHERE d.email_gsuite is NOT NULL AND d.email_gsuite != '' AND sz.sezione_gsuite = '$sezione_gsuite'
                      ORDER BY docente;"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_cdc[@]}"; do
                    echo salvo CSV gruppo "CDC_$nome_gruppo" "${gruppi_cdc[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "CDC_$nome_gruppo" --query "${gruppi_cdc[$nome_gruppo]}" > "$EXPORT_DIR_DATE/CDC_$nome_gruppo.csv"
                done
                ;;
            14)
                echo "Arrivederci!"
                exit 0
                ;;
            *)
                echo "Opzione non valida. Per favore, scegli un numero tra 1 e 14."
                sleep 1
                ;;
        esac
        
        # Pausa per permettere all'utente di leggere il risultato
        read -p "Premi Invio per continuare..." dummy
    done
}

# Avvia la funzione principale
main
