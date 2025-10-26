#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

#####################
# Gestione Import   #
#####################

# File PDF da convertire e importare
FILE_CDC_ARGO_PDF="$BASE_DIR/dati_argo/cdc/$TABELLA_CDC_ARGO.pdf"
FILE_CDC_ARGO_CSV="$BASE_DIR/dati_argo/cdc/$TABELLA_CDC_ARGO.csv"
FILE_CDC_ARGO_IMPORT_CSV="$BASE_DIR/dati_argo/cdc/full_$TABELLA_CDC_ARGO.csv"

#####################
# Gestione CdC      #
#####################

QUERY_DOCENTI_CDC="
FROM $TABELLA_CDC_ARGO cdc
  INNER JOIN $TABELLA_SEZIONI sz
  ON cdc.classi = (sz.cl || sz.sez_argo)
  INNER JOIN $TABELLA_PERSONALE d
  ON UPPER(d.cognome || ' ' || d.nome) = UPPER(cdc.docente) 
WHERE 1=1 
  AND d.email_gsuite IS NOT NULL AND TRIM(d.email_gsuite) != '' 
  AND UPPER(d.tipo_personale) = 'DOCENTE'
"

#####################
# Gestione BIENNI   #
#####################

SQL_FILTRO_ANNI_PRIMO_BIENNIO=" AND sz.cl IN (1,2)"
SQL_FILTRO_ANNI_SECONDO_BIENNIO=" AND sz.cl IN (3,4)"

SQL_FILTRO_SEZIONI_ELETTRONICA=" AND sz.addr_argo IN ( 'en', 'et' )"
SQL_FILTRO_SEZIONI_INFORMATICA=" AND sz.addr_argo IN ( 'in', 'idd', 'tlt' )"
SQL_FILTRO_SEZIONI_MECCANICA=" AND sz.addr_argo IN ( 'm', 'mDD' )"
SQL_FILTRO_SEZIONI_ODONTOTECNICA=" AND sz.addr_argo IN ( 'od' )"
SQL_FILTRO_SEZIONI_AEREONAUTICA=" AND sz.addr_argo IN ( 'tr' )"

QUERY_DOCENTI_PRIMO_BIENNIO="SELECT DISTINCT LOWER(d.email_gsuite) $QUERY_DOCENTI_CDC $SQL_FILTRO_ANNI_PRIMO_BIENNIO"

QUERY_DOCENTI_SECONDO_BIENNIO="SELECT DISTINCT LOWER(d.email_gsuite) $QUERY_DOCENTI_CDC $SQL_FILTRO_ANNI_SECONDO_BIENNIO"

add_to_map "primo_biennio_elettronica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_ELETTRONICA ORDER BY docente"
add_to_map "primo_biennio_informatica"  " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_INFORMATICA ORDER BY docente;"
add_to_map "primo_biennio_meccanica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_MECCANICA ORDER BY docente; "
add_to_map "primo_biennio_odontotecnica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_ODONTOTECNICA ORDER BY docente; "
add_to_map "primo_biennio_aereonautica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_AEREONAUTICA ORDER BY docente; "

add_to_map "secondo_biennio_elettronica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_ELETTRONICA ORDER BY docente"
add_to_map "secondo_biennio_informatica"  " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_INFORMATICA ORDER BY docente;"
add_to_map "secondo_biennio_meccanica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_MECCANICA ORDER BY docente; "
add_to_map "secondo_biennio_odontotecnica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_ODONTOTECNICA ORDER BY docente; "
add_to_map "secondo_biennio_aereonautica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_AEREONAUTICA ORDER BY docente; "

########################
# Query sezioni        #
########################

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione CdC su GSuite"
    echo "-------------"
    echo "0. Crea la tabella CdC"
    echo "1. Converti PDF in CSV da importare"
    echo "2. Importa nella tabella i dati CdC da file CSV e normalizza"
    echo "3. Esporta i dati dei CdC in CSV, un file per ogni CdC"
    echo "4. Crea i gruppi Cdc"
    echo "5. Backup dei gruppi CdC con i relativi membri"
    echo "6. Cancello i gruppi CdC"
    echo "7. "
    echo "8. Aggiungi membri ai gruppi dei Cdc"
    echo "9. Esporta un unico elenco docenti con classi associate in file CSV"
    echo "12. Crea tutti i gruppi dei bienni su GSuite"
    echo "13. Cancella tutti i gruppi dei bienni da GSuite"
    echo "14. Inserisci membri nei gruppi dei bienni"
    echo "15. Rimuovi membri dai gruppi dei bienni"
    echo "16. Esporta gruppi dei bienni in file CSV, un file per ogni gruppo"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            0)
                echo "Cancello e ricreo la tabella $TABELLA_CDC_ARGO ..."

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "DROP TABLE IF EXISTS '$TABELLA_CDC_ARGO';"
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "
                  CREATE TABLE IF NOT EXISTS '$TABELLA_CDC_ARGO' (
                      \"Pr.\" INTEGER,
                      Docente VARCHAR(200),
                      Materie VARCHAR(200),
                      Classi VARCHAR(200) 
                  );"
                ;;
            1)
                echo "Converto PDF in CSV da importare"

                python3 pdfTables2csv.py "$FILE_CDC_ARGO_PDF" --skip_duplicate_header --remove_newlines > "$FILE_CDC_ARGO_CSV"

                python3 csvReaderUtil.py "$FILE_CDC_ARGO_CSV" > "$FILE_CDC_ARGO_IMPORT_CSV"

                echo "File CSV da importare: $FILE_CDC_ARGO_IMPORT_CSV"
                ;;
            2)
                echo "Importa dati in $TABELLA_CDC_ARGO da CSV e normalizza ..."
                
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_CDC_ARGO" "$FILE_CDC_ARGO_IMPORT_CSV" --csv --empty-null

                $SQLITE_CMD studenti.db "UPDATE $TABELLA_CDC_ARGO 
                  SET Docente = TRIM(UPPER(Docente)),
                      Materie = TRIM(UPPER(Materie)),
                      Classi = SUBSTR(Classi, 1, INSTR(Classi,' ')-1);"
                ;;
            3)
                echo "Esporta i dati dei CdC in CSV, un file per ogni CdC"

                mkdir -p "$EXPORT_DIR_DATE"
                
                while IFS="," read -r sezione_gsuite; do
                    local CDC="CDC_$sezione_gsuite"
                    
                    $SQLITE_CMD -header -csv studenti.db "
                      SELECT DISTINCT UPPER(cdc.docente) AS docente, cdc.materie AS materia
                      $QUERY_DOCENTI_CDC
                          AND sz.sezione_gsuite = '$sezione_gsuite'
                          AND UPPER(cdc.Materie) != UPPER('Educazione civica')
                          AND UPPER(cdc.Materie) != UPPER('ORIENTAMENTO')
                      ORDER BY docente;
                      " > "$EXPORT_DIR_DATE/$CDC.csv"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
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
                echo "Backup dei gruppi CdC ..."

                mkdir -p "$EXPORT_DIR_DATE"

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
                echo "Inserisco i membri nei gruppi dei CdC"

                local -A gruppi_cdc

                while IFS="," read -r sezione_gsuite; do
                    # SELECT d.email_gsuite, d.codice_fiscale, cdc.docente, cdc.classi, sz.sezione_gsuite 
                    gruppi_cdc[$sezione_gsuite]="
                      SELECT DISTINCT LOWER(d.email_gsuite)
                      $QUERY_DOCENTI_CDC
                          AND sz.sezione_gsuite = '$sezione_gsuite'
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
                SELECT DISTINCT LOWER(d.email_gsuite), UPPER(d.codice_fiscale), 
                    UPPER(cdc.docente), cdc.classi, sz.sezione_gsuite 
                $$QUERY_DOCENTI_CDC
                  -- AND sz.sezione_gsuite = '3A_inf'
                  -- AND cdc.materie != UPPER('Educazione civica')
                ORDER BY docente;
                " > "$EXPORT_DIR_DATE/docenti_con_classi_associate.csv"
                ;;
            12)
                echo "Crea tutti i gruppi dei bienni su GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            13)
                echo "Cancella tutti i gruppi dei bienni da GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            14)
                echo "Inserisci membri nei gruppi dei bienni"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"
                  $SQLITE_CMD studenti.db "${gruppi[$nome_gruppo]}"

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            15)
                echo "Rimuovi membri dai gruppi dei bienni"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            16)
                echo "Esporta gruppi dei bienni in file CSV, un file per ogni gruppo"

                mkdir -p "$EXPORT_DIR_DATE"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  $SQLITE_CMD -header -csv studenti.db "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo"
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
        read -p "Premi Invio per continuare..." -r _
    done
}

# Avvia la funzione principale
main

