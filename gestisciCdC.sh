#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# File CSV da importare
FILE_CDC_ARGO_CSV="$BASE_DIR/dati_argo/Cdc/$TABELLA_CDC_ARGO.csv"

# SQL_FILTRO_ANNI=" AND sz.cl IN (1) " 
# SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione CdC su GSuite"
    echo "-------------"
    echo "1. Crea la tabella CdC"
    echo "2. Importa nella tabella i dati CdC da file CSV e normalizza"
    echo "3. Visualizzo i dati dei CdC"
    echo "4. Crea i gruppi Cdc"
    echo "5. Backup dei gruppi CdC con i relativi membri"
    echo "6. Cancello i gruppi CdC"
    echo "7. "
    echo "8. Aggiungi membri ai gruppi Cdc"
    echo "9. Esporta un unico elenco docenti con classi associate in file CSV"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Creo la tabella $TABELLA_CDC_ARGO ..."
                
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_CDC_ARGO' (docente VARCHAR(200), materie  VARCHAR(200), classi VARCHAR(200));"
                ;;
            2)
                echo "Importa dati in $TABELLA_CDC_ARGO da CSV e normalizza ..."
                
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CDC_ARGO" "$FILE_CDC_ARGO_CSV" --csv --empty-null

                $SQLITE_CMD studenti.db "UPDATE $TABELLA_CDC_ARGO 
                  SET docente = TRIM(UPPER(docente)),
                      materie = TRIM(UPPER(materie)),
                      classi = SUBSTR(classi, 1, INSTR(classi,' ')-1);"
                ;;
            3)
                echo "Visualizzo i dati dei CdC ..."
                
                # test estrazione dati con
                $SQLITE_CMD -header -table studenti.db "SELECT DISTINCT docente, classi FROM $TABELLA_CDC_ARGO ORDER BY docente;"
                ;;
            4)
                echo "Crea i gruppi CdC ..."

                while IFS="," read -r sezione_gsuite; do
                    local CDC="CDC_$sezione_gsuite"

                    echo "Creo gruppo $CDC ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$CDC" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            5)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Backup dei gruppi CdC ..."

                while IFS="," read -r sezione_gsuite; do
                    local CDC="CDC_$sezione_gsuite"

                    echo "Backup gruppo $CDC ...!"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$CDC" --query " NO " > "$EXPORT_DIR_DATE/$CDC.csv"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            6)
                echo "Cancello i gruppi CdC ..."

                while IFS="," read -r sezione_gsuite; do
                    local CDC="CDC_$sezione_gsuite"

                    echo "Cancello gruppo $CDC ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$CDC" --query " NO "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            8)
                declare -A gruppi_cdc
                echo "Inserisco i membri nei gruppi CdC ..."

                while IFS="," read -r sezione_gsuite; do
                    # SELECT d.email_gsuite, d.codice_fiscale, cdc.docente, cdc.classi, sz.sezione_gsuite 
                    gruppi_cdc[$sezione_gsuite]="SELECT DISTINCT d.email_gsuite
                      FROM $TABELLA_CDC_ARGO cdc
                        INNER JOIN $TABELLA_SEZIONI sz
                        ON cdc.classi = (sz.cl || sz.sez_argo)
                        INNER JOIN $TABELLA_PERSONALE d
                        ON (d.cognome || ' ' || d.nome) = cdc.docente 
                      WHERE d.email_gsuite is NOT NULL AND d.email_gsuite != '' AND d.tipo_personale = 'docente' AND sz.sezione_gsuite = '$sezione_gsuite'
                      ORDER BY docente;"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_cdc[@]}"; do
                    local CDC="CDC_$nome_gruppo"

                    echo creo gruppo "$CDC" "${gruppi_cdc[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$CDC" --query "${gruppi_cdc[$nome_gruppo]}"
                done
                ;;
            9)
                echo "Esporta un unico elenco docenti con classi associate in file CSV"

                # test estrazione dati con
                $SQLITE_CMD -header -csv studenti.db "
                SELECT DISTINCT d.email_gsuite, d.codice_fiscale, cdc.docente, 
                  cdc.classi, sz.sezione_gsuite 
                FROM $TABELLA_CDC_ARGO cdc
                INNER JOIN $TABELLA_SEZIONI sz
                ON cdc.classi = (sz.cl || sz.sez_argo)
                INNER JOIN $TABELLA_PERSONALE d
                ON (d.cognome || ' ' || d.nome) = cdc.docente 
                WHERE d.email_gsuite is not null
                  AND d.email_gsuite != '' 
                  AND d.tipo_personale = 'docente' 
                  -- AND sz.sezione_gsuite = '3A_inf'
                  -- AND cdc.materie != UPPER('Educazione civica')
                ORDER BY docente;
                " > "$EXPORT_DIR_DATE/docenti_con_classi_associate.csv"
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
        read -p "Premi Invio per continuare..." _
    done
}

# Avvia la funzione principale
main

