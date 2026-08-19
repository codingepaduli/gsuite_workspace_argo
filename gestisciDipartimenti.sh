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

  local FIELDS="DISTINCT LOWER(dipartimento) AS dipartimento"
  local ORDERING="LOWER(dipartimento)"
  local QUERY_NOMI_DIPARTIMENTI="$(query::getEmployeesInDipartimentiAll "$FIELDS" "$ORDERING" )"

  $SQLITE_CMD studenti.db -header -table "$QUERY_NOMI_DIPARTIMENTI"

  # Le query del personale di ogni dipartimenti
  while IFS="," read -r dipartimento; do
    FIELDS="LOWER(email_gsuite) AS email_gsuite"
    ORDERING="LOWER(email_gsuite)"
    query="$(query::getEmployeesInDipartimentoByNomeDipartimento "$FIELDS" "$ORDERING" " '$dipartimento' " )"
    add_to_map "$dipartimento" "$query"
  done < <($SQLITE_CMD -csv studenti.db "$QUERY_NOMI_DIPARTIMENTI" | sed 's/"//g' )

  #####################################################################
  # PERSONALE_ATA - gestito a parte perché il nome non deve essere
  # 'dipartimento_personale_ata' ma solo 'personale_ata'
  local DIPARTIMENTO_PERSONALE_ATA='personale_ata'
  local QUERY_PERSONALE_ATA=$(get_from_map "$DIPARTIMENTO_PERSONALE_ATA")
  remove_from_map "$DIPARTIMENTO_PERSONALE_ATA"
  #####################################################################

  echo "elenco dipartimenti:"
  echo "    "
  echo "    personale_ata ------------ gestione separata ------------"
  for nome_gruppo in "${!gruppi[@]}"; do
    echo " dipartimento $nome_gruppo"
  done
  echo "    "
  
  case $choice in
    1)
      echo "Crea tutti i gruppi dipartimento su GSuite ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Creo gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command createGroup --group "dipartimento_$nome_gruppo" --query " /* NO */ "
      done

      echo "Creo gruppo $DIPARTIMENTO_PERSONALE_ATA su GSuite...!"
      $RUN_CMD_WITH_QUERY --command createGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query " /* NO */ "
    ;;
    2)
      echo "Cancella tutti i gruppi dipartimento su GSuite ..."
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Cancello gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command deleteGroup --group "dipartimento_$nome_gruppo" --query " /* NO */ "
      done

      echo "Cancello gruppo $DIPARTIMENTO_PERSONALE_ATA su GSuite...!"
      $RUN_CMD_WITH_QUERY --command deleteGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query " /* NO */ "
    ;;
    3)
      echo "Inserisci membri nei gruppi  ..."

      $SQLITE_CMD -csv -table studenti.db "$QUERY_PERSONALE_ATA"
      $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "$QUERY_PERSONALE_ATA;"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Inserisco membri nel gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "dipartimento_$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    4)
      echo "Rimuovi membri dai gruppi  ..."

      $SQLITE_CMD -csv -table studenti.db "$QUERY_PERSONALE_ATA"
      $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "${QUERY_PERSONALE_ATA}"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Rimuovo membri dal gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "dipartimento_$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    7)
      echo "Aggiorna i dipartimenti con i nuovi docenti  ..."

      $SQLITE_CMD -csv -table studenti.db "$QUERY_PERSONALE_ATA"
      $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "${QUERY_PERSONALE_ATA}"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Inserisco membri nel gruppo $nome_gruppo ..."

        $SQLITE_CMD -csv -table studenti.db "${gruppi[$nome_gruppo]}"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "dipartimento_$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
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
