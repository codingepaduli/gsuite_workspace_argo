#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_10_14"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella sezioni"
    echo "-------------"
    echo "1. Crea tabella sezioni a partire dai dati degli studenti"
    echo "2. Crea dati delle sezioni"
    echo "3. Visualizza sezioni"
    echo "4. Esporto le sezioni in file CSV"
    echo " "
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Crea tabella sezioni a partire dai dati degli studenti ..."
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_SEZIONI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_SEZIONI' ( cl NUMERIC, letter VARCHAR(200), addr_argo VARCHAR(200), sez_argo NUMERIC, addr_gsuite VARCHAR(200), sez_gsuite VARCHAR(200), sezione_gsuite VARCHAR(200));"

                # Importa CSV dati
                # $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_SEZIONI" "$FILE_CSV_STUDENTI" --csv --empty-null
                ;;
            2)
                echo "Crea dati delle sezioni ..."
                $SQLITE_CMD studenti.db "INSERT INTO $TABELLA_SEZIONI (cl, sez_argo, letter, addr_argo, addr_gsuite, sez_gsuite, sezione_gsuite) 
                SELECT cl, sez_argo, letter, addr_argo, addr_gsuite, 
                  letter || '_' || addr_gsuite AS sez_gsuite,
                  cl || letter || '_' || addr_gsuite AS sezione_gsuite
                FROM (
                  SELECT DISTINCT 
                    TRIM(sa.cl) AS cl,
                    TRIM(sa.sez) AS sez_argo,
                    TRIM(SUBSTR(sa.sez,1,1)) AS letter,
                    TRIM(SUBSTR(sa.sez,2)) AS addr_argo,
                    CASE
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'in' THEN 'inf' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'm' THEN 'mec' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'tlt' THEN 'tlc' 
                          WHEN TRIM(SUBSTR(sa.sez,2)) = 'tr' THEN 'aer' 
                          ELSE TRIM(SUBSTR(sa.sez,2))
                    END AS addr_gsuite
                  FROM $TABELLA_STUDENTI sa 
                  ORDER BY sa.cl, sa.sez
                )"
                ;;
            3)
                echo "Visualizza dati delle sezioni ..."
                $SQLITE_CMD -header -table studenti.db "SELECT * FROM $TABELLA_SEZIONI ORDER BY cl, sez_argo;"
                ;;
            4)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporto le sezioni in file CSV ..."
                
                $SQLITE_CMD studenti.db -header -csv "SELECT * FROM $TABELLA_SEZIONI ORDER BY cl, sez_argo;" > "$EXPORT_DIR_DATE/${TABELLA_SEZIONI}_$CURRENT_DATE.csv"
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