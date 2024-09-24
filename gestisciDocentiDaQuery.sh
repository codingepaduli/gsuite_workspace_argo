#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Script per creazione utenti
RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Tabella docenti globale
TABELLA_DOCENTI_GLOBALE="docenti_2024_25"

# Tabella di lavoro docenti versionata alla data indicata
TABELLA_DOCENTI="docenti_argo_2024_09_24"

# Aggiunge gli insegnanti a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con docenti versionata alla data indicata
FILE_DOCENTI_CSV="$BASE_DIR/dati_argo/docenti_argo/$TABELLA_DOCENTI.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabelle docenti"
    echo "-------------"
    echo "1. Importa in tabella docenti da CSV"
    echo "2. Aggiorna email, data e flags da tabella globale"
    echo "3. Crea email a nuovi docenti"
    echo "4. Esporta i nuovi docenti in CSV"
    echo "5. Sposta i docenti in tabella globale"
    echo "6. ?? Rimuovi i docenti da tabella globale"
    echo "7. Crea nuovi docenti su GSuite"
    echo "8. Aggiungo nuovi docenti su Classroom"
    echo "9. Crea nuovi docenti su WordPress"
    echo "10. Crea script docenti_CF.sh"
    echo "11. Cancella e ricrea gruppo docenti"
    echo "12. Cancella e ricrea gruppo sostegno"
    echo "13. Cancella e ricrea gruppo coordinatori"
    echo "14. Backup gruppi docenti sostegno e coordinatori su CSV"
    echo "15. Sospendi (disabilita) docenti"
    echo "16. Elimina docenti"
    echo "17. Visualizza docenti su WordPress"
    echo "18. Elimina docenti su WordPress"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "creo la tabella docenti $TABELLA_DOCENTI da file CSV ..."
                
                # Cancello e ricreo la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_DOCENTI';"
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_DOCENTI' (cognome VARCHAR(200), nome VARCHAR(200), data_nascita VARCHAR(200), codice_fiscale VARCHAR(200), telefono VARCHAR(200), altro_telefono VARCHAR(200), cellulare VARCHAR(200), email_personale VARCHAR(200),email_gsuite VARCHAR(200), aggiunto_il VARCHAR(200), coordinatore VARCHAR(200), sostegno VARCHAR(200));"

                # Importa CSV dati
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_DOCENTI" "$FILE_DOCENTI_CSV" --csv --empty-null

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_DOCENTI 
                SET codice_fiscale = TRIM(LOWER(codice_fiscale)),
                    email_personale = TRIM(LOWER(email_personale)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)) ;"
                ;;
            2)
                echo "aggiorno la tabella docenti da dati precedenti ..."
                
                # aggiorno la tabella docenti da dati precedenti
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_DOCENTI
                  SET email_gsuite = email,
                      aggiunto_il = aggiunto,
                      coordinatore = coord,
                      sostegno = sos
                  FROM (SELECT d.codice_fiscale AS cod_fis, d.email_gsuite AS email, d.aggiunto_il AS aggiunto, d.coordinatore AS coord, d.sostegno AS sos FROM $TABELLA_DOCENTI_GLOBALE d) AS d_old
                  WHERE d_old.cod_fis = codice_fiscale;"
                ;;
            3)
                echo "creo la mail ai nuovi docenti ..."
                
                # creo la mail ai nuovi docenti
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_DOCENTI
                    SET email_gsuite = 'd.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE email_gsuite is NULL;"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "esporto i nuovi docenti in CSV ..."
                
                # esporto i nuovi docenti in CSV
                $SQLITE_CMD studenti.db -header -csv "SELECT cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il, coordinatore, sostegno FROM $TABELLA_DOCENTI WHERE aggiunto_il = '$CURRENT_DATE' ORDER BY cognome" > "$EXPORT_DIR_DATE/nuovi_docenti.csv"
                ;;
            5)
                echo "sposto i docenti nella tabella globale ..."
                
                # sposto i docenti nella tabella globale
                $SQLITE_CMD studenti.db "INSERT INTO $TABELLA_DOCENTI_GLOBALE (cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il, coordinatore, sostegno)
                    SELECT cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il, coordinatore, sostegno
                    FROM $TABELLA_DOCENTI
                    WHERE aggiunto_il='$CURRENT_DATE' AND 
                    codice_fiscale NOT IN (SELECT codice_fiscale FROM $TABELLA_DOCENTI_GLOBALE);"
                ;;
            6)
                echo "rimuovo i docenti dalla tabella globale ..."
                echo "meglio farlo a mano va..."
                echo "..."
                echo "..."
                
                continue
                # rimuovo i docenti dalla tabella globale
                $SQLITE_CMD studenti.db -header -csv "DELETE FROM $TABELLA_DOCENTI_GLOBALE WHERE aggiunto_il='$CURRENT_DATE' AND codice_fiscale IN (SELECT codice_fiscale FROM $TABELLA_DOCENTI WHERE codice_fiscale IS NOT NULL and codice_fiscale != '');"
                ;;
            7)
                echo "Creo i nuovi docenti su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createUsers --group "NO" --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_DOCENTI
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            8)
                echo "Aggiungo i nuovi docenti a Classroom ..."
                
                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_CLASSROOM" --query "SELECT email_gsuite
                FROM $TABELLA_DOCENTI
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            9)
                echo "Aggiungo i nuovi docenti su $DOMAIN ..."
                
                $RUN_CMD_WITH_QUERY --command createUsersOnWordPress --group " NO " --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_DOCENTI
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            10)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script .sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/docenti_CF.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/docenti_CF.sh"
                echo "TABELLA_DOCENTI=\"$TABELLA_DOCENTI\"" >> "$EXPORT_DIR_DATE/docenti_CF.sh"

                while IFS="," read -r email_gsuite codice_fiscale cognome nome; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_DOCENTI SET email_gsuite = '$email_gsuite' WHERE codice_fiscale = '$codice_fiscale'\" # $cognome $nome;" >> "$EXPORT_DIR_DATE/docenti_CF.sh"

                done < <($SQLITE_CMD -csv studenti.db "select email_gsuite,  codice_fiscale, cognome, nome FROM $TABELLA_DOCENTI WHERE aggiunto_il='$CURRENT_DATE' ORDER BY cognome" | sed "s/\"//g")
                ;;
            11)
                echo "Ricrea gruppo docenti ..."
                $RUN_CMD_WITH_QUERY --command deleteGroup --group "docenti" --query " NO "

                $RUN_CMD_WITH_QUERY --command createGroup --group "docenti" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "docenti" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL;"
                ;;
            12)
                echo "Ricrea gruppo coordinatori ..."
                $RUN_CMD_WITH_QUERY --command deleteGroup --group "test_coo" --query " NO "

                $RUN_CMD_WITH_QUERY --command createGroup --group "test_coo" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "test_coo" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.coordinatore IS NOT NULL;"
                ;;
            13)
                echo "Ricrea gruppo sostegno ..."
                $RUN_CMD_WITH_QUERY --command deleteGroup --group "sostegno" --query " NO "

                $RUN_CMD_WITH_QUERY --command createGroup --group "sostegno" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "sostegno" --query "select d.email_gsuite from $TABELLA_DOCENTI_GLOBALE d WHERE d.email_gsuite IS NOT NULL AND d.sostegno IS NOT NULL;"
                ;;
            14)
                echo "Backup gruppi docenti, coordinatori, sostegno ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "docenti" --query " NO " > "$EXPORT_DIR_DATE/docenti_$CURRENT_DATE.csv"

                $RUN_CMD_WITH_QUERY --command printGroup --group "sostegno" --query " NO " > "$EXPORT_DIR_DATE/sostegno_$CURRENT_DATE.csv"

                $RUN_CMD_WITH_QUERY --command printGroup --group "test_coo" --query " NO" > "$EXPORT_DIR_DATE/test_coo_$CURRENT_DATE.csv"
                ;;
            15)
                echo "Sospendi (disabilita) docenti ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select d.email_gsuite from $TABELLA_DOCENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            16)
                echo "Cancella docenti ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email_gsuite from $TABELLA_DOCENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            17)
                echo "Visualizza docenti su wordpress ..."

                $RUN_CMD_WITH_QUERY --command showUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_DOCENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            18)
                echo "Cancella docenti da wordpress ..."

                $RUN_CMD_WITH_QUERY --command deleteUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_DOCENTI d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
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
