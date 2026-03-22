#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 AND sz.cl IN ( $SQL_FILTRO_ANNI ) AND sz.addr_argo IN ( $SQL_FILTRO_SEZIONI ) ORDER BY sz.sezione_gsuite"

# Crea la query per gruppi GSUITE aggiuntivi, indicati nel file di configurazione
SQL_QUERY_ADDITIONAL_GROUPS="WITH temp AS ( SELECT NULL AS value "
# Itera sull'array
for value in "${GSUITE_ADDITIONAL_GROUPS[@]}"; do
    # Aggiungi il valore alla lista, racchiudendolo tra apici
    SQL_QUERY_ADDITIONAL_GROUPS+=" UNION ALL"
    SQL_QUERY_ADDITIONAL_GROUPS+=" SELECT '$value' AS value"
done
SQL_QUERY_ADDITIONAL_GROUPS+=") SELECT value FROM temp WHERE value IS NOT NULL "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione completa"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "0. Creo le tabelle, importo gli studenti"
    echo "1. Eseguo script aggiornamento email studenti"
    echo "2. Creo le email studenti e i relativi account su GSuite, li esporto in CSV"
    echo "3. Aggiungi i nuovi studenti alle classi, effettua gli spostamenti, toglie i ritirati"

    echo "5. Invio singola email ad ogni coordinatore con elenco studenti per classe"

    echo "6. Creo le tabelle, importo il personale"
    echo "7. Eseguo script aggiornamento email personale"
    

    echo "20. Esci"
}

# Funzione principale
main() {

  while true; do
    show_menu
    read -p "Scegli un'opzione (1-20): " -r choice
        
    case $choice in
      0)
        echo "Creo le tabelle, importo gli studenti"

        local CREATE_TABLE_STUDENTS=0
        local IMPORT_STUDENTS=1
        local CREATE_TABLE_STUDENTS_SIRIO=12
        local IMPORT_STUDENTS_SIRIO=13
        local COPY_STUDENTS_FROM_SIRIO=14

        ./gestisciStudenti.sh "$CREATE_TABLE_STUDENTS"
        ./gestisciStudenti.sh "$IMPORT_STUDENTS"
        read -p "Premi per continuare " -r _
        ./gestisciStudenti.sh "$CREATE_TABLE_STUDENTS_SIRIO"
        ./gestisciStudenti.sh "$IMPORT_STUDENTS_SIRIO"
        read -p "Premi per continuare " -r _
        ./gestisciStudenti.sh "$COPY_STUDENTS_FROM_SIRIO"
        read -p "Premi per continuare " -r _
      ;;
      1)
        local CREATE_SCRIPT_CF_STUDENTS=7
        local MOVE_SCRIPT_OLD_STUDENTS=10
        local CHECK_STUDENTS=16

        ./gestisciStudenti.sh "$CREATE_SCRIPT_CF_STUDENTS"
        ./gestisciStudenti.sh "$MOVE_SCRIPT_OLD_STUDENTS"
        ./gestisciStudenti.sh "$CHECK_STUDENTS"
      ;;
      2)
        echo "Creo le email e i relativi account su GSuite, li esporto in CSV"

        local SHOW_NEW_STUDENTS=3
        local CREATE_MAIL_STUDENTS=4
        local EXPORT_NEW_STUDENTS=5
        local CREATE_GSUITE_ACCOUNT_STUDENTS=6
        local CREATE_SCRIPT_CF_STUDENTS=7
        
        ./gestisciStudenti.sh "$SHOW_NEW_STUDENTS"
        ./gestisciStudenti.sh "$CREATE_MAIL_STUDENTS"
        ./gestisciStudenti.sh "$SHOW_NEW_STUDENTS"
        ./gestisciStudenti.sh "$EXPORT_NEW_STUDENTS" # Also by years
        ./gestisciStudenti.sh "$CREATE_GSUITE_ACCOUNT_STUDENTS"
        ./gestisciStudenti.sh "$CREATE_SCRIPT_CF_STUDENTS"
      ;;
      3)
        echo "Aggiungi i nuovi studenti alle classi, effettua gli spostamenti, toglie i ritirati"

        local SMOVE_STUDENTS_IN_CLASSES=8
        local ADD_NEW_STUDENTS_IN_CLASSES=9
        
        ./gestisciGruppiClasse.sh "$SMOVE_STUDENTS_IN_CLASSES"
        ./gestisciGruppiClasse.sh "$ADD_NEW_STUDENTS_IN_CLASSES"
      ;;
      5)
        echo "5. Invio singola email ad ogni coordinatore con elenco studenti per classe"

        local EXPORT_CLASSES=3
        local SEND_MAIL_TO_SUPERVISORS=6
        
        ./gestisciGruppiClasse.sh "$EXPORT_CLASSES"
        ./gestisciSezioni.sh "$SEND_MAIL_TO_SUPERVISORS"
      ;;
      6)
        echo "Creo la tabella, importo il personale"

        local CREATE_TABLE_EMPLOYEES=1
        local IMPORT_EMPLOYEES=2

        ./gestisciPersonale.sh "$CREATE_TABLE_EMPLOYEES"
        ./gestisciPersonale.sh "$IMPORT_EMPLOYEES"
        read -p "Premi per continuare " -r _
      ;;
      7)
        local CREATE_SCRIPT_CF_EMPLOYEES=12
        local MOVE_SCRIPT_OLD_EMPLOYEES=17
        # local CHECK_EMPLOYEES=16

        ./gestisciPersonale.sh "$CREATE_SCRIPT_CF_EMPLOYEES"
        ./gestisciPersonale.sh "$MOVE_SCRIPT_OLD_EMPLOYEES"
        # ./gestisciPersonale.sh "$CHECK_EMPLOYEES"
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

showConfig() {
  if log::level_is_active "CONFIG"; then
    log::_write_log "CONFIG" "Checking config - $(date --date='today' '+%Y-%m-%d %H:%M:%S')"
    log::_write_log "CONFIG" "-----------------------------------------"
    log::_write_log "CONFIG" "Current date: $CURRENT_DATE"
    log::_write_log "CONFIG" "Tabella studenti diurno: $TABELLA_STUDENTI"
    log::_write_log "CONFIG" "Tabella studenti precedente per confronto: $TABELLA_STUDENTI_PRECEDENTE"
    log::_write_log "CONFIG" "Tabella sezioni: $TABELLA_SEZIONI"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_STUDENTI_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_STUDENTI_A"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "Query sezioni: $SQL_QUERY_SEZIONI"
    log::_write_log "CONFIG" "Query altri gruppi: $SQL_QUERY_ADDITIONAL_GROUPS"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

# Show config vars
showConfig

# Avvia la funzione principale
main

