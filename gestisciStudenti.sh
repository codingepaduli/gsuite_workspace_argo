#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 
FILE_CSV_STUDENTI="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI.csv"
FILE_CSV_STUDENTI_SERALE="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI_SERALE.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella Studenti"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "0. Cancello e ricreo la tabella studenti DIURNO"
    echo "1. Importo e normalizzo i dati del DIURNO"
    echo "2. Visualizza dati in tabella"
    echo "3. Visualizza nuovi studenti"
    echo "4. Creo la mail ai nuovi studenti"
    echo "5. Esporto i nuovi studenti in file CSV"
    echo "6. Creo il nuovi studenti su GSuite"
    echo "7. Crea script studenti_CF.sh"
    echo "8. Sospendi studenti"
    echo "9. Cancella studenti"
    echo "10. "
    echo "11. "
    echo "12. Cancello e ricreo la tabella studenti SERALE"
    echo "13. Importo e normalizzo i dati del SERALE"
    echo "14. Copio i dati del SERALE nella tabella del DIURNO, unificando la gestione"
    echo "15. "
    echo "16. Controlla dati (codice fiscale ed email gSuite duplicate)"
    echo "20. Esci"
}

# Funzione principale
main() {

    checkAllVarsNotEmpty "DOMAIN" "TABELLA_STUDENTI" "TABELLA_STUDENTI_SERALE" "CURRENT_DATE"

    if [ $? -ne 0 ]; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            0)
                echo "Cancello e ricreo la tabella studenti $TABELLA_STUDENTI ..."
                
                # Cancello la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "DROP TABLE IF EXISTS '$TABELLA_STUDENTI';"

                # Creo la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "CREATE TABLE IF NOT EXISTS '$TABELLA_STUDENTI' ( cognome VARCHAR(200) NOT NULL, nome VARCHAR(200) NOT NULL, cod_fisc VARCHAR(200) NOT NULL, cl NUMERIC NOT NULL, sez VARCHAR(200) NOT NULL, e_mail VARCHAR(200), email_pa VARCHAR(200), email_ma VARCHAR(200), email_gen VARCHAR(200), matricola VARCHAR(200), codicesidi VARCHAR(200), datan TEXT, ritira VARCHAR(200), datar VARCHAR(200), email_gsuite VARCHAR(200), aggiunto_il TEXT);"
                ;;
            1)
                echo "Importo e normalizzo i dati dal file CSV $FILE_CSV_STUDENTI ..."
                # Importa CSV dati
                # $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_STUDENTI" "$FILE_CSV_STUDENTI" --csv --empty-null

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_CSV_STUDENTI $TABELLA_STUDENTI"

                # Normalizza dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI 
                SET cod_fisc = TRIM(UPPER(cod_fisc)),
                    email_gsuite = TRIM(LOWER(email_gsuite)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)),
                    datan = date(substr(datan, 7, 4) || '-' || substr(datan, 4, 2) || '-' || substr(datan, 1, 2));"
                
                # Normalizza dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI 
                SET datar = date(substr(datar, 7, 4) || '-' || substr(datar, 4, 2) || '-' || substr(datar, 1, 2))
                WHERE datar is NOT NULL AND datar != '';"
                ;;
            2)
                echo "Visualizza dati in tabella ..."

                $SQLITE_CMD -header -table studenti.db "SELECT cl, sez, cognome, nome, cod_fisc, email_gsuite FROM $TABELLA_STUDENTI ORDER BY cl, sez;"
                ;;
            3)
                echo "Visualizza nuovi studenti ..."
                
                $SQLITE_CMD studenti.db -header -table "SELECT cl, sez, cognome, nome, cod_fisc, aggiunto_il, email_gsuite 
                FROM $TABELLA_STUDENTI 
                WHERE email_gsuite is NULL OR aggiunto_il = '$CURRENT_DATE' 
                ORDER BY cl, sez, cognome, nome;"
                ;;
            4)
                echo "Creo la mail ai nuovi studenti ..."
                
                # creo le mail del diurno
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI
                    SET email_gsuite = 
                    CASE
                        WHEN cl = 1 THEN 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '.' || matricola || '@$DOMAIN'
                        WHEN cl = 2 THEN 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '.' || matricola || '@$DOMAIN'
                        WHEN cl = 3 THEN 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '@$DOMAIN'
                        ELSE 's.' 
                        || REPLACE(REPLACE(nome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(cognome, '''', ''), ' ', '') 
                        || '@$DOMAIN'
                    END,
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE sez NOT LIKE '%_sirio' AND
                    email_gsuite is NULL 
                    AND matricola IS NOT NULL;"

                # creo le mail del serale
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI
                    SET email_gsuite = 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '.' || matricola || '@$DOMAIN',
                      aggiunto_il = '$CURRENT_DATE'
                    WHERE sez LIKE '%_sirio' AND 
                    email_gsuite is NULL
                    AND matricola IS NOT NULL;"
                ;;
            5)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto i nuovi studenti in file CSV ..."
                
                $SQLITE_CMD studenti.db -header -csv "SELECT cl, sez, cognome, nome, email_gsuite, 'Volta2425' as password FROM $TABELLA_STUDENTI WHERE email_gsuite is NULL OR aggiunto_il = '$CURRENT_DATE' ORDER BY cl, sez, cognome, nome" > "$EXPORT_DIR_DATE/nuovi_studenti_$CURRENT_DATE.csv"
                ;;
            6)
                echo "Creo i nuovi studenti su GSuite ..."
                
                # creo le mail del diurno
                $RUN_CMD_WITH_QUERY --command createStudents --group "Studenti/Diurno" --query "SELECT email_gsuite, cognome, nome, cod_fisc, e_mail, ' ' 
                FROM $TABELLA_STUDENTI 
                WHERE sez NOT LIKE '%_sirio' AND 
                    aggiunto_il='$CURRENT_DATE' 
                ORDER BY cl, sez, cognome, nome;"

                # creo le mail del serale
                $RUN_CMD_WITH_QUERY --command createStudents --group "Studenti/Serale" --query "SELECT email_gsuite, cognome, nome, cod_fisc, e_mail, ' ' 
                FROM $TABELLA_STUDENTI 
                WHERE sez LIKE '%_sirio' AND
                    aggiunto_il='$CURRENT_DATE'
                ORDER BY cl, sez, cognome, nome;"
                ;;
            7)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script studenti_CF_$CURRENT_DATE.sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"
                echo 'source "_environment_working_tables.sh"' >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"

                while IFS="," read -r email_gsuite cod_fisc cognome nome cl sez; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI SET email_gsuite = '$email_gsuite' WHERE cod_fisc = '$cod_fisc'\" # $cognome $nome $cl $sez;" >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"

                done < <($SQLITE_CMD -csv studenti.db "select email_gsuite,  cod_fisc, cognome, nome, cl, sez FROM $TABELLA_STUDENTI ORDER BY cod_fisc" | sed "s/\"//g")
                ;;
            8)
                echo "Sospendi account studenti ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "
                select s.email_gsuite 
                from $TABELLA_STUDENTI s 
                WHERE s.email_gsuite IS NOT NULL 
                    AND s.email_gsuite != ''
                    AND s.aggiunto_il='$CURRENT_DATE' 
                ORDER BY s.cl, s.sez, s.cognome, s.nome;"
                ;;
            9)
                echo "Cancella account studenti ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "
                select s.email_gsuite 
                from $TABELLA_STUDENTI s 
                WHERE s.email_gsuite IS NOT NULL 
                    AND s.email_gsuite != ''
                    AND s.aggiunto_il='$CURRENT_DATE' 
                ORDER BY s.cl, s.sez, s.cognome, s.nome;"
                ;;
            12)
                echo "Cancello e ricreo la tabella studenti $TABELLA_STUDENTI_SERALE ..."
                
                # Cancello la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "DROP TABLE IF EXISTS '$TABELLA_STUDENTI_SERALE';"

                # Creo la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "CREATE TABLE IF NOT EXISTS '$TABELLA_STUDENTI_SERALE' ( cognome VARCHAR(200) NOT NULL, nome VARCHAR(200) NOT NULL, cod_fisc VARCHAR(200) NOT NULL, cl NUMERIC NOT NULL, sez VARCHAR(200) NOT NULL, e_mail VARCHAR(200), email_pa VARCHAR(200), email_ma VARCHAR(200), email_gen VARCHAR(200), matricola VARCHAR(200), codicesidi VARCHAR(200), datan TEXT, ritira VARCHAR(200), datar VARCHAR(200), email_gsuite VARCHAR(200), aggiunto_il TEXT);"
                ;;
            13)
                echo "Importo e normalizzo i dati dal file CSV $FILE_CSV_STUDENTI_SERALE ..."
                # Importa CSV dati
                # $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_STUDENTI_SERALE" "$FILE_CSV_STUDENTI_SERALE" --csv --empty-null

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_CSV_STUDENTI_SERALE $TABELLA_STUDENTI_SERALE"

                # Normalizza dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI_SERALE 
                SET cod_fisc = TRIM(UPPER(cod_fisc)),
                    email_gsuite = TRIM(LOWER(email_gsuite)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)),
                    sez = TRIM(sez) || '_sirio',
                    datan = date(substr(datan, 7, 4) || '-' || substr(datan, 4, 2) || '-' || substr(datan, 1, 2));"

                # Normalizza dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_STUDENTI_SERALE 
                SET datar = date(substr(datar, 7, 4) || '-' || substr(datar, 4, 2) || '-' || substr(datar, 1, 2))
                WHERE datar is NOT NULL 
                    AND datar != '';"
                ;;
            14)
                echo "Copio i dati dalla tabella $TABELLA_STUDENTI_SERALE nella tabella $TABELLA_STUDENTI ..."
                
                # Copio i dati del serale nella tabella del diurno
                # unificando i dati ed il processo di gestione
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "INSERT INTO $TABELLA_STUDENTI (cognome, nome, cod_fisc, cl, sez, e_mail, email_pa, email_ma, email_gen, matricola, codicesidi, datan, ritira, datar, email_gsuite, aggiunto_il)
                  SELECT cognome, nome, cod_fisc, cl, sez, e_mail, email_pa, email_ma, email_gen, matricola, codicesidi, datan, ritira, datar, email_gsuite, aggiunto_il
                  FROM $TABELLA_STUDENTI_SERALE AS ss
                  WHERE ss.cod_fisc NOT IN (
                    SELECT s.cod_fisc FROM $TABELLA_STUDENTI AS s
                  );"

                ;;
            16)
                echo "Controllo i dati"
                
                echo "codici fiscali duplicati:"
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "
                  SELECT cod_fisc, cognome, nome, cl, sez, datan, matricola, codicesidi, ritira, datar, email_gsuite
                  FROM $TABELLA_STUDENTI
                  WHERE cod_fisc IN (
                      SELECT cod_fisc
                      FROM $TABELLA_STUDENTI
                      GROUP BY cod_fisc
                      HAVING COUNT(*) > 1
                  );"

                echo "email GSuite duplicate:"
                
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "
                  SELECT cod_fisc, cognome, nome, cl, sez, datan, matricola, codicesidi, ritira, datar, email_gsuite
                  FROM $TABELLA_STUDENTI
                  WHERE email_gsuite IN (
                      SELECT email_gsuite
                      FROM $TABELLA_STUDENTI
                      WHERE email_gsuite IS NOT NULL
                        AND  email_gsuite != ''
                      GROUP BY email_gsuite
                      HAVING COUNT(*) > 1
                  );"
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
  log::_write_log "CONFIG" "Checking config - $(date --date='today' '+%Y-%m-%d %H:%M:%S')"
  log::_write_log "CONFIG" "-----------------------------------------"
  log::_write_log "CONFIG" "Current date: $CURRENT_DATE"
  log::_write_log "CONFIG" "Tabella studenti diurno: $TABELLA_STUDENTI"
  log::_write_log "CONFIG" "Tabella studenti serale: $TABELLA_STUDENTI_SERALE"
  log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
  log::_write_log "CONFIG" "File CVS studenti diurno: $FILE_CSV_STUDENTI"
  log::_write_log "CONFIG" "File CVS studenti serale: $FILE_CSV_STUDENTI_SERALE"
  log::_write_log "CONFIG" "-----------------------------------------"
}

# Show config vars
showConfig

# Avvia la funzione principale
main
