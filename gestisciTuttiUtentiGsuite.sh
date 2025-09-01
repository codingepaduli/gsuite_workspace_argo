#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV di lavoro con personale versionata alla data indicata
FILE_UTENTI_CSV="$BASE_DIR/dati_gsuite/$TABELLA_UTENTI_GSUITE.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella di tutti gli utenti GSuite"
    echo "-------------"
    echo "1. Cancello e ricreo la tabella di tutti gli utenti GSuite"
    echo "2. Importo e normalizzo i dati dal file CSV"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "1. Cancello e ricreo la tabella del personale"
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_UTENTI_GSUITE';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_UTENTI_GSUITE' ( 
                    nome VARCHAR(200),
                    cognome VARCHAR(200),
                    email_gsuite VARCHAR(200),
                    stato_utente VARCHAR(200),
                    ultimo_login TEXT,
                    spazio_email REAL,
                    spazio_storage REAL,
                    spazio_gdrive REAL,
                    selezionato_il TEXT);"
                ;;
            2)
                echo "2. Importo e normalizzo i dati dal file CSV $FILE_UTENTI_CSV ..."
                
                # Importa CSV dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_UTENTI_CSV $TABELLA_UTENTI_GSUITE"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_UTENTI_GSUITE 
                SET nome = TRIM(UPPER(nome)),
                    cognome = TRIM(UPPER(cognome)),
                    email_gsuite = TRIM(LOWER(email_gsuite)),
                    stato_utente = TRIM(UPPER(stato_utente)),
                    ultimo_login = TRIM(UPPER(ultimo_login)),
                    spazio_email = CAST(spazio_email AS REAL) * 1000,
                    spazio_storage = CAST(spazio_storage AS REAL) * 1000,
                    spazio_gdrive = CAST(spazio_gdrive AS REAL) * 1000,
                    selezionato_il = TRIM(UPPER(selezionato_il));"
                
                # Normalizza date
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_UTENTI_GSUITE 
                SET ultimo_login = date(substr(ultimo_login, 1, 4) || '-' || substr(ultimo_login, 6, 2) || '-' || substr(ultimo_login, 9, 2))
                WHERE ultimo_login is NOT NULL AND TRIM(UPPER(ultimo_login)) != UPPER('Never logged in');"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_UTENTI_GSUITE 
                SET ultimo_login = date('2000-01-01')
                WHERE ultimo_login is NOT NULL AND TRIM(UPPER(ultimo_login)) = UPPER('Never logged in');"
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
