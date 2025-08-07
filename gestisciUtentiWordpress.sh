#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# Aggiunge gli insegnanti a classroom
# GRUPPO_CLASSROOM="insegnanti_classe"

# File CSV di lavoro con personale versionata alla data indicata
FILE_UTENTI_WORDPRESS_CSV="$BASE_DIR/dati_argo/utenti_wordpress/utenti_wordpress_2025-01-08.csv"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabelle Wordpress"
    echo "-------------"
    echo "1. Crea o ricrea) la tabella Wordpress ${TABELLA_UTENTI_WORDPRESS}"
    echo "2. Esporta utenti da Wordpress in file CSV"
    echo "3. Importa utenti Wordpress in tabella ${TABELLA_UTENTI_WORDPRESS} da file CSV"
    echo "4. Cancella utenti"
    
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Creo la tabella $TABELLA_UTENTI_WORDPRESS ..."

                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '${TABELLA_UTENTI_WORDPRESS}';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '${TABELLA_UTENTI_WORDPRESS}' (id NUMBER, slug VARCHAR(200), name VARCHAR(200), email VARCHAR(200));"
                ;;
            2)
                mkdir -p "$EXPORT_DIR_DATE"

                # https://www.isisvoltaaversa.it/author/ciro-attanasioisisvoltaaversa-it/

                # _fields=id,email,nickname,registered_date,roles,slug,name,status,link

                curl -X GET --no-progress-meter "${WORDPRESS_URL}wp-json/wp/v2/users/2010" -u "$WORDPRESS_ACCESS_TOKEN" 

                echo "get from page $page"

                echo "id,slug,name" > "${EXPORT_DIR_DATE}/utenti_wordpress_${CURRENT_DATE}.csv"
                
                for ((page=1; page<=WORDPRESS_NUM_PAGES_TO_SEARCH; page++))
                do
                  curl -X GET --no-progress-meter "${WORDPRESS_URL}wp-json/wp/v2/users?search=&_fields=id,slug,name&per_page=100&page=$page" -u "$WORDPRESS_ACCESS_TOKEN" | python3 jsonReaderUtil.py >> "${EXPORT_DIR_DATE}/utenti_wordpress_${CURRENT_DATE}.csv"
                done
                ;;
            3)
                echo "Importo il file CSV ..."
                
                # Importa CSV dati (--skip 1 salta l'header del file CSV)
                $SQLITE_CMD studenti.db --csv ".import --skip 1 $FILE_UTENTI_WORDPRESS_CSV $TABELLA_UTENTI_WORDPRESS"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_UTENTI_WORDPRESS 
                SET slug = TRIM(LOWER(slug)),
                    name = TRIM(LOWER(name)),
                    email = TRIM(LOWER(email)) ;"
                ;;
            4)
                echo "Cancella personale da wordpress ..."

                $RUN_CMD_WITH_QUERY --command deleteUsersOnWordPress --group " NO " --query "select u.id from $TABELLA_UTENTI_WORDPRESS u WHERE u.id = 20000;"
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
