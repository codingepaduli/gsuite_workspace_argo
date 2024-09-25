#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Script per creazione utenti
RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Tabella Ata globale
TABELLA_ATA_GLOBALE="ata_2024_25"

# Tabella di lavoro Ata versionata alla data indicata
TABELLA_ATA="ata_argo_2024_09_25"

# Aggiunge gli insegnanti a classroom
# GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con ata versionata alla data indicata
FILE_ATA_CSV="$BASE_DIR/dati_argo/ata_argo/$TABELLA_ATA.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabelle Ata"
    echo "-------------"
    echo "1. Importa in tabella Ata da CSV"
    echo "2. Aggiorna email, data e flags da tabella globale"
    echo "3. Crea email a nuovi Ata"
    echo "4. Esporta i nuovi Ata in CSV"
    echo "5. Sposta i Ata in tabella globale"
    echo "6. ?? Rimuovi i Ata da tabella globale"
    echo "7. Crea nuovi Ata su GSuite"
    echo "8. Aggiungo Ata su Classroom"
    echo "9. Crea nuovi Ata su WordPress"
    echo "10. Crea script Ata_CF.sh"
    echo "11. Cancella e ricrea gruppo Ata"
    echo "14. Backup gruppi Ata su CSV"
    echo "15. Sospendi (disabilita) Ata"
    echo "16. Elimina Ata"
    echo "17. Visualizza Ata su WordPress"
    echo "18. Elimina Ata su WordPress"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "creo la tabella Ata $TABELLA_ATA da file CSV ..."
                
                # Cancello e ricreo la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_ATA';"
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_ATA' (cognome VARCHAR(200), nome VARCHAR(200), data_nascita VARCHAR(200), codice_fiscale VARCHAR(200), telefono VARCHAR(200), altro_telefono VARCHAR(200), cellulare VARCHAR(200), email_personale VARCHAR(200),email_gsuite VARCHAR(200), aggiunto_il VARCHAR(200));"

                # Importa CSV dati
                $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_ATA" "$FILE_ATA_CSV" --csv --empty-null

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_ATA 
                SET codice_fiscale = TRIM(LOWER(codice_fiscale)),
                    email_personale = TRIM(LOWER(email_personale)),
                    cognome = TRIM(UPPER(cognome)),
                    nome = TRIM(UPPER(nome)) ;"
                ;;
            2)
                echo "aggiorno la tabella Ata da dati precedenti ..."
                
                # aggiorno la tabella Ata da dati precedenti
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_ATA
                  SET email_gsuite = email,
                      aggiunto_il = aggiunto
                  FROM (SELECT d.codice_fiscale AS cod_fis, d.email_gsuite AS email, d.aggiunto_il AS aggiunto FROM $TABELLA_ATA_GLOBALE d) AS d_old
                  WHERE d_old.cod_fis = codice_fiscale;"
                ;;
            3)
                echo "creo la mail al nuovo personale ..."
                
                # creo la mail ai nuovi Ata
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_ATA
                    SET email_gsuite = 'a.' || 
                            REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
                            REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
                        aggiunto_il = '$CURRENT_DATE'
                    WHERE email_gsuite is NULL;"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "esporto i nuovi Ata in CSV ..."
                
                # esporto i nuovi Ata in CSV
                $SQLITE_CMD studenti.db -header -csv "SELECT cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il FROM $TABELLA_ATA WHERE aggiunto_il = '$CURRENT_DATE' ORDER BY cognome" > "$EXPORT_DIR_DATE/nuovi_Ata.csv"
                ;;
            5)
                echo "sposto i Ata nella tabella globale ..."
                
                # sposto i Ata nella tabella globale
                $SQLITE_CMD studenti.db "INSERT INTO $TABELLA_ATA_GLOBALE (cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il)
                    SELECT cognome, nome, data_nascita, codice_fiscale, telefono, altro_telefono, cellulare, email_personale, email_gsuite, aggiunto_il
                    FROM $TABELLA_ATA
                    WHERE aggiunto_il='$CURRENT_DATE' AND 
                    codice_fiscale NOT IN (SELECT codice_fiscale FROM $TABELLA_ATA_GLOBALE);"
                ;;
            6)
                echo "rimuovo i Ata dalla tabella globale ..."
                echo "meglio farlo a mano va..."
                echo "..."
                echo "..."
                
                continue
                # rimuovo i Ata dalla tabella globale
                $SQLITE_CMD studenti.db -header -csv "DELETE FROM $TABELLA_ATA_GLOBALE WHERE aggiunto_il='$CURRENT_DATE' AND codice_fiscale IN (SELECT codice_fiscale FROM $TABELLA_ATA WHERE codice_fiscale IS NOT NULL and codice_fiscale != '');"
                ;;
            7)
                echo "Creo i nuovi Ata su GSuite ..."

                $RUN_CMD_WITH_QUERY --command createUsers --group "NO" --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_ATA
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            8)
                echo "Aggiungo i nuovi Ata a Classroom ..."
                
                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$GRUPPO_CLASSROOM" --query "SELECT email_gsuite
                FROM $TABELLA_ATA
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            9)
                echo "Aggiungo i nuovi Ata su $DOMAIN ..."
                
                $RUN_CMD_WITH_QUERY --command createUsersOnWordPress --group " NO " --query "SELECT email_gsuite, cognome, nome, codice_fiscale, email_personale, cellulare 
                FROM $TABELLA_ATA
                WHERE aggiunto_il='$CURRENT_DATE';"
                ;;
            10)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Crea script .sh ..."
                
                echo "#!/bin/bash" > "$EXPORT_DIR_DATE/Ata_CF.sh"
                echo 'source "_environment.sh"' >> "$EXPORT_DIR_DATE/Ata_CF.sh"
                echo "TABELLA_ATA=\"$TABELLA_ATA\"" >> "$EXPORT_DIR_DATE/Ata_CF.sh"

                while IFS="," read -r email_gsuite codice_fiscale cognome nome; do

                    # Aggiungo il CF negli script
                    echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_ATA SET email_gsuite = '$email_gsuite' WHERE codice_fiscale = '$codice_fiscale'\" # $cognome $nome;" >> "$EXPORT_DIR_DATE/Ata_CF.sh"

                done < <($SQLITE_CMD -csv studenti.db "select email_gsuite,  codice_fiscale, cognome, nome FROM $TABELLA_ATA WHERE aggiunto_il='$CURRENT_DATE' ORDER BY cognome" | sed "s/\"//g")
                ;;
            11)
                echo "Ricrea gruppo Ata ..."
                $RUN_CMD_WITH_QUERY --command deleteGroup --group "Ata" --query " NO "

                $RUN_CMD_WITH_QUERY --command createGroup --group "Ata" --query " NO "

                $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "Ata" --query "select d.email_gsuite from $TABELLA_ATA_GLOBALE d WHERE d.email_gsuite IS NOT NULL;"
                ;;
            14)
                echo "Backup gruppo Ata ..."
                $RUN_CMD_WITH_QUERY --command printGroup --group "Ata" --query " NO " > "$EXPORT_DIR_DATE/Ata_$CURRENT_DATE.csv"
                ;;
            15)
                echo "Sospendi (disabilita) Ata ..."

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select d.email_gsuite from $TABELLA_ATA d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            16)
                echo "Cancella Ata ..."

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select d.email_gsuite from $TABELLA_ATA d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            17)
                echo "Visualizza Ata su wordpress ..."

                $RUN_CMD_WITH_QUERY --command showUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_ATA d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
                ;;
            18)
                echo "Cancella Ata da wordpress ..."

                $RUN_CMD_WITH_QUERY --command deleteUsersOnWordPress --group " NO " --query "select d.email_gsuite from $TABELLA_ATA d WHERE d.email_gsuite IS NOT NULL AND aggiunto_il='$CURRENT_DATE';"
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
