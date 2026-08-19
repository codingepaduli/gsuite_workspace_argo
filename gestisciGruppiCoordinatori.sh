#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_queryCoordinatori.sh"

declare -A GRUPPO_COORDINATORI
GRUPPO_COORDINATORI[0]="coordinatori"
GRUPPO_COORDINATORI[1]="coordinatori_prime"
GRUPPO_COORDINATORI[2]="coordinatori_seconde"
GRUPPO_COORDINATORI[3]="coordinatori_terze"
GRUPPO_COORDINATORI[4]="coordinatori_quarte"
GRUPPO_COORDINATORI[5]="coordinatori_quinte"

# Funzione per mostrare il menu
show_menu() {
  echo "Gestione Coordinatori"
  echo "-------------"
  echo "2. Crea tutti i gruppi coordinatori da GSuite"
  echo "3. Cancella tutti i gruppi coordinatori su GSuite ..."
  echo "4. "
  echo "5. Visualizza coordinatori con classi associate"
  echo "6. Salva coordinatori con classi associate su CSV"
  echo "7. Esporta script di backup dei coordinatori"
  echo "8. Inserisci membri nei gruppi  ..."
  echo "9. Rimuovi membri dai gruppi  ..."
  echo "20. Esci"
}

# Funzione principale
main() {
  local query

  local choice="$1"
  
  case $choice in
    2)
      echo "Crea tutti i gruppi coordinatori su GSuite ..."
      
      for i in {1..5}; do 
        echo "Creo gruppo ${GRUPPI_COORDINATORI[$i]} su GSuite...!"
        $RUN_CMD_WITH_QUERY --command createGroup --group "${GRUPPI_COORDINATORI[$i]}" --query " NO "
      done
    ;;
    3)
      echo "Cancella tutti i gruppi coordinatori su GSuite ..."
      
      for i in {1..5}; do 
        echo "Cancello gruppo ${GRUPPI_COORDINATORI[$i]} su GSuite...!"
        $RUN_CMD_WITH_QUERY --command deleteGroup --group "${GRUPPI_COORDINATORI[$i]}" --query " NO "
      done
    ;;
    5)
      echo "Visualizza coordinatori con classi associate"

      local FIELDS="UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
        LOWER(sz.email_coordinatore) as email_coordinatore, 
        UPPER(cognome) AS cognome, UPPER(nome) AS nome"
      local ORDERING="UPPER(sezione_gsuite)"
      query="$(query::getSezioniConCoordinatori "$FIELDS" "$ORDERING")"
      
      $SQLITE_CMD studenti.db -header -table "$query"
    ;;
    6)
      echo "6. Salva $GRUPPO_COORDINATORI con classi associate su CSV"

      mkdir -p "$EXPORT_DIR_DATE"

      local FIELDS="UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
        LOWER(sz.email_coordinatore) as email_coordinatore, 
        UPPER(cognome) AS cognome, UPPER(nome) AS nome"
      local ORDERING="UPPER(sezione_gsuite)"
      query="$(query::getSezioniConCoordinatori "$FIELDS" "$ORDERING")"
      
      $SQLITE_CMD studenti.db -header -csv "$query" > "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.csv"

      $LIBREOFFICE_CMD --convert-to xlsx --outdir "$EXPORT_DIR_DATE" "$EXPORT_DIR_DATE/coordinatori_${CURRENT_DATE}.csv"
    ;;
    7)
      echo "7. Esporta script di backup dei coordinatori"

      mkdir -p "$EXPORT_DIR_DATE"

      local FIELDS="UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
        LOWER(sz.email_coordinatore) as email_coordinatore, 
        UPPER(cognome) AS cognome, UPPER(nome) AS nome"
      local ORDERING="UPPER(sezione_gsuite)"
      query="$(query::getSezioniConCoordinatori "$FIELDS" "$ORDERING")"

      {
        echo "#!/bin/bash"
        echo 'source "_environment.sh"'
        echo 'source "_environment_working_tables.sh"'
        echo 'source "./_maps.sh"'
        echo " "
      } > "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.sh"
      
      while IFS="," read -r sezione_gsuite email_coordinatore cognome nome; do
        {
          echo '$SQLITE_CMD studenti.db -csv "'
          echo 'UPDATE $TABELLA_SEZIONI'
          echo "SET email_coordinatore='$email_coordinatore'"
          echo "WHERE sezione_gsuite='$sezione_gsuite'; -- $cognome $nome"
          echo '"'
        } >> "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.sh"
      done < <($SQLITE_CMD studenti.db -csv "$query" | sed "s/\"//g")
    ;;
    8)
      echo "Inserisci membri nei gruppi  ..."

      local FIELDS=" DISTINCT LOWER(email_coordinatore) as email_coordinatore "
      local ORDERING="LOWER(email_coordinatore)"

      # genero le query
      for i in {1..5}; do
        echo "Inserisco membri nel gruppo ${GRUPPI_COORDINATORI[$i]} ..."

        query="$(query::getSezioniConCoordinatoriByAnno "$FIELDS" "$ORDERING" "$i")"
        $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "${GRUPPI_COORDINATORI[$i]}" --query "$query"
      done
    ;;
    9)
      echo "Rimuovi membri dai gruppi  ..."

      local FIELDS=" DISTINCT LOWER(email_coordinatore) as email_coordinatore "
      local ORDERING="LOWER(email_coordinatore)"
      
      for i in {1..5}; do
        echo "Rimuovo membri dal gruppo ${GRUPPI_COORDINATORI[$i]} ..."

        query="$(query::getSezioniConCoordinatoriByAnno "$FIELDS" "$ORDERING" "$i")"
        $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "${GRUPPI_COORDINATORI[$i]}" --query "$query"
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
    log::_write_log "CONFIG" "Tabella sezioni: $TABELLA_SEZIONI"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_PERSONALE_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_PERSONALE_A"
    log::_write_log "CONFIG" "Dominio: $DOMAIN"
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
