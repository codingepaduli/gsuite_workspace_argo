#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_queryStudenti.sh"

# File CSV 
FILE_CSV_STUDENTI="$STUDENTI_ARGO_IMPORT_DIR/$TABELLA_STUDENTI.csv"
FILE_CSV_STUDENTI_SERALE="$STUDENTI_ARGO_IMPORT_DIR/$TABELLA_STUDENTI_SERALE.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella Studenti"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "0. Cancello e ricreo la tabella studenti DIURNO"
    echo "1. Importo e normalizzo i dati del DIURNO"
    echo "2. Visualizza dati in tabella"
    echo "3. Visualizza nuovi studenti"
    echo "4. Creo la mail ai nuovi studenti"
    echo "5. Esporto i nuovi studenti in file CSV"
    echo "6. Creo il nuovi studenti su GSuite"
    echo "7. Crea script studenti_CF.sh"
    echo "8. Sospendi studenti"
    echo "9. Cancella studenti"
    echo "10. Sposta script studenti_CF.sh relativo alla tabella precedente in root"
    echo "11. "
    echo "12. Cancello e ricreo la tabella studenti SERALE"
    echo "13. Importo e normalizzo i dati del SERALE"
    echo "14. Copio i dati del SERALE nella tabella del DIURNO, unificando la gestione"
    echo "15. "
    echo "16. Controlla codici fiscali duplicati"
    echo "17. Controlla email gsuite duplicate"
    echo "20. Esci"
}

# Funzione principale
main() {
    local query

    if ! checkAllVarsNotEmpty "DOMAIN" "TABELLA_STUDENTI" "TABELLA_STUDENTI_SERALE" "CURRENT_DATE"; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    choice="$1"
        
        case $choice in
            0)
              echo "Cancello e ricreo la tabella studenti $TABELLA_STUDENTI ..."
                
              # Cancello la tabella
              query="$(query::dropTableIfExists )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              # Creo la tabella
              query="$(query::createTableIfNotExists )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            ;;
            1)
              echo "Importo e normalizzo i dati dal file CSV $FILE_CSV_STUDENTI ..."

              $LIBREOFFICE_CMD --convert-to csv --outdir "$STUDENTI_ARGO_IMPORT_DIR" "$STUDENTI_ARGO_IMPORT_DIR/$TABELLA_STUDENTI.xls"

              # Rimuovo tutte le righe vuote del file
              sed -i '/^[[:space:]]*$/d' "$FILE_CSV_STUDENTI"

              # Aggiungo due campi nel file
              sed -i 's/$/,,/' "$FILE_CSV_STUDENTI"

              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_CSV_STUDENTI $TABELLA_STUDENTI"
              
              echo "Normalizzo i campi"
              query="$(query::normalizeFields )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Date errate"
              query="$(query:checkWrongDate )";
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
              
              echo "Normalizzo data nascita"
              query="$(query::normalizeBirthDate )";
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
                
              echo "Normalizzo data ritiro"
              query="$(query::normalizeRetiredDate )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Normalizzo email"
              query="$(query::normalizeEmailGSuite )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Normalizzo inserimenti"
              query="$(query::normalizeInsertDate )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            ;;
            2)
              echo "Visualizza dati in tabella ..."

              local FIELDS="sz.sezione_gsuite, cognome || ' ' || nome AS nome, email_gsuite"
              local ORDERING="sz.sezione_gsuite"
              query="$(query::queryStudentiTutti "$FIELDS" "$ORDERING" )"

              $SQLITE_CMD -header -table studenti.db "$query"
            ;;
            3)
              local FIELDS="sz.sezione_gsuite AS classe, cognome || ' ' || nome AS nome, aggiunto_il, datar AS data_ritiro, matricola, email_gsuite"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              query="$(query::queryStudentiSenzaEmail "$FIELDS" "$ORDERING" )"
              $SQLITE_CMD studenti.db -header -table "$query"

              echo "Studenti iscritti nel periodo"

              query="$(query::queryStudentiNonCancellatiIscrittiInPeriodo "$FIELDS" "$ORDERING" )"
              $SQLITE_CMD studenti.db -header -table "$query"
            ;;
            4)
              echo "Creo la mail ai nuovi studenti ..."
                
              # creo le mail del diurno
              query="$(query::creaUsernameDiurno )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              # creo le mail del serale
              query="$(query::creaUsernameSerale )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            ;;
            5)
              mkdir -p "$EXPORT_DIR_DATE"
              echo "Esporto i nuovi studenti in file CSV ..."

              local FIELDS="sz.sezione_gsuite AS classe, cognome || ' ' || nome AS nome, email_gsuite, '$PASSWORD_STUDENTI' as password"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              local query
              query="$(query::queryStudentiNonCancellatiIscrittiInPeriodo "$FIELDS" "$ORDERING" )"
              $SQLITE_CMD studenti.db -header -csv "$query" > "$EXPORT_DIR_DATE/nuovi_studenti_tutti.csv"

              $LIBREOFFICE_CMD --convert-to xlsx --outdir "$EXPORT_DIR_DATE" "$EXPORT_DIR_DATE/nuovi_studenti_tutti.csv"

              for classe in {1..5}
              do
                query="$(query::queryStudentiDellAnnoNonCancellatiIscrittiInPeriodo "$FIELDS" "$ORDERING" "$classe" )"
                
                $SQLITE_CMD studenti.db -header -csv "$query" > "$EXPORT_DIR_DATE/nuovi_studenti_classi_$classe.csv"

                $LIBREOFFICE_CMD --convert-to xlsx --outdir "$EXPORT_DIR_DATE" "$EXPORT_DIR_DATE/nuovi_studenti_classi_$classe.csv"
              done
            ;;
            6)
              echo "Creo i nuovi studenti su GSuite ..."

              local FIELDS="email_gsuite, cognome, nome, cod_fisc, ' ', ' ', '$PASSWORD_STUDENTI'"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              local query
              query="$(query::queryStudentiDiurnoNonCancellatiIscrittiInPeriodo "$FIELDS" "$ORDERING" )"
              $RUN_CMD_WITH_QUERY --command createUsers --group "Studenti/Diurno" --query "$query"
              
              local query
              query="$(query::queryStudentiSeraleNonCancellatiIscrittiInPeriodo "$FIELDS" "$ORDERING" )"
              $RUN_CMD_WITH_QUERY --command createUsers --group "Studenti/Serale" --query "$query"
            ;;
            7)
              mkdir -p "$EXPORT_DIR_DATE"
              echo "Crea script $TABELLA_STUDENTI.sh e $TABELLA_STUDENTI_PRECEDENTE.sh ..."

              local FIELDS="LOWER(email_gsuite) AS email_gsuite, UPPER(cod_fisc) AS cod_fisc, UPPER(cognome) AS cognome, UPPER(nome) AS nome, sz.cl, sz.sez_argo"
              local ORDERING=" UPPER(cod_fisc) "
              local query
              query="$(query::queryStudentiTutti "$FIELDS" "$ORDERING" )"
              
              local queryStudentiPrecedenti
              queryStudentiPrecedenti="$(query::queryStudentiPrecedentiTutti "$FIELDS" "$ORDERING" )"
                
              echo "#!/bin/bash" | tee "$EXPORT_DIR_DATE/$TABELLA_STUDENTI.sh" "$EXPORT_DIR_DATE/$TABELLA_STUDENTI_PRECEDENTE.sh"
              echo 'source "_environment.sh"' | tee -a "$EXPORT_DIR_DATE/$TABELLA_STUDENTI.sh" "$EXPORT_DIR_DATE/$TABELLA_STUDENTI_PRECEDENTE.sh"
              echo 'source "_environment_working_tables.sh"' | tee -a "$EXPORT_DIR_DATE/$TABELLA_STUDENTI.sh" "$EXPORT_DIR_DATE/$TABELLA_STUDENTI_PRECEDENTE.sh"

              # Tabella CF corrente
              while IFS="," read -r email_gsuite cod_fisc cognome nome cl sez; do
                # Aggiungo il CF negli script
                echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI SET email_gsuite = LOWER('$email_gsuite') WHERE UPPER(cod_fisc) = UPPER('$cod_fisc')\" # $cognome $nome $cl $sez;" >> "$EXPORT_DIR_DATE/$TABELLA_STUDENTI.sh"
              done < <($SQLITE_CMD -csv studenti.db "$query" | sed "s/\"//g")

              # Tabella CF precedente
              while IFS="," read -r email_gsuite cod_fisc cognome nome cl sez; do
                # Aggiungo il CF negli script
                echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI SET email_gsuite = LOWER('$email_gsuite') WHERE UPPER(cod_fisc) = UPPER('$cod_fisc')\" # $cognome $nome $cl $sez;" >> "$EXPORT_DIR_DATE/$TABELLA_STUDENTI_PRECEDENTE.sh"
              done < <($SQLITE_CMD -csv studenti.db "$queryStudentiPrecedenti" | sed "s/\"//g")
            ;;
            8)
              echo "Sospendi account studenti ..."

              local FIELDS="LOWER(email_gsuite)"
              local ORDERING="sz.sezione_gsuite, cognome, nome"
              local query
              query="$(query::queryStudentiCancellatiInPeriodo "$FIELDS" "$ORDERING" )"

              $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "$query"
            ;;
            9)
              echo "Cancella account studenti ..."

              local FIELDS="LOWER(email_gsuite)"
              local ORDERING="sz.sezione_gsuite, cognome, nome"
              local query
              query="$(query::queryStudentiCancellatiInPeriodo "$FIELDS" "$ORDERING" )"

              $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "$query"
            ;;
            10)
              echo "Sposta script studenti_CF.sh relativo alla tabella precedente in root"
              cp "$EXPORT_DIR_DATE/$TABELLA_STUDENTI_PRECEDENTE.sh" "$BASE_DIR/$TABELLA_STUDENTI.sh" 
              chmod +x "$BASE_DIR/$TABELLA_STUDENTI.sh"

              # run the script
              echo "Eseguo script aggiornamento email" 
              "$BASE_DIR/$TABELLA_STUDENTI.sh"
            ;;
            12)
              echo "Cancello e ricreo la tabella studenti $TABELLA_STUDENTI_SERALE ..."
                
              # Cancello la tabella
              query="$(query::dropTableIfExists "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              # Creo la tabella
              query="$(query::createTableIfNotExists "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            ;;
            13)
              echo "Importo e normalizzo i dati dal file CSV $FILE_CSV_STUDENTI_SERALE ..."

              $LIBREOFFICE_CMD --convert-to csv --outdir "$STUDENTI_ARGO_IMPORT_DIR" "$STUDENTI_ARGO_IMPORT_DIR/$TABELLA_STUDENTI_SERALE.xls"

              # Rimuovo tutte le righe vuote del file
              sed -i '/^[[:space:]]*$/d' "$FILE_CSV_STUDENTI_SERALE"

              # Aggiungo due campi nel file
              sed -i 's/$/,,/' "$FILE_CSV_STUDENTI_SERALE"

              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_CSV_STUDENTI_SERALE $TABELLA_STUDENTI_SERALE"

              echo "Normalizzo i campi"
              query="$(query::normalizeFields "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              query="$(query::normalizeSirioSection )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Date errate"
              query="$(query:checkWrongDate "$TABELLA_STUDENTI_SERALE")";
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Normalizzo data nascita"
              query="$(query::normalizeBirthDate "$TABELLA_STUDENTI_SERALE")";
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Normalizzo data ritiro"
              query="$(query::normalizeRetiredDate "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"

              echo "Normalizzo email"
              query="$(query::normalizeEmailGSuite "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            
              echo "Normalizzo inserimenti"
              query="$(query::normalizeInsertDate "$TABELLA_STUDENTI_SERALE" )"
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$query"
            ;;
            14)
              echo "Copio i dati dalla tabella $TABELLA_STUDENTI_SERALE nella tabella $TABELLA_STUDENTI ..."

              local FIELDS="cognome, nome, cod_fisc, e_mail, email_pa, email_ma, email_gen, matricola, codicesidi, datan, ritira, datar, email_gsuite, aggiunto_il"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              local query
              query="$(query::queryStudentiTabellaSeraleTutti "$FIELDS, sz.cl, sz.sez_argo " "$ORDERING" )"
                
              # Copio i dati del serale nella tabella del diurno
              # unificando i dati ed il processo di gestione
              $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "INSERT INTO $TABELLA_STUDENTI ( $FIELDS, cl, sez ) $query"
            ;;
            16)
              echo "Controllo eventuali codici fiscali duplicati:"

              local query
              query="$(query::cfStudentiDuplicati )"

              ## Salvo in un array i CF risultanti della query
              local -a cfArray
              readarray -t cfArray < <($SQLITE_CMD studenti.db -csv "$query" )

              ## Scrivo l'array (a, b, c) come stringa 'a', 'b', 'c',
              local COD_FISC_IN
              printf -v COD_FISC_IN "'%s', " "${cfArray[@]}"

              ## Tolgo l'ultima virgola e l'ultimo spazio ", "
              COD_FISC_IN=${COD_FISC_IN%, }

              local FIELDS="cognome, nome, cod_fisc, sz.cl, sz.sez_argo, datar"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              query="$(query::studentiByCF "$FIELDS" "$ORDERING" "$COD_FISC_IN")"
              $SQLITE_CMD studenti.db -header -table "$query"
            ;;
            17)
              echo "Controllo eventuali email GSuite duplicate:"
              
              local query
              query="$(query::emailStudentiDuplicati )"

              ## Salvo in un array le email risultanti della query
              local -a emailArray
              readarray -t emailArray < <($SQLITE_CMD studenti.db -csv "$query" )

              ## Scrivo l'array (a, b, c) come stringa 'a', 'b', 'c',
              local EMAIL_GSUITE_IN
              printf -v EMAIL_GSUITE_IN "'%s', " "${emailArray[@]}"

              ## Tolgo l'ultima virgola e l'ultimo spazio ", "
              EMAIL_GSUITE_IN="${EMAIL_GSUITE_IN%, }"

              local FIELDS="cognome, nome, cod_fisc, sz.cl, sz.sez_argo, datar, email_gsuite"
              local ORDERING="sz.sezione_gsuite, cognome, nome"

              query="$(query::studentiByEmailGSuite "$FIELDS" "$ORDERING" "$EMAIL_GSUITE_IN")"

              $SQLITE_CMD studenti.db -header -table "$query"
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
    log::_write_log "CONFIG" "Tabella studenti diurno: $TABELLA_STUDENTI"
    log::_write_log "CONFIG" "Tabella studenti serale: $TABELLA_STUDENTI_SERALE"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "File CVS studenti diurno: $FILE_CSV_STUDENTI"
    log::_write_log "CONFIG" "File CVS studenti serale: $FILE_CSV_STUDENTI_SERALE"
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
