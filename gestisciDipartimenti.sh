#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_queryPersonale.sh"

# Funzione per mostrare il menu
show_menu() {
  echo "Gestione Dipartimenti su GSuite"
  echo "-------------"
  echo "1. Crea tutti i gruppi dipartimento su GSuite ..."
  echo "2. Cancella tutti i gruppi dipartimento su GSuite ..."
  echo "3. Inserisci membri nei gruppi  ..."
  echo "4. Rimuovi membri dai gruppi  ..."
  echo " "
  echo "7. Aggiorna i dipartimenti con i nuovi docenti  ..."
  echo " "
  echo "20. Esci"
}

# Funzione principale
main() {
  local query

  local choice="$1"

  # local FIELDS="DISTINCT LOWER(dipartimento) AS dipartimento"
  # local ORDERING="LOWER(dipartimento)"
  # local QUERY_NOMI_DIPARTIMENTI="$(query::getEmployeesInDipartimentiAll "$FIELDS" "$ORDERING" )"
  local QUERY_NOMI_DIPARTIMENTI="$(query::getDipartimentiRaggruppatiAll )"
  $SQLITE_CMD studenti.db -header -table "$QUERY_NOMI_DIPARTIMENTI"

  # Le query del personale di ogni dipartimenti
  while IFS="," read -r dipartimento materie; do
    local FIELDS="LOWER(email_gsuite) AS email_gsuite"
    local ORDERING="LOWER(email_gsuite)"
    query="$(query::getEmployeesInDipartimentoByNomeDipartimento "$FIELDS" "$ORDERING" "$materie" )"
    add_to_map "$dipartimento" "$query"
  done < <($SQLITE_CMD -csv studenti.db "$QUERY_NOMI_DIPARTIMENTI" | sed 's/"//g' )

  echo "elenco dipartimenti e gruppi:"
  for nome_gruppo in "${!gruppi[@]}"; do
    echo " dipartimento: $nome_gruppo"
  done
  echo "    "
  
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
    7)
      echo "Aggiorna i dipartimenti con i nuovi docenti  ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Inserisco membri nel gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
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

  show_menu
  read -p "Scegli un'opzione (1-20): " -r scelta
fi

# Avvia la funzione principale
main "$scelta"
