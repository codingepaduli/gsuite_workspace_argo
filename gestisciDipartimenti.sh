#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

QUERY_NOMI_DIPARTIMENTI="
    SELECT DISTINCT UPPER(dipartimento)
    FROM $TABELLA_PERSONALE
    WHERE dipartimento IS NOT NULL 
        AND TRIM(dipartimento) != ''
    ORDER BY UPPER(dipartimento) ;"

while IFS="," read -r dipartimento; do
  add_to_map "$dipartimento" "
      SELECT LOWER(email_gsuite) AS email_gsuite
      FROM $TABELLA_PERSONALE
      WHERE (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '')
          AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
          AND UPPER(dipartimento) = UPPER('$dipartimento') 
      ORDER BY LOWER(email_gsuite);"
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
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
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

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "${QUERY_PERSONALE_ATA}"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "dipartimento_$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            4)
                echo "Rimuovi membri dai gruppi  ..."

                $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$DIPARTIMENTO_PERSONALE_ATA" --query "${QUERY_PERSONALE_ATA}"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "dipartimento_$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
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
        
        # Pausa per permettere all'utente di leggere il risultato
        read -p "Premi Invio per continuare..." -r _
    done
}

# Avvia la funzione principale
main
