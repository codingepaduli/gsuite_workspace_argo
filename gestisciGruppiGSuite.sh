#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

########################################################################
# Questo script permette di importare i gruppi e di rimuovere i membri #
# disabilitati, ma non è progettato per inserire i membri nei gruppi,  #
# questa funzionalità è demandata agli specifici script.               # 
########################################################################

# Gruppo insegnanti
GRUPPO_DOCENTI="docenti_volta"

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

add_to_map "$GRUPPO_DOCENTI" " NO; "
add_to_map "$GRUPPO_CLASSROOM" " NO; "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi GSuite"
    echo "-------------"
    echo "1. Creo la tabella gruppi GSuite"
    echo "2. Importa in tabella i gruppi GSuite"
    echo "3. Normalizza dati in tabella"
    echo "4. Backup tutti i gruppi GSuite su CSV distinti..."
    echo "7. "
    echo "8. Visualizza membri disabilitati da rimuovere dai gruppi GSuite"
    echo "9. Rimuovi membri disabilitati dai gruppi GSuite"
    echo "10. "
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Creo la tabella gruppi GSuite"

                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_GRUPPI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_GRUPPI' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            2)
                echo "Importa in tabella i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " | $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_GRUPPI" - --csv --empty-null
                done
                ;;
            3)
                echo "Normalizza dati"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GRUPPI 
                SET \"group\" = TRIM(LOWER(\"group\")),
                    name = TRIM(UPPER(name)),
                    email = TRIM(LOWER(email)),
                    role = TRIM(UPPER(role)),
                    type = TRIM(UPPER(type)),
                    status = TRIM(UPPER(status));"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GRUPPI 
                    SET \"group\" = substr(\"group\", 1, instr(\"group\", '@') - 1)
                    WHERE \"group\" LIKE '%@%';"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup tutti i gruppi su CSV distinti ..."

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/${nome_gruppo}_${CURRENT_DATE}.csv"
                done
                ;;
            6)
                # echo "Inserisci membri nei gruppi  ..."
                
                # for nome_gruppo in "${!gruppi[@]}"; do
                #   echo "Inserisco membri nel gruppo $nome_gruppo ...!"
                #   echo "query ${gruppi[$nome_gruppo]} ...!"
                #   $SQLITE_CMD studenti.db "${gruppi[$nome_gruppo]}"

                #   $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                # done
                ;;
            8)
                echo "Visualizza membri disabilitati da rimuovere  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "membri disabilitati da rimuovere dal gruppo $nome_gruppo ...!"

                  local QUERY_UTENTI_DISABILITATI="SELECT LOWER(dg.email)
                      FROM $TABELLA_GRUPPI dg 
                      WHERE 1=1
                        -- filtro gruppo
                          AND \"group\" = '$nome_gruppo'
                        -- filtro studenti e personale
                          AND LOWER(dg.email) NOT NULL AND TRIM(LOWER(dg.email)) != ''
                          AND LOWER(SUBSTR(dg.email, 1, MIN(2, LENGTH(dg.email)))) IN ('d.', 'a.', 's.')
                          AND LOWER(dg.email) IN (
                            SELECT LOWER(t.email_gsuite)
                            FROM $TABELLA_UTENTI_GSUITE t
                            WHERE UPPER(t.stato_utente) = 'SUSPENDED'
                          ) "

                  $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "$QUERY_UTENTI_DISABILITATI"
                done
                ;;
            9)
                echo "Rimuovi membri dai gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ...!"

                  local QUERY_UTENTI_DISABILITATI="SELECT LOWER(dg.email)
                      FROM $TABELLA_GRUPPI dg 
                      WHERE 1=1
                        -- filtro gruppo
                          AND \"group\" = '$nome_gruppo'
                        -- filtro studenti e personale
                          AND LOWER(dg.email) NOT NULL AND TRIM(LOWER(dg.email)) != ''
                          AND LOWER(SUBSTR(dg.email, 1, MIN(2, LENGTH(dg.email)))) IN ('d.', 'a.', 's.')
                          AND LOWER(dg.email) IN (
                            SELECT LOWER(t.email_gsuite)
                            FROM $TABELLA_UTENTI_GSUITE t
                            WHERE UPPER(t.stato_utente) = 'SUSPENDED'
                          ) "

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "$QUERY_UTENTI_DISABILITATI"
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
