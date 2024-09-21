#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Tabella docenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_09_20"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
# SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt') " 
# SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "

SQL_FILTRO_ANNI=" AND sz.cl IN (1) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('idd', 'et', 'tlt') "

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
    echo "1. Crea gruppi docenti su GSuite"
    echo "2. Backup gruppi docenti GSuite su CSV"
    echo "3. Cancella gruppi docenti su GSuite"
    echo "4. Aggiungi membri docenti da query"
    echo "5. Cancella membri docenti da query"
    echo "6. Crea gruppi studenti"
    echo "7. Cancella gruppi studenti"
    echo "8. Backup gruppi studenti su CSV"
    echo "9. Aggiungi membri a gruppi studenti"
    echo "10. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-10): " choice
        
        case $choice in
            1)
                echo "creo i gruppi..."
                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            2)
                echo "Backup gruppi..."
                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
                done
                ;;
            3)
                echo "Cancello i gruppi..."
                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            4)
                echo "Aggiungo membri ai gruppi ..."
                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            5)
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Cancello membri al gruppo $nome_gruppo ...!"
                    $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            6)
                while IFS="," read -r sezione_gsuite; do
                    echo "Creo gruppo $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite" | sed 's/"//g' )
                ;;
            7)
                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello gruppo $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite" | sed 's/"//g' )
                ;;
            8)
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_argo
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND sa.email_argo IS NOT NULL
                                  ORDER BY sa.email_argo"
                done < <($SQLITE_CMD -csv studenti.db "SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite" | sed 's/"//g' )

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
                done < <($SQLITE_CMD -csv studenti.db "SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}"
                done
                ;;
            10)
                echo "Arrivederci!"
                exit 0
                ;;
            *)
                echo "Opzione non valida. Per favore, scegli un numero tra 1 e 10."
                sleep 1
                ;;
        esac
        
        # Pausa per permettere all'utente di leggere il risultato
        read -p "Premi Invio per continuare..." dummy
    done
}

# Avvia la funzione principale
main

