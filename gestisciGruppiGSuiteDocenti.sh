#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

##########################################################################
# Progettato per gestire il personale, non per CdC, non per dipartimenti # 
##########################################################################

# Gruppo insegnanti
GRUPPO_DOCENTI="docenti_volta"

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# Funzione per mostrare il menu
show_menu() {
  echo "Gestione gruppi GSuite del personale:"
  echo "-------------"
  echo "1. Aggiungi tutti i membri ai gruppi GSuite"
  echo "3. Visualizza nuovo personale da aggiungere ai gruppi GSuite"
  echo "4. Aggiungi nuovo personale ai gruppi GSuite"
  echo "18. Crea i gruppi su GSuite ..."
  echo "19. Cancella i gruppi GSuite ..."
  echo "20. Esci"
}

# Funzione principale
main() {
  local choice="$1"

  case $choice in
    1)
      echo "Aggiungi tutti i membri ai gruppi GSuite ..."

      local FIELDS="LOWER(email_gsuite) AS email_gsuite"
      local ORDERING="LOWER(email_gsuite)"

      add_to_map "$GRUPPO_DOCENTI" "$(query::getTeachersWithEmailNotDeleted "$FIELDS" "$ORDERING" )"
      add_to_map "$GRUPPO_CLASSROOM" "$(query::getTeachersWithEmailNotDeleted "$FIELDS" "$ORDERING" )"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Creo gruppo $nome_gruppo su GSuite...!"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    3)
      echo "Visualizza nuovo personale da aggiungere ai gruppi GSuite"
      
      local FIELDS="LOWER(tipo_personale) as tipo, UPPER(cognome) as cognome, 
                UPPER(nome) as nome, LOWER(email_personale) as email_personale, 
                LOWER(email_gsuite) as email_gsuite"
      local ORDERING="LOWER(email_gsuite)"

      add_to_map "$GRUPPO_DOCENTI" "$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING" )"
      add_to_map "$GRUPPO_CLASSROOM" "$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING" )"

      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Nuovo personale da aggiungere al gruppo $nome_gruppo "
        $RUN_CMD_WITH_QUERY --command executeQuery --group " /* NO */ " --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    4)
      echo "Aggiungi nuovo personale ai gruppi GSuite"

      local FIELDS="LOWER(email_gsuite) AS email_gsuite"
      local ORDERING="LOWER(email_gsuite)"

      add_to_map "$GRUPPO_DOCENTI" "$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING" )"
      add_to_map "$GRUPPO_CLASSROOM" "$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING" )"

      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Nuovo personale da aggiungere al gruppo $nome_gruppo "
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
      done
    ;;
    18)
      echo "Crea i gruppi su GSuite"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Creo gruppo $nome_gruppo su GSuite"
        $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
      done
    ;;
    19)
      echo "Cancella i gruppi GSuite"
      
      for nome_gruppo in "${!gruppi[@]}"; do
        echo "Cancello gruppo $nome_gruppo da GSuite"
        # $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
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
    log::_write_log "CONFIG" "Gruppo Classroom: $GRUPPO_CLASSROOM"
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
