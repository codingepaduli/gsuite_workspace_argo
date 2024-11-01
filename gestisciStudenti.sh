#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_10_31"

# File CSV 
FILE_CSV_STUDENTI="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella Studenti"
    echo "-------------"
    echo "1. Importa in tabella studenti da CSV"
    echo "2. Visualizza dati in tabella"
    echo "3. Visualizza nuovi studenti"
    echo "4. Creo la mail ai nuovi studenti"
    echo "5. Esporto i nuovi studenti in file CSV"
    echo "6. Creo il nuovi studenti su GSuite"
    echo "7. Crea script studenti_CF.sh"
    echo "8. Sospendi studenti"
    echo "9. Cancella studenti"
    echo "10. Creo la mail ai nuovi studenti del serale"
    echo "11. Creo i nuovi studenti del serale su GSuite ..."
    echo "12. "
    echo "13. "
    echo "14. "
    echo "15. "
    echo "16. "
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Cancello, ricreo e normalizzo la tabella studenti $TABELLA_STUDENTI importando il file CSV ..."
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_STUDENTI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_STUDENTI' ( cognome VARCHAR(200), nome VARCHAR(200), cod_fisc VARCHAR(200), cl NUMERIC, sez VARCHAR(200), e_mail VARCHAR(200), email_pa VARCHAR(200), email_ma VARCHAR(200), email_gen VARCHAR(200), matricola VARCHAR(200), codicesidi VARCHAR(200), datan VARCHAR(200), ritira VARCHAR(200), datar VARCHAR(200), email_gsuite VARCHAR(200), aggiunto_il VARCHAR(200));"

                # Importa CSV dati
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_STUDENTI" "$FILE_CSV_STUDENTI" --csv --empty-null

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_STUDENTI 
                SET cod_fisc = TRIM(UPPER(cod_fisc)),
                    email_gsuite = TRIM(LOWER(email_gsuite)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome));"
                ;;
            2)
                echo "Visualizza dati in tabella ..."

                $SQLITE_CMD -header -table studenti.db "SELECT cl, sez, cognome, nome, cod_fisc, email_gsuite FROM $TABELLA_STUDENTI ORDER BY cl, sez;"
                ;;
            3)
                echo "Visualizza nuovi studenti ..."
                
                $SQLITE_CMD studenti.db -header -table "SELECT cl, sez, cognome, nome, cod_fisc, aggiunto_il, email_gsuite FROM $TABELLA_STUDENTI WHERE email_gsuite is NULL OR aggiunto_il = '$CURRENT_DATE' ORDER BY cl, sez, cognome, nome;"
                ;;
            4)
                echo "Creo la mail ai nuovi studenti ..."
                
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_STUDENTI
                    SET email_gsuite = 
                    CASE
                        WHEN cl = 1 THEN 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '.' || matricola || '@$DOMAIN'
                        WHEN cl = 2 THEN 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '@$DOMAIN'
                        ELSE 's.' 
                        || REPLACE(REPLACE(nome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(cognome, '''', ''), ' ', '') 
                        || '@$DOMAIN'
                    END,
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE email_gsuite is NULL
                    AND matricola IS NOT NULL;"
                ;;
            5)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto i nuovi studenti in file CSV ..."
                
                $SQLITE_CMD studenti.db -header -csv "SELECT cl, sez, cognome, nome, email_gsuite, 'Volta2425' as password FROM $TABELLA_STUDENTI WHERE email_gsuite is NULL OR aggiunto_il = '$CURRENT_DATE' ORDER BY cl, sez, cognome, nome" > "$EXPORT_DIR_DATE/nuovi_studenti_$CURRENT_DATE.csv"
                ;;
            6)
                echo "Creo i nuovi studenti su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createStudents --group "Studenti/Diurno" --query "SELECT email_gsuite, cognome, nome, cod_fisc, e_mail, ' ' FROM $TABELLA_STUDENTI WHERE aggiunto_il='$CURRENT_DATE' ORDER BY cl, sez, cognome, nome;"
                ;;
            7)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script studenti_CF_$CURRENT_DATE.sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"
                echo "TABELLA_STUDENTI=\"$TABELLA_STUDENTI\"" >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"

                while IFS="," read -r email_gsuite cod_fisc cognome nome cl sez; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI SET email_gsuite = '$email_gsuite' WHERE cod_fisc = '$cod_fisc'\" # $cognome $nome $cl $sez;" >> "$EXPORT_DIR_DATE/studenti_CF_$CURRENT_DATE.sh"

                done < <($SQLITE_CMD -csv studenti.db "select email_gsuite,  cod_fisc, cognome, nome, cl, sez FROM $TABELLA_STUDENTI ORDER BY cod_fisc" | sed "s/\"//g")
                ;;
            8)
                echo "Sospendi account studenti ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select d.email_gsuite from $TABELLA_STUDENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE' ORDER BY cl, sez, cognome, nome;"
                ;;
            9)
                echo "Cancella account studenti ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email_gsuite from $TABELLA_STUDENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE' ORDER BY cl, sez, cognome, nome;"
                ;;
            10)
                echo "Creo la mail ai nuovi studenti del serale ..."
                
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_STUDENTI
                    SET email_gsuite = 's.' 
                        || REPLACE(REPLACE(cognome, '''',''), ' ', '') 
                        || '.' || REPLACE(REPLACE(nome, '''', ''), ' ', '') 
                        || '.' || matricola || '@$DOMAIN',
                      aggiunto_il = '$CURRENT_DATE'
                    WHERE email_gsuite is NULL
                    AND matricola IS NOT NULL;"
                ;;
            11)
                echo "Creo i nuovi studenti del serale su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createStudents --group "Studenti/Serale" --query "SELECT email_gsuite, cognome, nome, cod_fisc, e_mail, ' ' FROM $TABELLA_STUDENTI WHERE aggiunto_il='$CURRENT_DATE' ORDER BY cl, sez, cognome, nome;"
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
