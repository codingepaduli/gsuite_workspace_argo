#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella sezioni $TABELLA_SEZIONI"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
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

    checkAllVarsNotEmpty "DOMAIN" "TABELLA_STUDENTI" "TABELLA_STUDENTI_SERALE" "TABELLA_SEZIONI"

    if [ $? -ne 0 ]; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi
    
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Crea tabella sezioni a partire dai dati degli studenti ..."
                
                # Cancello la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "DROP TABLE IF EXISTS '$TABELLA_SEZIONI';"

                # Creo la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "CREATE TABLE IF NOT EXISTS '$TABELLA_SEZIONI' ( cl NUMERIC, letter VARCHAR(200), addr_argo VARCHAR(200), sez_argo NUMERIC, addr_gsuite VARCHAR(200), sez_gsuite VARCHAR(200), sezione_gsuite VARCHAR(200));"
                ;;
            2)
                echo "Crea dati delle sezioni ..."
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "INSERT INTO $TABELLA_SEZIONI (cl, sez_argo, letter, addr_argo, addr_gsuite, sez_gsuite, sezione_gsuite) 
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
        read -p "Premi Invio per continuare..." -r _
    done
}

# Avvia la funzione principale
main
