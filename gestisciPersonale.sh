#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_queryPersonale.sh"

# Aggiunge gli insegnanti a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con personale versionata alla data indicata
FILE_PERSONALE_CSV="$PERSONALE_ARGO_IMPORT_DIR/$TABELLA_PERSONALE.csv"

# Funzione per mostrare il menu
show_menu() {
  echo "Gestione tabelle Personale"
  echo "-------------"
  echo "1. Cancello e ricreo la tabella del personale"
  echo "2. Importo e normalizzo i dati dal file CSV"
  echo "3. Visualizza personale neo-assunto"
  echo "4. Genero su DB la mail ai nuovi docenti"
  echo "5. Genero su DB la mail al nuovo personale ATA"
  echo "6. Esporto il nuovo personale in file CSV"
  echo "7. Visualizza personale della tabella precedente non incluso in quella attuale"
  echo "8. Importa nella tabella attuale il personale della tabella precedente NON CANCELLATO E non incluso in quella attuale"
  echo "9. Crea il nuovo personale su GSuite"
  echo "10. Aggiungo i nuovi docenti su Classroom"
  echo "12. Crea script personale_CF.sh"
  echo "13. Sospendi (disabilita) personale"
  echo "14. Elimina personale"
  echo "15. Visualizza personale da cancellare ..."
  echo "17. Sposta script personale_CF.sh relativo alla tabella precedente in root"
  echo "19. Controllo i dati"
  echo "20. Esci"
}

# Funzione principale
main() {
  local query

  if ! checkAllVarsNotEmpty "TABELLA_PERSONALE" "PERIODO_PERSONALE_DA" "PERIODO_PERSONALE_A" ; then
    echo "Errore: Definisci le variabili nel file di configurazione." >&2
    exit 1  # Termina lo script con codice di stato 1
  fi

  local choice="$1"
        
  case $choice in
    1)
      echo "1. Cancello e ricreo la tabella del personale"
      
      # Cancello la tabella
      query="$(query::dropTableIfExists )"
      $SQLITE_CMD studenti.db "$query"

      # Creo la tabella
      query="$(query::createTableIfNotExists )"
      $SQLITE_CMD studenti.db "$query"
    ;;
    2)
      echo "2. Importo e normalizzo i dati dal file CSV $FILE_PERSONALE_CSV ..."

      $LIBREOFFICE_CMD --convert-to csv --outdir "$PERSONALE_ARGO_IMPORT_DIR" "$PERSONALE_ARGO_IMPORT_DIR/$TABELLA_PERSONALE.xls"

      # Rimuovo tutte le righe vuote del file
      sed -i '/^[[:space:]]*$/d' "$FILE_PERSONALE_CSV"

      # Aggiungo due campi nel file
      # sed -i 's/$/,,/' "$FILE_PERSONALE_CSV"
        
      # Importa CSV dati
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_PERSONALE_CSV $TABELLA_PERSONALE"

      # Normalizza dati
      query="$(query::normalizeFields )"
      $SQLITE_CMD studenti.db "$query"
      
      # Normalizza birthday
      query="$(query::normalizeBirthDate )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

      # Normalizza date
      query="$(query::normalizeInsertDate )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

      # Normalizza date
      query="$(query::normalizeRetiredDate )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
    ;;
    3)
      echo "Personale neo-assunto ancora senza email:"
      query="$(query::getEmployeesNonDeletedWithoutEmailGSuite )"
      $SQLITE_CMD studenti.db -header -table "$query"

      echo "Personale neo-assunto con email creata:"
      local FIELDS="LOWER(tipo_personale) as tipo, 
        UPPER(cognome) as cognome, UPPER(nome) as nome, 
        LOWER(email_personale) as email_personale, 
        LOWER(email_gsuite) as email_gsuite, aggiunto_il"
      local ORDERING="UPPER(cognome)"
      query="$(query::getEmployeesNotDeletedAddedInPeriod "$FIELDS" "$ORDERING")"
      $SQLITE_CMD studenti.db -header -table "$query"
    ;;
    4)
      checkAllVarsNotEmpty "DOMAIN" "CURRENT_DATE"

      echo "Genero su DB la mail ai nuovi docenti ..."
      query="$(query::createEmailTeachers )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
    ;;
    5)
      checkAllVarsNotEmpty "DOMAIN" "CURRENT_DATE"

      echo "Genero su DB la mail al nuovo personale ATA ..."
      
      query="$(query::createEmailATA )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
    ;;
    6)
      checkAllVarsNotEmpty "PASSWORD_CLASSROOM"

      mkdir -p "$EXPORT_DIR_DATE"
      echo "Esporto il nuovo personale in file CSV ..."
      
      local FIELDS="LOWER(email_gsuite) as email_gsuite, '$PASSWORD_CLASSROOM' as password, LOWER(tipo_personale) as tipo_personale, aggiunto_il as aggiunto_il, UPPER(cognome) as cognome, UPPER(nome) as nome, UPPER(codice_fiscale) as codice_fiscale, cellulare, LOWER(email_personale) as email_personale"
      local ORDERING="UPPER(cognome)"
      query="$(query::getEmployeesNotDeletedAddedInPeriod "$FIELDS" "$ORDERING" )"
      $SQLITE_CMD studenti.db -header -csv "$query" > "$EXPORT_DIR_DATE/nuovo_personale.csv"
    ;;
    7)
      echo "7. Visualizza personale della tabella precedente non incluso in quella attuale"

      # Creo la query di tutti i codici fiscali
      local FIELDS="group_concat(quote(LOWER(codice_fiscale)), ',') AS codice_fiscale"
      query="$(query::getQueryEmployeesDefaultValues "$FIELDS")"

      local $cfArrayString="$($SQLITE_CMD studenti.db -csv "$query")"

      ## Creo la query del personale della vecchia tabella
      ## i cui codici fiscali non si trovano nella nuova tabella
      local FIELDS="LOWER(tipo_personale) AS tipo, UPPER(cognome) AS cognome, 
          UPPER(nome) AS nome, UPPER(codice_fiscale) AS codice_fiscale, 
          LOWER(email_gsuite) AS email_gsuite, cancellato_il "
      local ORDERING=" UPPER(codice_fiscale) "

      query="$(query::getQueryOldEmployeesCfNotIn "$FIELDS" "$ORDERING" "$cfArrayString")"

      $SQLITE_CMD studenti.db -header -table  "$query"
    ;;
    8)
      echo "8. Importa nella tabella attuale il personale della tabella precedente NON CANCELLATO E non incluso in quella attuale"

      # Creo la query di tutti i codici fiscali
      local FIELDS="group_concat(quote(LOWER(codice_fiscale)), ',') AS codice_fiscale"
      query="$(query::getQueryEmployeesDefaultValues "$FIELDS")"

      local $cfArrayString="$($SQLITE_CMD studenti.db -csv "$query")"

      ## Creo la query del personale della vecchia tabella
      ## i cui codici fiscali non si trovano nella nuova tabella
      local FIELDS=" * "
      local ORDERING=" UPPER(codice_fiscale) "
      query="$(query::getQueryOldEmployeesCfNotIn "$FIELDS" "$ORDERING" "$cfArrayString")"

      ## Eseguo l'import a partire dalla query
      $SQLITE_CMD studenti.db -header -table  "INSERT INTO $TABELLA_PERSONALE $query"
    ;;
    9)
      checkAllVarsNotEmpty "GSUITE_OU_DOCENTI" "GSUITE_OU_ATA" "PASSWORD_CLASSROOM"
      
      echo "Crea il nuovo personale su GSuite ..."

      local FIELDS="LOWER(email_gsuite), UPPER(cognome), UPPER(nome), UPPER(codice_fiscale), LOWER(email_personale), cellulare, '$PASSWORD_CLASSROOM'"
      local ORDERING=" UPPER(cognome) "
      query="$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING")"
      $RUN_CMD_WITH_QUERY --command createUsers --group "$GSUITE_OU_DOCENTI" --query "$query"

      query="$(query::getAtaNotDeletedAddedInPeriod "$FIELDS")"
      $RUN_CMD_WITH_QUERY --command createUsers --group "$GSUITE_OU_ATA" --query "$query"
    ;;
    10)
      checkAllVarsNotEmpty "GRUPPO_CLASSROOM"
      
      echo "Aggiungo i nuovi docenti su Classroom ..."
      
      local FIELDS="LOWER(email_gsuite)"
      local ORDERING=" UPPER(cognome) "
      query="$(query::getTeachersNotDeletedAddedInPeriod "$FIELDS" "$ORDERING")"
      $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_CLASSROOM" --query "$query"
    ;;
    12)
      checkAllVarsNotEmpty "CURRENT_DATE"

      # Preparo query estrazione del personale
      local FIELDS="LOWER(tipo_personale), LOWER(email_gsuite), UPPER(codice_fiscale), UPPER(cognome), UPPER(nome), aggiunto_il, cancellato_il, UPPER(contratto), UPPER(dipartimento), note"
      local ORDERING="UPPER(codice_fiscale)"
      
      query="$(query::getQueryEmployeesDefaultValues "$FIELDS" "$ORDERING")"

      # Creo lo script con i dati della query
      mkdir -p "$EXPORT_DIR_DATE"
      echo "Crea script $TABELLA_PERSONALE.sh e $TABELLA_PERSONALE_PRECEDENTE.sh ..."

      {
        echo "#!/bin/bash" 
        echo 'source "_environment.sh"'
        echo 'source "_environment_working_tables.sh"'
        echo " "
      } | tee "$EXPORT_DIR_DATE/$TABELLA_PERSONALE.sh" "$EXPORT_DIR_DATE/$TABELLA_PERSONALE_PRECEDENTE.sh"

      while IFS="," read -r tipo_personale email_gsuite codice_fiscale cognome nome aggiunto cancellato contratto dipartimento note; do

        # Aggiungo il CF negli script
        echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_PERSONALE SET email_gsuite = LOWER('$email_gsuite'), aggiunto_il = '$aggiunto', cancellato_il = '$cancellato', contratto = UPPER('$contratto'), dipartimento = UPPER('$dipartimento'), note = '$note' WHERE UPPER(codice_fiscale) = UPPER('$codice_fiscale')\" # $cognome $nome $tipo_personale;" >> "$EXPORT_DIR_DATE/$TABELLA_PERSONALE.sh"

      done < <($SQLITE_CMD -csv studenti.db "$query" | sed "s/\"//g")

      query="$(query::getQueryEmployeesDefaultValues "$FIELDS" "$ORDERING" "$TABELLA_PERSONALE_PRECEDENTE")"

      while IFS="," read -r tipo_personale email_gsuite codice_fiscale cognome nome aggiunto cancellato contratto dipartimento note; do

        # Aggiungo il CF negli script
        echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_PERSONALE SET email_gsuite = LOWER('$email_gsuite'), aggiunto_il = '$aggiunto', cancellato_il = '$cancellato', contratto = UPPER('$contratto'), dipartimento = UPPER('$dipartimento'), note = '$note' WHERE UPPER(codice_fiscale) = UPPER('$codice_fiscale')\" # $cognome $nome $tipo_personale;" >> "$EXPORT_DIR_DATE/$TABELLA_PERSONALE_PRECEDENTE.sh"

      done < <($SQLITE_CMD -csv studenti.db "$query" | sed "s/\"//g")
    ;;
    15)
      echo "Visualizza personale da cancellare ..."

      local FIELDS="LOWER(tipo_personale) AS tipo_personale, LOWER(email_gsuite) AS email_gsuite, UPPER(codice_fiscale) AS codice_fiscale, UPPER(cognome) AS cognome, UPPER(nome) AS nome, aggiunto_il, cancellato_il, UPPER(contratto) AS contratto, note"
      local ORDERING="UPPER(codice_fiscale)"
      query="$(query::getEmployeesWithEmailGSuiteDeletedInPeriod "$FIELDS" "$ORDERING" )"

      $SQLITE_CMD studenti.db -header -table "$query"
    ;;
    13)
      echo "Sospendi (disabilita) personale ..."

      local FIELDS="LOWER(tipo_personale), LOWER(email_gsuite), UPPER(codice_fiscale), UPPER(cognome), UPPER(nome), aggiunto_il, cancellato_il, UPPER(contratto), UPPER(dipartimento), note"
      local ORDERING="UPPER(codice_fiscale)"

      query="$(query::getEmployeesWithEmailGSuiteDeletedInPeriod "$FIELDS" "$ORDERING")"

      $SQLITE_CMD -csv studenti.db "$query" 

      # $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "$query"
    ;;
    14)
      echo "Cancella personale ..."

      local FIELDS="LOWER(tipo_personale), LOWER(email_gsuite), UPPER(codice_fiscale), UPPER(cognome), UPPER(nome), aggiunto_il, cancellato_il, UPPER(contratto), UPPER(dipartimento), note"
      local ORDERING="UPPER(codice_fiscale)"

      query="$(query::getEmployeesWithEmailGSuiteDeletedInPeriod "$FIELDS" "$ORDERING")"

      $SQLITE_CMD -csv studenti.db "$query" 

      # $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "$query"
    ;;
    17)
      cp "$EXPORT_DIR_DATE/$TABELLA_PERSONALE_PRECEDENTE.sh" "$BASE_DIR/$TABELLA_PERSONALE.sh" 
      chmod +x "$BASE_DIR/$TABELLA_PERSONALE.sh"

      # run the script
      echo "Eseguo script aggiornamento email" 
      "$BASE_DIR/$TABELLA_PERSONALE.sh"
    ;;
    19)
      echo "Controllo i dati"

      echo "Codici fiscali duplicati"
      query="$(query::getDuplicatedCF )"
      $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

      echo "email duplicate"
      query="$(query::getDuplicatedEmail )"
      $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "$query"
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
    log::_write_log "CONFIG" "Tabella personale precedente per confronto: $TABELLA_PERSONALE_PRECEDENTE"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_PERSONALE_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_PERSONALE_A"
    log::_write_log "CONFIG" "Dominio: $DOMAIN"
    log::_write_log "CONFIG" "Gruppo Classroom: $GRUPPO_CLASSROOM"
    log::_write_log "CONFIG" "Password Classroom: $PASSWORD_CLASSROOM"
    log::_write_log "CONFIG" "File personale CSV: $FILE_PERSONALE_CSV"
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
