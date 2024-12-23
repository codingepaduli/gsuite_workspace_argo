#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# Mappa (array associativo)
declare -A gruppi

# Funzione per aggiungere elementi alla mappa
add_to_map() {
    local key=$1
    local value=$2
    gruppi[$key]=$value
}

# Funzione per ottenere un valore dalla mappa
get_from_map() {
    local key=$1
    echo "${gruppi[$key]}"
}

# Funzione per rimuovere un elemento dalla mappa
remove_from_map() {
    local key=$1
    unset "gruppi[$key]"
}

# Gruppo insegnanti
GRUPPO_DOCENTI="docenti_volta"
GRUPPO_SOSTEGNO="sostegno"
GRUPPO_COORDINATORI="coordinatori"

# add_to_map "docenti_volta" "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il IS NOT NULL AND aggiunto_il != '' AND tipo_personale='docente'; "

add_to_map "$GRUPPO_COORDINATORI" "SELECT LOWER(g.email_gsuite) as email_gsuite FROM $TABELLA_GRUPPI g WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY g.email_gsuite;"

# add_to_map "docenti_volta" "
# SELECT csv.email
# FROM tabella_CSV csv 
# WHERE SUBSTR(csv.email, 1, 2) = 'd.'
# AND csv.email NOT IN (
#     SELECT pa.email_gsuite
#     FROM personale_argo_2024_11_28 pa
#     WHERE pa.tipo_personale = 'docente' 
# ); "


# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di docenti"
    echo "-------------"
    echo "1. Aggiungi membri al $GRUPPO_DOCENTI ..."
    echo "2. Backup gruppo $GRUPPO_DOCENTI su CSV"
    echo "3. Backup gruppo classroom $GRUPPO_CLASSROOM su CSV..."
    echo "4. Backup gruppo $GRUPPO_SOSTEGNO su CSV..."
    echo "5. Backup gruppo $GRUPPO_COORDINATORI su CSV..."
    echo "6. Crea gruppo $GRUPPO_COORDINATORI su GSuite..."
    echo "7. Salva $GRUPPO_COORDINATORI con classi associate su CSV"
    echo "11. Normalizza tabella"
    echo "12. Visualizza $GRUPPO_COORDINATORI"
    echo "13. Aggiungi membri al $GRUPPO_COORDINATORI ..."
    echo "14. Aggiungi membri al $GRUPPO_SOSTEGNO ..."
    echo "15. Crea gruppi su GSuite..."
    echo "16. Inserisci membri nei gruppi  ..."
    echo "17. Rimuovi membri dai gruppi  ..."

    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Aggiungi membri al $GRUPPO_DOCENTI ..."
                
                # $RUN_CMD_WITH_QUERY --command deleteGroup --group "$GRUPPO_DOCENTI" --query " NO "

                # $RUN_CMD_WITH_QUERY --command createGroup --group "$GRUPPO_DOCENTI" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_DOCENTI" --query "select d.email_gsuite from $TABELLA_PERSONALE_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il IS NOT NULL AND tipo_personale='docente';"
            
                # $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "test_coo" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.coordinatore IS NOT NULL;"
            
                # $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "sostegno" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.sostegno IS NOT NULL;"
                ;;
            2)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup gruppo $GRUPPO_DOCENTI ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_DOCENTI" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_DOCENTI}_${CURRENT_DATE}.csv"
                ;;
            3)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup gruppo classroom $GRUPPO_CLASSROOM ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_CLASSROOM" --query " NO " > "$EXPORT_DIR_DATE/${GRUPPO_CLASSROOM}_${CURRENT_DATE}.csv"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup gruppo $GRUPPO_SOSTEGNO ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_SOSTEGNO" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_SOSTEGNO}_${CURRENT_DATE}.csv"
                ;;
            5)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup gruppo $GRUPPO_COORDINATORI ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "$GRUPPO_COORDINATORI" --query " NO " > "${EXPORT_DIR_DATE}/${GRUPPO_COORDINATORI}_${CURRENT_DATE}.csv"
                ;;
            6)
                echo "Crea gruppo $GRUPPO_COORDINATORI ..."
                
                $RUN_CMD_WITH_QUERY --command createGroup --group "$GRUPPO_COORDINATORI" --query " NO "
                ;;
            7)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Salva $GRUPPO_COORDINATORI con classi associate in CSV..."
                $SQLITE_CMD studenti.db -header -csv "SELECT UPPER(d.cognome) as cognome, UPPER(d.nome) as nome, LOWER(d.email_gsuite) as email_gsuite, g.aggiunto_il as coordinatori FROM $TABELLA_PERSONALE d INNER JOIN $TABELLA_GRUPPI g ON g.email_gsuite = d.email_gsuite WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY d.cognome, d.nome;" > "${EXPORT_DIR_DATE}/${GRUPPO_COORDINATORI}_con_classi_${CURRENT_DATE}.csv"
                ;;
            10)
                # Cancello la tabella
                # $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_GRUPPI';"

                # Creo la tabella
                # $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_GRUPPI' (nome_gruppo VARCHAR(200), codice_fiscale VARCHAR(200), email_gsuite VARCHAR(200), email_personale VARCHAR(200), aggiunto_il VARCHAR(200));"

                # Importa CSV dati
                #  $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_GRUPPI" "$FILE_PERSONALE_CSV" --csv --empty-null
                ;;
            11)
                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GRUPPI 
                SET nome_gruppo = TRIM(LOWER(nome_gruppo)),
                    codice_fiscale = TRIM(UPPER(codice_fiscale)),
                    email_gsuite = TRIM(UPPER(email_gsuite)),
                    email_personale = TRIM(UPPER(email_personale));"
                ;;
            12)
                echo "Visualizza $GRUPPO_COORDINATORI ..."
                
                $SQLITE_CMD studenti.db -header -table "SELECT UPPER(d.cognome) as cognome, UPPER(d.nome) as nome, LOWER(d.email_gsuite) as email_gsuite, g.aggiunto_il as coordinatori FROM $TABELLA_PERSONALE d INNER JOIN $TABELLA_GRUPPI g ON g.email_gsuite = d.email_gsuite WHERE g.nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY d.cognome, d.nome;"
                ;;
            13)
                echo "Aggiungi membri al $GRUPPO_COORDINATORI ..."

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_COORDINATORI" --query "SELECT DISTINCT email_gsuite FROM $TABELLA_GRUPPI WHERE nome_gruppo = '$GRUPPO_COORDINATORI' ORDER BY aggiunto_il;"
                ;;
            14)
                echo "Aggiungi membri al $GRUPPO_SOSTEGNO ..."
                
                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_SOSTEGNO" --query "SELECT email_gsuite FROM $TABELLA_GRUPPI WHERE nome_gruppo = '$GRUPPO_SOSTEGNO';"
                ;;
            15)
                echo "Crea gruppi su GSuite  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"

                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            16)
                echo "Inserisci membri nei gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            17)
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
