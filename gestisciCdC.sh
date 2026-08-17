#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_querySezioni.sh"
source "./_queryCdc.sh"

#####################
# Gestione Import   #
#####################

# File PDF da convertire e importare
FILE_CDC_ARGO_PDF="$CDC_ARGO_IMPORT_DIR/$TABELLA_CDC_ARGO.pdf"
FILE_CDC_ARGO_CSV="$CDC_ARGO_IMPORT_DIR/$TABELLA_CDC_ARGO.csv"
FILE_CDC_ARGO_IMPORT_CSV="$CDC_ARGO_IMPORT_DIR/full_$TABELLA_CDC_ARGO.csv"

add_to_map "primo_biennio_elettronica"      " "
add_to_map "primo_biennio_informatica"      " "
add_to_map "primo_biennio_meccanica"        " "
add_to_map "primo_biennio_odontotecnica"    " "
add_to_map "primo_biennio_aeronautica"      " "

add_to_map "secondo_biennio_elettronica"    " "
add_to_map "secondo_biennio_informatica"    " "
add_to_map "secondo_biennio_meccanica"      " "
add_to_map "secondo_biennio_odontotecnica"  " "
add_to_map "secondo_biennio_aeronautica"    " "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione CdC su GSuite"
    echo "-------------"
    echo "0. Cancella e ricrea la tabella CdC"
    echo "1. Converti PDF in CSV da importare"
    echo "2. Importa nella tabella i dati CdC da file CSV e normalizza"
    echo "3. Esporta i dati dei CdC in CSV, un file per ogni CdC"
    echo "4. Crea i gruppi Cdc"
    echo "5. Cancello i gruppi CdC"
    echo "6. Esporta un unico elenco docenti con classi associate in file CSV"
    echo "7. Aggiungi TUTTI i membri ai gruppi dei Cdc"
    echo " "
    echo "9. Aggiungi i NUOVI membri ai gruppi dei Cdc"
    echo " "
    echo "11. Cancella tutti i gruppi dei bienni da GSuite"
    echo "12. Crea tutti i gruppi dei bienni su GSuite"
    echo "13. Inserisci TUTTI i membri nei gruppi dei bienni"
    echo " "
    echo "15. Inserisci i NUOVI membri nei gruppi dei bienni"
    echo " "
    echo "17. Prepara EMAIL degli account studenti, da inviare ai coordinatori"
    echo "20. Esci"
}

# Funzione principale
main() {

  local querySezioni
  querySezioni="$(query::querySezioniTutte "sezione_gsuite" )"

  local query

  choice="$1"
  
  case $choice in
    0)
      echo "Cancello e ricreo la tabella $TABELLA_CDC_ARGO ..."
      
      # Cancello la tabella
      query="$(query::dropTableIfExists )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

      # Creo la tabella
      query="$(query::createTableIfNotExists )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
    ;;
    1)
      echo "Converto PDF in CSV"

      # Converto PDF in CSV (con campi mancanti)
      $PYTHON_CMD pdfTables2csv.py "$FILE_CDC_ARGO_PDF" --skip_duplicate_header --remove_newlines > "$FILE_CDC_ARGO_CSV"

      # Trasformo CSV aggiungendo i campi mancanti
      $PYTHON_CMD csvReaderUtil.py "$FILE_CDC_ARGO_CSV" > "$FILE_CDC_ARGO_IMPORT_CSV"

      echo "Generato file CSV da importare: $FILE_CDC_ARGO_IMPORT_CSV"
    ;;
    2)
      echo "Importa dati in $TABELLA_CDC_ARGO da CSV e normalizza ..."

      # Importo i dati dal file CSV
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_CDC_ARGO_IMPORT_CSV $TABELLA_CDC_ARGO"
    
      # Normalizzo i campi in tabella
      query="$(query::normalizeFields )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
    ;;
    3)
      echo "Esporta i dati dei CdC in CSV, un file per ogni CdC"

      mkdir -p "$EXPORT_DIR_DATE"
                
      while IFS="," read -r sezione_gsuite; do
        # Query dati di CdC per sezione
        local FIELDS=" DISTINCT UPPER(docente) AS docente, materie AS materia "
        local ORDERING="sezione_gsuite"
        local CDC="CDC_$sezione_gsuite"

        query="$(query::queryCdcByClass "$FIELDS" "$ORDERING" "$sezione_gsuite")"
        echo "$query"

        $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query" > "$EXPORT_DIR_DATE/$CDC.csv"
      done < <($SQLITE_CMD -csv studenti.db "$querySezioni" | sed 's/"//g' )
    ;;
    4)
      echo "Crea i gruppi CdC ..."

      while IFS="," read -r sezione_gsuite; do
        local CDC="CDC_$sezione_gsuite"

        echo "Creo gruppo $CDC ...!"
        $RUN_CMD_WITH_QUERY --command createGroup --group "$CDC" --query " NO "
      done < <($SQLITE_CMD -csv studenti.db "$querySezioni" | sed 's/"//g' )
    ;;
    5)
      echo "Cancello i gruppi CdC ..."

      while IFS="," read -r sezione_gsuite; do
        local CDC="CDC_$sezione_gsuite"

        echo "Cancello gruppo $CDC ...!"
        $RUN_CMD_WITH_QUERY --command deleteGroup --group "$CDC" --query " NO "
      done < <($SQLITE_CMD -csv studenti.db "$querySezioni" | sed 's/"//g' )
    ;;
    6)
      echo "Esporta un unico elenco docenti con classi associate in file CSV"

      local FIELDS=" DISTINCT UPPER(docente) AS docente, materie AS materia "
      local ORDERING="sezione_gsuite"
      query="$(query::queryAllCdc "$FIELDS" "$ORDERING" )"

      $SQLITE_CMD -header -csv studenti.db "$query" > "$EXPORT_DIR_DATE/docenti_con_classi_associate.csv"
    ;;
    7)
      echo "Inserisco TUTTI i membri nei gruppi dei CdC"

      local FIELDS=" 'CDC_' || sezione_gsuite AS sezione_gsuite, LOWER(email_gsuite) AS email_gsuite "
      local ORDERING="sezione_gsuite, cognome, nome"
      query="$(query::queryAllCdc "$FIELDS" "$ORDERING" )"

      $RUN_CMD_WITH_QUERY --command addMembersToGroupByMap --group " NO " --query  "$query"
    ;;
    9)
      echo "Inserisco i NUOVI membri nei gruppi dei CdC"

      local FIELDS=" 'CDC_' || sezione_gsuite AS sezione_gsuite, LOWER(email_gsuite) AS email_gsuite "
      local ORDERING="sezione_gsuite, cognome, nome"
      query="$(query::queryNewTeachers "$FIELDS" "$ORDERING" )"

      $RUN_CMD_WITH_QUERY --command addMembersToGroupByMap --group " NO " --query "$query"
    ;;
    11)
      echo "Cancella tutti i gruppi dei bienni da GSuite"

      for nome_gruppo in "${!gruppi[@]}"; do
        $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
      done
    ;;
    12)
      echo "Crea tutti i gruppi dei bienni su GSuite"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Creo gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
      done
    ;;
    13)
      echo "Inserisci TUTTI i membri nei gruppi dei bienni"

      local FIELDS=" biennio, LOWER(email_gsuite) AS email_gsuite "
      local ORDERING="sezione_gsuite, cognome, nome"
      query="$(query::queryAllCdc "$FIELDS" "$ORDERING" )"
      
      $RUN_CMD_WITH_QUERY --command addMembersToGroupByMap --group " NO " --query "$query"
    ;;
    15)
      echo "Inserisci i NUOVI membri nei gruppi dei bienni"

      local FIELDS=" biennio, LOWER(email_gsuite) AS email_gsuite "
      local ORDERING="sezione_gsuite, cognome, nome"
      query="$(query::queryNewTeachers "$FIELDS" "$ORDERING" )"
                
      $RUN_CMD_WITH_QUERY --command addMembersToGroupByMap --group " NO " --query "$query"
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
}

showConfig() {
  if log::level_is_active "CONFIG"; then
    log::_write_log "CONFIG" "Checking config - $(date --date='today' '+%Y-%m-%d %H:%M:%S')"
    log::_write_log "CONFIG" "-----------------------------------------"
    log::_write_log "CONFIG" "Current date: $CURRENT_DATE"
    log::_write_log "CONFIG" "Tabella Cdc: $TABELLA_CDC_ARGO"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "File PDF dei Cdc: $FILE_CDC_ARGO_PDF"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

# Show config vars
showConfig

if [ "$#" -eq 1 ]; then
  scelta=$1
else
  show_menu
  read -p "Scegli un'opzione (1-20): " -r scelta
fi

# Avvia la funzione principale
main "$scelta"
