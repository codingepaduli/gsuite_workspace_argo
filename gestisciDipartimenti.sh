#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_queryPersonale.sh"

declare -A queryAnagrafica
declare -A queryNewTeachers
declare QUERY_NOMI_DIPARTIMENTI

# Funzione per mostrare il menu
show_menu() {
  echo "Gestione Dipartimenti su GSuite"
  echo "-------------"
  echo "1. Crea tutti i gruppi dipartimento su GSuite ..."
  echo "2. Cancella tutti i gruppi dipartimento su GSuite ..."
  echo "3. Inserisci membri nei gruppi  ..."
  echo "4. Rimuovi membri dai gruppi  ..."
  echo "5. Esporta i dipartimenti in CSV e XLSX  ..."
  echo " "
  echo "7. Aggiorna i dipartimenti con i nuovi docenti  ..."
  echo "8. Invia email ai coordinatori di dipartimento"
  echo "20. Esci"
}

# Funzione principale
main() {
  local query
  
  local choice="$1"

  case $choice in
    1)
      echo "Crea tutti i gruppi dipartimento su GSuite ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Creo gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " /* NO */ "
      done
    ;;
    2)
      echo "Cancella tutti i gruppi dipartimento su GSuite ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Cancello gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " /* NO */ "
      done
    ;;
    3)
      echo "Inserisci membri nei gruppi  ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Inserisco membri nel gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    4)
      echo "Rimuovi membri dai gruppi  ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Rimuovo membri dal gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    5)
      echo "Esporta i dipartimenti in CSV e XLSX  ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Esporto dipartimento $nome_gruppo ..."

        $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "${queryAnagrafica[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
        $LIBREOFFICE_CMD --convert-to xlsx --outdir "$EXPORT_DIR_DATE" "$EXPORT_DIR_DATE/$nome_gruppo.csv"
      done
    ;;
    7)
      echo "Aggiorna i dipartimenti con i nuovi docenti  ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Inserisco membri nel gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${queryNewTeachers[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${queryNewTeachers[$nome_gruppo]}"
      done
    ;;
    8)
      echo "8. Invia i dipartimenti ai coordinatori di dipartimento"
    
      local FIELDS="dipartimento"
      local ORDERING="dipartimento"
      local NOMI_DIPARTIMENTI="$(query::getDipartimentiRaggruppatiAll "$FIELDS" "$ORDERING" )"
      
      declare -a dipartimenti
      readarray -t dipartimenti < <( $SQLITE_CMD studenti.db "$NOMI_DIPARTIMENTI" )

      local TO="gsuite_supporto@$DOMAIN"
      local CC="gsuite_supporto@$DOMAIN" # supporto_digitale@$DOMAIN
      local SUBJECT="Elenco dipartimenti"
      local MESSAGE="
          \n Salve,
          \n in allegato l'elenco dei dipartimenti
          \n Eventuali segnalazioni di imprecisioni o problematiche possono essere inoltrate a supporto_digitale@$DOMAIN .
          \n Cordiali saluti"
          
      $GAM_CMD sendemail  to "$TO" cc "$CC" subject "$SUBJECT" message "$MESSAGE" attach "$EXPORT_DIR_DATE/${dipartimenti[0]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[1]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[2]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[3]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[4]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[5]}.xlsx" attach "$EXPORT_DIR_DATE/${dipartimenti[6]}.xlsx"  attach "$EXPORT_DIR_DATE/${dipartimenti[7]}.xlsx"
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

inizializzaDiparitmenti() {
  local query

  # local FIELDS="DISTINCT LOWER(dipartimento) AS dipartimento"
  # local ORDERING="LOWER(dipartimento)"
  # local QUERY_NOMI_DIPARTIMENTI="$(query::getEmployeesInDipartimentiAll "$FIELDS" "$ORDERING" )"
  local QUERY_NOMI_DIPARTIMENTI="$(query::getDipartimentiRaggruppatiAll )"
  $SQLITE_CMD studenti.db -header -table "$QUERY_NOMI_DIPARTIMENTI"

  # Qquery del personale di ogni dipartimenti
  while IFS="," read -r dipartimento materie; do
    local FIELDS="LOWER(email_gsuite) AS email_gsuite"
    local ORDERING="LOWER(email_gsuite)"
    query="$(query::getEmployeesInDipartimentoByNomeDipartimento "$FIELDS" "$ORDERING" "$materie" )"
    add_to_map "$dipartimento" "$query"
    query="$(query::getNewEmployeesInDipartimentoByNomeDipartimento "$FIELDS" "$ORDERING" "$materie" )"
    queryNewTeachers[$dipartimento]="$query"

    local FIELDS="UPPER(cognome) as cognome, UPPER(nome) as nome, LOWER(email_gsuite) AS email_gsuite"
    local ORDERING="LOWER(email_gsuite)"
    query="$(query::getEmployeesInDipartimentoByNomeDipartimento "$FIELDS" "$ORDERING" "$materie" )"
    queryAnagrafica[$dipartimento]="$query"
  done < <($SQLITE_CMD -csv studenti.db "$QUERY_NOMI_DIPARTIMENTI" | sed 's/"//g' )
}

showConfig() {
  if log::level_is_active "CONFIG"; then
    log::_write_log "CONFIG" "Checking config - $(date --date='today' '+%Y-%m-%d %H:%M:%S')"
    log::_write_log "CONFIG" "-----------------------------------------"
    log::_write_log "CONFIG" "Current date: $CURRENT_DATE"
    log::_write_log "CONFIG" "Tabella personale: $TABELLA_PERSONALE"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_PERSONALE_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_PERSONALE_A"
    log::_write_log "CONFIG" "Dominio: $DOMAIN"
    log::_write_log "CONFIG" "Password Classroom: $PASSWORD_CLASSROOM"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

if [ "$#" -eq 1 ]; then
  scelta="$1"
else
  # Show config vars
  showConfig
  inizializzaDiparitmenti

  show_menu
  read -p "Scegli un'opzione (1-20): " -r scelta
fi

# Avvia la funzione principale
main "$scelta"
