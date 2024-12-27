#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# Tabella personale globale
TABELLA_PERSONALE_GLOBALE="personale_2024_25"

# Aggiunge gli insegnanti a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con personale versionata alla data indicata
FILE_PERSONALE_CSV="$BASE_DIR/dati_argo/personale_argo/$TABELLA_PERSONALE.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabelle Personale"
    echo "-------------"
    echo "1. Importa in tabella personale da CSV"
    echo "2. Aggiorna email, data e flags da tabella globale"
    echo "3. Visualizza personale neo-assunto"
    echo "4. Creo la mail ai nuovi docenti"
    echo "5. Creo la mail al nuovo personale ATA"
    echo "6. Esporto il nuovo personale in file CSV"
    echo "7. Sposto il nuovo personale nella tabella globale"
    echo "8. ?? Rimuovi i personale da tabella globale"
    echo "9. Crea il nuovo personale su GSuite"
    echo "10. Aggiungo i nuovi docenti su Classroom"
    echo "11. Crea i nuovi docenti su WordPress"
    echo "12. Crea script personale_CF.sh"
    echo "13. Sospendi (disabilita) personale"
    echo "14. Elimina personale"
    echo "15. Visualizza personale su WordPress"
    echo "16. Elimina personale su WordPress"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Cancello, ricreo e normalizzo la tabella del personale $TABELLA_PERSONALE importando il file CSV ..."
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_PERSONALE';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_PERSONALE' (tipo_personale VARCHAR(200), cognome VARCHAR(200), nome VARCHAR(200), data_nascita VARCHAR(200), codice_fiscale VARCHAR(200), telefono VARCHAR(200), altro_telefono VARCHAR(200), cellulare VARCHAR(200), email_personale VARCHAR(200), email_gsuite VARCHAR(200), aggiunto_il VARCHAR(200), note VARCHAR(200));"

                # Importa CSV dati
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_PERSONALE" "$FILE_PERSONALE_CSV" --csv --empty-null

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_PERSONALE 
                SET codice_fiscale = TRIM(UPPER(codice_fiscale)),
                    tipo_personale = TRIM(LOWER(tipo_personale)),
                    email_personale = TRIM(LOWER(email_personale)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)) ;"
                ;;
            2)
                echo "Aggiorno la tabella personale da dati precedenti ..."
                
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_PERSONALE
                  SET email_gsuite = email,
                      aggiunto_il = aggiunto
                  FROM (SELECT UPPER(d.codice_fiscale) AS cod_fis, LOWER(d.email_gsuite) AS email, d.aggiunto_il AS aggiunto FROM $TABELLA_PERSONALE_GLOBALE d) AS d_old
                  WHERE d_old.cod_fis = UPPER(codice_fiscale);"
                ;;
            3)
                echo "Visualizza personale neo-assunto ..."
                
                $SQLITE_CMD studenti.db -header -table "SELECT tipo_personale, cognome, nome, email_personale, email_gsuite FROM $TABELLA_PERSONALE WHERE email_gsuite is NULL OR email_gsuite = '' OR aggiunto_il = '$CURRENT_DATE';"
                ;;
            4)
                echo "Creo la mail ai nuovi docenti ..."
                
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_PERSONALE
                    SET email_gsuite = 'd.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE (email_gsuite is NULL 
                        OR email_gsuite = '')
                        AND tipo_personale = 'docente';"
                ;;
            5)
                echo "Creo la mail al nuovo personale ATA ..."
                
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_PERSONALE
                    SET email_gsuite = 'a.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE (email_gsuite is NULL 
                        OR email_gsuite = '')
                        AND tipo_personale = 'ata';"
                ;;
            6)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto il nuovo personale in file CSV ..."
                
                $SQLITE_CMD studenti.db -header -csv "SELECT email_gsuite, '$PASSWORD_CLASSROOM', tipo_personale, aggiunto_il, cognome, nome, codice_fiscale, cellulare, email_personale FROM $TABELLA_PERSONALE WHERE (email_gsuite is NULL OR email_gsuite = '') OR aggiunto_il = '$CURRENT_DATE' ORDER BY cognome" > "$EXPORT_DIR_DATE/nuovo_personale.csv"
                ;;
            7)
                echo "Sposto il nuovo personale nella tabella globale ..."
                
                $SQLITE_CMD studenti.db "INSERT INTO $TABELLA_PERSONALE_GLOBALE (tipo_personale, cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il)
                    SELECT tipo_personale, cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il
                    FROM $TABELLA_PERSONALE
                    WHERE aggiunto_il='$CURRENT_DATE' AND 
                    codice_fiscale NOT IN (SELECT codice_fiscale FROM $TABELLA_PERSONALE_GLOBALE);"
                ;;
            8)
                echo "rimuovo i personale dalla tabella globale ..."
                echo "meglio farlo a mano va..."
                echo "..."
                echo "..."
                
                continue
                # rimuovo i personale dalla tabella globale
                $SQLITE_CMD studenti.db -header -csv "DELETE FROM $TABELLA_PERSONALE_GLOBALE WHERE aggiunto_il='$CURRENT_DATE' AND codice_fiscale IN (SELECT codice_fiscale FROM $TABELLA_PERSONALE WHERE codice_fiscale IS NOT NULL and codice_fiscale != '');"
                ;;
            9)
                echo "Creo i nuovi docenti su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createUsers --group "Docenti" --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_PERSONALE
                WHERE aggiunto_il='$CURRENT_DATE'
                AND tipo_personale='docente';"
                ;;
            10)
                echo "Aggiungo i nuovi docenti su Classroom ..."
                
                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_CLASSROOM" --query "SELECT email_gsuite
                FROM $TABELLA_PERSONALE WHERE aggiunto_il='$CURRENT_DATE' AND tipo_personale='docente';"
                ;;
            11)
                echo "Creo i nuovi docenti su $DOMAIN ..."
                
                $RUN_CMD_WITH_QUERY --command createUsersOnWordPress --group " NO " --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_PERSONALE
                WHERE aggiunto_il='$CURRENT_DATE' AND tipo_personale='docente';"
                ;;
            12)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script personale_CF_$CURRENT_DATE.sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"
                echo 'source "./_environment_working_tables.sh"' >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"
                echo "TABELLA_PERSONALE=\"$TABELLA_PERSONALE\"" >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"

                while IFS="," read -r tipo_personale email_gsuite codice_fiscale cognome nome aggiunto note; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_PERSONALE SET email_gsuite = '$email_gsuite', aggiunto_il = '$aggiunto', note = '$note' WHERE codice_fiscale = '$codice_fiscale'\" # $cognome $nome $tipo_personale;" >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"

                done < <($SQLITE_CMD -csv studenti.db "select tipo_personale, email_gsuite, codice_fiscale, cognome, nome, aggiunto_il, note FROM $TABELLA_PERSONALE ORDER BY codice_fiscale" | sed "s/\"//g")
                ;;
            13)
                echo "Sospendi (disabilita) personale ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            14)
                echo "Cancella personale ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            15)
                echo "Visualizza personale su wordpress ..."

                $RUN_CMD_WITH_QUERY --command showUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            16)
                echo "Cancella personale da wordpress ..."

                $RUN_CMD_WITH_QUERY --command deleteUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_PERSONALE d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            17)
                echo "Creo i nuovi ATA su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createUsers --group "ATA" --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_PERSONALE
                WHERE aggiunto_il='$CURRENT_DATE'
                AND tipo_personale='docente';"
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
