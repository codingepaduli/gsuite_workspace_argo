#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# Gruppo insegnanti
GRUPPO_DOCENTI="docenti_volta"
GRUPPO_SOSTEGNO="sostegno"
GRUPPO_COORDINATORI="coordinatori"

add_to_map "$GRUPPO_DOCENTI" "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND d.email_gsuite != '' AND tipo_personale='docente' ORDER BY d.email_gsuite; "

add_to_map "$GRUPPO_COORDINATORI" "SELECT LOWER(g.email_gsuite) as email_gsuite FROM $TABELLA_GRUPPI g WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY g.email_gsuite;"

add_to_map "$GRUPPO_SOSTEGNO" "SELECT LOWER(g.email_gsuite) as email_gsuite FROM $TABELLA_GRUPPI g WHERE g.nome_gruppo = '$GRUPPO_SOSTEGNO' ORDER BY g.email_gsuite;"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi docenti (da tabella $TABELLA_GRUPPI)"
    echo "-------------"
    echo "1. Creo la tabella $TABELLA_GRUPPI"
    echo "2. Crea tutti i gruppi su GSuite"
    echo "3. Backup tutti i gruppi su CSV distinti..."
    echo "4. "
    echo "5. Visualizza $GRUPPO_COORDINATORI con classi associate"
    echo "6. Salva $GRUPPO_COORDINATORI con classi associate su CSV"
    echo "7. "
    echo "8. Inserisci membri nei gruppi  ..."
    echo "9. Rimuovi membri dai gruppi  ..."
    echo "10. "
    echo "11. Normalizza tabella"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            10)
                echo "Creo la tabella $TABELLA_GRUPPI"

                # Cancello la tabella
                # $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_GRUPPI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_GRUPPI' (nome_gruppo VARCHAR(200), codice_fiscale VARCHAR(200), email_gsuite VARCHAR(200), email_personale VARCHAR(200), aggiunto_il VARCHAR(200));"
                ;;
            2)
                echo "Crea tutti i gruppi su GSuite ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            3)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup tutti i gruppi su CSV distinti ..."

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/${nome_gruppo}_${CURRENT_DATE}.csv"

                  echo "Saved in file $EXPORT_DIR_DATE/${nome_gruppo}_${CURRENT_DATE}.csv"
                done
                ;;
            5)
                echo "Visualizza $GRUPPO_COORDINATORI con classi associate"
                
                $SQLITE_CMD studenti.db -header -table "SELECT UPPER(d.cognome) as cognome, UPPER(d.nome) as nome, LOWER(d.email_gsuite) as email_gsuite, g.aggiunto_il as coordinatori FROM $TABELLA_PERSONALE d INNER JOIN $TABELLA_GRUPPI g ON g.email_gsuite = d.email_gsuite WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY d.cognome, d.nome;"
                ;;
            6)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Salva $GRUPPO_COORDINATORI con classi associate in CSV..."
                $SQLITE_CMD studenti.db -header -csv "SELECT UPPER(d.cognome) as cognome, UPPER(d.nome) as nome, LOWER(d.email_gsuite) as email_gsuite, g.aggiunto_il as coordinatori FROM $TABELLA_PERSONALE d INNER JOIN $TABELLA_GRUPPI g ON g.email_gsuite = d.email_gsuite WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY d.cognome, d.nome;" > "${EXPORT_DIR_DATE}/${GRUPPO_COORDINATORI}_con_classi_${CURRENT_DATE}.csv"
                ;;
            11)
                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GRUPPI 
                SET nome_gruppo = TRIM(LOWER(nome_gruppo)),
                    codice_fiscale = TRIM(UPPER(codice_fiscale)),
                    email_gsuite = TRIM(UPPER(email_gsuite)),
                    email_personale = TRIM(UPPER(email_personale));"
                ;;
            8)
                echo "Inserisci membri nei gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            9)
                echo "Rimuovi membri dai gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
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
        read -p "Premi Invio per continuare..." dummy
    done
}

# Avvia la funzione principale
main
