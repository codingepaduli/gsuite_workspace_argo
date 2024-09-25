#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Script per creazione utenti
RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Tabella personale globale
TABELLA_PERSONALE_GLOBALE="personale_2024_25"

# Tabella di lavoro personale versionata alla data indicata
TABELLA_PERSONALE="personale_argo_2024_09_25"

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# Gruppo insegnanti abilitati a classroom
GRUPPO_DOCENTI="docenti_volta"
GRUPPO_SOSTEGNO="sostegno"
GRUPPO_COORDINATORI="sostegno"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di docenti"
    echo "-------------"
    echo "1. Cancella e ricrea gruppo docenti"
    echo "2. Backup gruppo $GRUPPO_DOCENTI su CSV"
    echo "3. Backup gruppo classroom $GRUPPO_CLASSROOM su CSV..."
    echo "4. Backup gruppo $GRUPPO_SOSTEGNO su CSV..."
    echo "5. Backup gruppo $GRUPPO_COORDINATORI su CSV..."
    echo "6. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Ricrea gruppo $GRUPPO_DOCENTI ..."
                $RUN_CMD_WITH_QUERY --command deleteGroup --group "$GRUPPO_DOCENTI" --query " NO "

                $RUN_CMD_WITH_QUERY --command createGroup --group "$GRUPPO_DOCENTI" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_DOCENTI" --query "select d.email_gsuite from $TABELLA_PERSONALE_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND tipo_personale='docente';"
                ;;
            
                # $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "test_coo" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.coordinatore IS NOT NULL;"
            
                # $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "sostegno" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.sostegno IS NOT NULL;"
            2)
                echo "Backup gruppo $GRUPPO_DOCENTI ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_DOCENTI" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_DOCENTI}_${CURRENT_DATE}.csv"
                ;;
            3)
                echo "Backup gruppo classroom $GRUPPO_CLASSROOM ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_CLASSROOM" --query " NO " > "$EXPORT_DIR_DATE/classroom_$CURRENT_DATE.csv"
                ;;
            4)
                echo "Backup gruppo $GRUPPO_SOSTEGNO ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_SOSTEGNO" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_SOSTEGNO}_${CURRENT_DATE}.csv"
                ;;
            5)
                echo "Backup gruppo $GRUPPO_COORDINATORI ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_COORDINATORI" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_COORDINATORI}_${CURRENT_DATE}.csv"
                ;;
            6)
                echo "Arrivederci!"
                exit 0
                ;;
            *)
                echo "Opzione non valida. Per favore, scegli un numero tra 1 e 20."
                sleep 1
                ;;
        esac
        
        # Pausa per permettere all'utente di leggere il risultato
        read -p "Premi Invio per continuare..." dummy
    done
}

# Avvia la funzione principale
main
