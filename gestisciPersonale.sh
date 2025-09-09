#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# Aggiunge gli insegnanti a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con personale versionata alla data indicata
FILE_PERSONALE_CSV="$BASE_DIR/dati_argo/personale_argo/$TABELLA_PERSONALE.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabelle Personale"
    echo "-------------"
    echo "1. Cancello e ricreo la tabella del personale"
    echo "2. Importo e normalizzo i dati dal file CSV"
    echo "3. Visualizza personale neo-assunto"
    echo "4. Creo la mail ai nuovi docenti"
    echo "5. Creo la mail al nuovo personale ATA"
    echo "6. Esporto il nuovo personale in file CSV"
    echo "7. Visualizza personale della tabella precedente non incluso in quella attuale"
    echo "8. Importa nella tabella attuale il personale della tabella precedente non incluso in quella attuale"
    echo "9. Crea il nuovo personale su GSuite"
    echo "10. Aggiungo i nuovi docenti su Classroom"
    echo "11. Creo il nuovo personale su WordPress"
    echo "12. Crea script personale_CF.sh"
    echo "13. Sospendi (disabilita) personale"
    echo "14. Elimina personale"
    echo "15. Visualizza personale su WordPress"
    echo "16. Elimina personale su WordPress"
    echo "19. Controllo i dati"
    echo "20. Esci"
}

# Funzione principale
main() {

    if ! checkAllVarsNotEmpty "TABELLA_PERSONALE" "PERIODO_PERSONALE_DA" "PERIODO_PERSONALE_A" ; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "1. Cancello e ricreo la tabella del personale"
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_PERSONALE';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_PERSONALE' ( 
                    tipo_personale VARCHAR(200), 
                    cognome VARCHAR(200), 
                    nome VARCHAR(200), 
                    data_nascita VARCHAR(200), 
                    codice_fiscale VARCHAR(200), 
                    telefono VARCHAR(200), 
                    altro_telefono VARCHAR(200), 
                    cellulare VARCHAR(200), 
                    email_personale VARCHAR(200), 
                    email_gsuite VARCHAR(200), 
                    aggiunto_il TEXT, 
                    cancellato_il TEXT, 
                    contratto VARCHAR(200), 
                    dipartimento VARCHAR(200), 
                    note VARCHAR(200));"
                ;;
            2)
                echo "2. Importo e normalizzo i dati dal file CSV $FILE_PERSONALE_CSV ..."
                
                # Importa CSV dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_PERSONALE_CSV $TABELLA_PERSONALE"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_PERSONALE 
                SET codice_fiscale = TRIM(UPPER(codice_fiscale)),
                    tipo_personale = TRIM(LOWER(tipo_personale)),
                    email_personale = TRIM(LOWER(email_personale)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)) ;"
                
                # Normalizza date
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_PERSONALE 
                SET aggiunto_il = date(substr(aggiunto_il, 7, 4) || '-' || substr(aggiunto_il, 4, 2) || '-' || substr(aggiunto_il, 1, 2))
                WHERE aggiunto_il is NOT NULL AND TRIM(aggiunto_il) != '';"

                # Normalizza date
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_PERSONALE 
                SET cancellato_il = date(substr(cancellato_il, 7, 4) || '-' || substr(cancellato_il, 4, 2) || '-' || substr(cancellato_il, 1, 2))
                WHERE cancellato_il IS NOT NULL AND TRIM(cancellato_il) != '';"
                ;;
            3)
                echo "Visualizza personale neo-assunto ..."
                
                $SQLITE_CMD studenti.db -header -table "SELECT LOWER(tipo_personale) as tipo, UPPER(cognome) as cognome, UPPER(nome) as nome, LOWER(email_personale) as email_personale, LOWER(email_gsuite) as email_gsuite
                FROM $TABELLA_PERSONALE 
                WHERE email_gsuite is NULL OR TRIM(email_gsuite) = ''
                    OR (aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                        AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A');"
                ;;
            4)
                checkAllVarsNotEmpty "DOMAIN" "CURRENT_DATE"

                echo "Creo la mail ai nuovi docenti ..."
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_PERSONALE
                    SET email_gsuite = 'd.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                        AND (email_gsuite IS NULL OR TRIM(email_gsuite) = '')
                        AND UPPER(tipo_personale) = UPPER('docente')
                        AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '');"
                ;;
            5)
                checkAllVarsNotEmpty "DOMAIN" "CURRENT_DATE"

                echo "Creo la mail al nuovo personale ATA ..."
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_PERSONALE
                    SET email_gsuite = 'a.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                        AND (email_gsuite IS NULL OR TRIM(email_gsuite) = '')
                        AND UPPER(tipo_personale) = UPPER('ata')
                        AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '');"
                ;;
            6)
                checkAllVarsNotEmpty "PASSWORD_CLASSROOM"

                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto il nuovo personale in file CSV ..."
                
                $SQLITE_CMD studenti.db -header -csv "SELECT LOWER(email_gsuite) as email_gsuite, '$PASSWORD_CLASSROOM' as password, LOWER(tipo_personale) as tipo_personale, aggiunto_il as aggiunto_il, UPPER(cognome) as cognome, UPPER(nome) as nome, UPPER(codice_fiscale) as codice_fiscale, cellulare, LOWER(email_personale) as email_personale
                FROM $TABELLA_PERSONALE 
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                      AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) OR (email_gsuite is NULL OR TRIM(email_gsuite) = '')
                ORDER BY UPPER(cognome); " > "$EXPORT_DIR_DATE/nuovo_personale.csv"
                ;;
            7)
                echo "7. Visualizza personale della tabella precedente non incluso in quella attuale"

                $SQLITE_CMD studenti.db -header -table "SELECT LOWER(tipo_personale) as tipo, UPPER(cognome) as cognome, UPPER(nome) as nome, UPPER(codice_fiscale) as codice_fiscale, LOWER(email_gsuite) as email_gsuite 
                FROM $TABELLA_PERSONALE_PRECEDENTE 
                WHERE codice_fiscale IS NOT NULL AND TRIM(codice_fiscale) != ''
                    AND UPPER(codice_fiscale) NOT IN (
                      SELECT UPPER(codice_fiscale)
                      FROM $TABELLA_PERSONALE );"
                ;;
            8)
                echo "8. Importa nella tabella attuale il personale della tabella precedente non incluso in quella attuale"
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "INSERT INTO $TABELLA_PERSONALE 
                SELECT *
                FROM $TABELLA_PERSONALE_PRECEDENTE
                WHERE codice_fiscale IS NOT NULL AND TRIM(codice_fiscale) != ''
                    AND UPPER(codice_fiscale) NOT IN (
                      SELECT UPPER(codice_fiscale)
                      FROM $TABELLA_PERSONALE );"
                ;;
            9)
                checkAllVarsNotEmpty "GSUITE_OU_DOCENTI" "GSUITE_OU_ATA"
                
                echo "Crea il nuovo personale su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createUsers --group "$GSUITE_OU_DOCENTI" --query " 
                SELECT LOWER(email_gsuite), UPPER(cognome), UPPER(nome), UPPER(codice_fiscale), LOWER(email_personale), cellulare 
                FROM $TABELLA_PERSONALE
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '') 
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                      AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) AND UPPER(tipo_personale) = UPPER('docente');"

                $RUN_CMD_WITH_QUERY --command createUsers --group "$GSUITE_OU_ATA" --query "
                SELECT LOWER(email_gsuite), UPPER(cognome), UPPER(nome), UPPER(codice_fiscale), LOWER(email_personale), cellulare 
                FROM $TABELLA_PERSONALE
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '') 
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                      AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) AND UPPER(tipo_personale) = UPPER('ata');"
                ;;
            10)
                checkAllVarsNotEmpty "GRUPPO_CLASSROOM"
                
                echo "Aggiungo i nuovi docenti su Classroom ..."
                
                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_CLASSROOM" --query "SELECT LOWER(email_gsuite)
                FROM $TABELLA_PERSONALE 
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '') 
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                      AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) AND UPPER(tipo_personale) = UPPER('docente');"
                ;;
            11)
                checkAllVarsNotEmpty "DOMAIN" "WORDPRESS_ROLE_TEACHER" "WORDPRESS_ROLE_ATA"
                
                echo "Creo il nuovo personale su $DOMAIN ..."
                
                $RUN_CMD_WITH_QUERY --command createUsersOnWordPress --group "$WORDPRESS_ROLE_TEACHER" --query "
                SELECT LOWER(email_gsuite), UPPER(cognome), UPPER(nome), UPPER(codice_fiscale), LOWER(email_personale), cellulare 
                FROM $TABELLA_PERSONALE
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '') 
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                    AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) AND UPPER(tipo_personale) = UPPER('docente');"

                $RUN_CMD_WITH_QUERY --command createUsersOnWordPress --group "$WORDPRESS_ROLE_ATA" --query "
                SELECT LOWER(email_gsuite), UPPER(cognome), UPPER(nome), UPPER(codice_fiscale), LOWER(email_personale), cellulare 
                FROM $TABELLA_PERSONALE
                WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
                    AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite) != '') 
                    AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
                    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
                    AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
                    ) AND UPPER(tipo_personale) = UPPER('ata');"
                ;;
            12)
                checkAllVarsNotEmpty "CURRENT_DATE"

                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script personale_CF_$CURRENT_DATE.sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"
                echo 'source "./_environment_working_tables.sh"' >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"

                while IFS="," read -r tipo_personale email_gsuite codice_fiscale cognome nome aggiunto cancellato contratto dipartimento note; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_PERSONALE SET email_gsuite = LOWER('$email_gsuite'), aggiunto_il = '$aggiunto', cancellato_il = '$cancellato', contratto = UPPER('$contratto'), dipartimento = UPPER('$dipartimento'), note = '$note' WHERE UPPER(codice_fiscale) = UPPER('$codice_fiscale')\" # $cognome $nome $tipo_personale;" >> "$EXPORT_DIR_DATE/personale_CF_$CURRENT_DATE.sh"

                done < <($SQLITE_CMD -csv studenti.db "select LOWER(tipo_personale), LOWER(email_gsuite), UPPER(codice_fiscale), UPPER(cognome), UPPER(nome), aggiunto_il, cancellato_il, UPPER(contratto), UPPER(dipartimento), note FROM $TABELLA_PERSONALE ORDER BY UPPER(codice_fiscale)" | sed "s/\"//g")
                ;;
            13)
                echo "Sospendi (disabilita) personale ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "SELECT LOWER(d.email_gsuite)
                FROM $TABELLA_PERSONALE d 
                WHERE d.email_gsuite IS NOT NULL AND TRIM(d.email_gsuite) != '' 
                    AND ( d.cancellato_il IS NOT NULL AND TRIM(d.cancellato_il) != ''
                        AND d.cancellato_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A' );"
                ;;
            14)
                echo "Cancella personale ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "SELECT LOWER(d.email_gsuite)
                FROM $TABELLA_PERSONALE d 
                WHERE d.email_gsuite IS NOT NULL AND TRIM (d.email_gsuite) != ''
                    AND ( d.cancellato_il IS NOT NULL AND TRIM(d.cancellato_il) != ''
                        AND d.cancellato_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A' );"
                ;;
            15)
                checkAllVarsNotEmpty "CURRENT_DATE"

                echo "Visualizza personale su wordpress ..."

                $RUN_CMD_WITH_QUERY --command showUsersOnWordPress --group " NO " --query "select LOWER(email_gsuite) from $TABELLA_PERSONALE WHERE email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            16)
                checkAllVarsNotEmpty "CURRENT_DATE"

                echo "Cancella personale da wordpress ..."

                $RUN_CMD_WITH_QUERY --command deleteUsersOnWordPress --group " NO " --query "select LOWER(email_gsuite) from $TABELLA_PERSONALE WHERE email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            19)
                echo "Controllo i dati"

                echo "Codici fiscali duplicati"

                $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "SELECT *
                  FROM $TABELLA_PERSONALE 
                  WHERE UPPER(codice_fiscale) IN (
                      SELECT UPPER(codice_fiscale)
                      FROM $TABELLA_PERSONALE 
                      GROUP BY UPPER(codice_fiscale)
                      HAVING COUNT(*) > 1
                  )"
                
                echo "email duplicate"

                $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "SELECT *
                  FROM $TABELLA_PERSONALE 
                  WHERE UPPER(email_gsuite) IN (
                      SELECT UPPER(email_gsuite)
                      FROM $TABELLA_PERSONALE 
                      GROUP BY UPPER(email_gsuite)
                      HAVING COUNT(*) > 1
                  )"
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
    log::_write_log "CONFIG" "Tabella personale: $TABELLA_PERSONALE"
    log::_write_log "CONFIG" "Tabella personale precedente per confronto: $TABELLA_PERSONALE_PRECEDENTE"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_PERSONALE_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_PERSONALE_A"
    log::_write_log "CONFIG" "Dominio: $DOMAIN"
    log::_write_log "CONFIG" "Gruppo Classroom: $GRUPPO_CLASSROOM"
    log::_write_log "CONFIG" "Password Classroom: $PASSWORD_CLASSROOM"
    log::_write_log "CONFIG" "File personale CSV: $FILE_PERSONALE_CSV"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

# Show config vars
showConfig

# Avvia la funzione principale
main
