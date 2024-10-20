#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_10_14"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt') " 
# SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "

SQL_FILTRO_ANNI=" AND sz.cl IN (5) " 
# SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('idd', 'et', 'tlt') "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi su GSuite"
    echo "-------------"
    echo "1. Crea le classi su GSUITE (solo classi, senza studenti)"
    echo "2. Cancella le classi da GSUITE"
    echo "3. Backup delle classi su CSV"
    echo "4. Aggiungi studenti alle classi"
    echo "5. Aggiungi nuovi utenti alle classi ?"

    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Crea le classi su GSUITE (solo classi, senza studenti)"

                while IFS="," read -r sezione_gsuite; do
                    echo "Creo classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            2)
                echo "Cancello le classi da GSUITE"

                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$sezione_gsuite" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            3)
                echo "3. Backup delle classi su CSV"

                mkdir -p "$EXPORT_DIR_DATE"
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_gsuite
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND sa.email_gsuite IS NOT NULL
                                  ORDER BY sa.email_gsuite"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
                done
                ;;
            5)
                echo "Aggiungo studenti alle classi"

                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_gsuite
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND sa.email_gsuite IS NOT NULL
                                  ORDER BY sa.email_gsuite"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}"
                done
                ;;
            10)
                echo "Da implementare ?..."

                # $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email from $TABELLA_CSV d WHERE d.email IS NOT NULL ORDER BY d.name;"
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

