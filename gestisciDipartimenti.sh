#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# Query dei nomi dei dipartimenti e senza il prefisso "dipartimento_"
QUERY_NOMI_DIPARTIMENTI="
    SELECT DISTINCT UPPER(dipartimento)
    FROM $TABELLA_PERSONALE
    WHERE dipartimento IS NOT NULL 
        AND TRIM(dipartimento) != ''
    ORDER BY UPPER(dipartimento) ;"

# Le query del personale di ogni dipartimenti
while IFS="," read -r dipartimento; do
  add_to_map "$dipartimento" "
      FROM $TABELLA_PERSONALE
      WHERE (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '')
          AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
          AND UPPER(dipartimento) = UPPER('$dipartimento') 
      "
done < <($SQLITE_CMD -csv studenti.db "$QUERY_NOMI_DIPARTIMENTI" | sed 's/"//g' )

#####################################################################
# PERSONALE_ATA - gestito a parte perché il nome non deve essere
# 'dipartimento_personale_ata' ma solo 'personale_ata'
DIPARTIMENTO_PERSONALE_ATA='PERSONALE_ATA'
QUERY_PERSONALE_ATA=$(get_from_map "$DIPARTIMENTO_PERSONALE_ATA")
remove_from_map "$DIPARTIMENTO_PERSONALE_ATA"
#####################################################################

echo "elenco dipartimenti:"
echo "    "
echo "    PERSONALE_ATA ------------ gestione separata ------------"
for nome_gruppo in "${!gruppi[@]}"; do
  echo " dipartimento $nome_gruppo"
done
echo "    "

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
        local choice="$1"
        
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

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "
                SELECT LOWER(email_gsuite) AS email_gsuite 
                ${QUERY_PERSONALE_ATA}
                ORDER BY LOWER(email_gsuite);"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "dipartimento_$nome_gruppo" --query "
                  SELECT LOWER(email_gsuite) AS email_gsuite 
                  ${gruppi[$nome_gruppo]}
                  ORDER BY LOWER(email_gsuite);"
                done
                ;;
            4)
                echo "Rimuovi membri dai gruppi  ..."

                $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "
                SELECT LOWER(email_gsuite) AS email_gsuite 
                ${QUERY_PERSONALE_ATA}
                ORDER BY LOWER(email_gsuite);"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "dipartimento_$nome_gruppo" --query "
                  SELECT LOWER(email_gsuite) AS email_gsuite 
                  ${gruppi[$nome_gruppo]}
                  ORDER BY LOWER(email_gsuite);"
                done
                ;;
            7)
                echo "Aggiorna i dipartimenti con i nuovi docenti  ..."

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "
                SELECT LOWER(email_gsuite) AS email_gsuite 
                ${QUERY_PERSONALE_ATA}
                  AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                    AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                  )
                ORDER BY LOWER(email_gsuite);"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "dipartimento_$nome_gruppo" --query "
                  SELECT LOWER(email_gsuite) AS email_gsuite 
                  ${gruppi[$nome_gruppo]}
                  AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                    AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                  )
                  ORDER BY LOWER(email_gsuite);"
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