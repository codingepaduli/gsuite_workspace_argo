#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"
source "./_query.sh"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella sezioni $TABELLA_SEZIONI"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "1. Crea tabella sezioni a partire dai dati degli studenti"
    echo "2. Crea dati delle sezioni"
    echo "3. Visualizza sezioni"
    echo "4. Esporto le sezioni in file CSV"
    echo ""
    echo "6. Invia elenco classi ai coordinatori"
    echo " "
    echo "20. Esci"
}

# Funzione principale
main() {

    if ! checkAllVarsNotEmpty "TABELLA_STUDENTI" "TABELLA_SEZIONI"; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    choice="$1"
        
        case $choice in
            1)
                echo "Crea tabella sezioni a partire dai dati degli studenti ..."
                
                # Cancello la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "DROP TABLE IF EXISTS '$TABELLA_SEZIONI';"

                # Creo la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "CREATE TABLE IF NOT EXISTS '$TABELLA_SEZIONI' ( cl NUMERIC, letter VARCHAR(200), addr_argo VARCHAR(200), sez_argo NUMERIC, addr_gsuite VARCHAR(200), sez_gsuite VARCHAR(200), sezione_gsuite VARCHAR(200), email_coordinatore VARCHAR(200));"
                ;;
            2)
                echo "Crea dati delle sezioni ..."
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "
                INSERT INTO $TABELLA_SEZIONI (cl, sez_argo, letter, addr_argo, addr_gsuite, sez_gsuite, sezione_gsuite) 
                SELECT cl, sez_argo, letter, addr_argo, 
                  UPPER(addr_gsuite), 
                  UPPER(letter || '_' || addr_gsuite) AS sez_gsuite,
                  UPPER(cl || letter || '_' || addr_gsuite) AS sezione_gsuite
                FROM (
                  SELECT DISTINCT 
                    TRIM(sa.cl) AS cl,
                    TRIM(sa.sez) AS sez_argo,
                    TRIM(SUBSTR(sa.sez,1,1)) AS letter,
                    TRIM(SUBSTR(sa.sez,2)) AS addr_argo,
                    CASE
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'in' THEN 'INF' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'm' THEN 'MEC' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'mDD' THEN 'MDD' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'me_sirio' THEN 'MEC_SIRIO'
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'm_sirio' THEN 'MEC_SIRIO' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'tlt' THEN 'TLC' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'tr' THEN 'AER' 
                          ELSE TRIM(SUBSTR(sa.sez,2))
                    END AS addr_gsuite
                  FROM $TABELLA_STUDENTI sa 
                  ORDER BY sa.cl, sa.sez
                )"
                ;;
            3)
                echo "Visualizza dati delle sezioni ..."

                query=$(query::getQuerySezioniDefaultValues "cl, letter, addr_argo, addr_gsuite, sezione_gsuite, email_coordinatore" "sezione_gsuite" )

                $SQLITE_CMD -header -table studenti.db " $query"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto le sezioni in file CSV ..."

                query=$(query::getQuerySezioniDefaultValues "cl, letter, addr_argo, addr_gsuite, sezione_gsuite, email_coordinatore" "sezione_gsuite" )
                
                $SQLITE_CMD studenti.db -header -csv "$query" > "$EXPORT_DIR_DATE/${TABELLA_SEZIONI}_$CURRENT_DATE.csv"
                ;;
            6)
              echo "Invia elenco classi ai coordinatori"

              echo "Prepara EMAIL degli account studenti, da inviare ai coordinatori"

              query=$(query::getQuerySezioniSupervisorNotEmpty "sezione_gsuite, email_coordinatore" "addr_argo" )

                while IFS="," read -r sezione_gsuite email_coordinatore; do

                    local TO="$email_coordinatore" # , CDC_$sezione_gsuite@$DOMAIN

                    local CC="gsuite_supporto@$DOMAIN" # supporto_digitale@$DOMAIN

                    local MESSAGE="
                      \n Buongiorno,
                      \n in allegato l'elenco degli account degli studenti della classe $sezione_gsuite .
                      \n Richieste e segnalazioni di imprecisioni o problematiche relative agli account studenti possono essere inoltrate a supporto_digitale@$DOMAIN .
                      \n Tutti i docenti sono abilitati ad effettuare il reset password degli studenti, come da circolare 211 (in allegato).
                      \n Cordiali saluti"

                    echo "Invio EMAIL degli account studenti della classe $sezione_gsuite - coordinatore $email_coordinatore"

                    if [ ! -e "$EXPORT_DIR_DATE/$sezione_gsuite.xlsx" ]; then
                      echo "Il file $EXPORT_DIR_DATE/$sezione_gsuite.xlsx non esiste."
                      break;
                    fi

                    if [ ! -e "$EXPORT_DIR_DATE/Circolare211-ResetPassword.pdf" ]; then
                      echo "Il file $EXPORT_DIR_DATE/Circolare211-ResetPassword.pdf non esiste."
                      break;
                    fi

                    $GAM_CMD sendemail to "$TO" cc "$CC" subject "Account studenti $sezione_gsuite" message "$MESSAGE" attach "$EXPORT_DIR_DATE/$sezione_gsuite.xlsx" attach "$EXPORT_DIR_DATE/Circolare211-ResetPassword.pdf"

                done < <($SQLITE_CMD -csv studenti.db " $query" | sed 's/"//g' )
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
    log::_write_log "CONFIG" "Tabella sezioni: $TABELLA_SEZIONI"
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
