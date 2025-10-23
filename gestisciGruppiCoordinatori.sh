#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

GRUPPO_COORDINATORI="coordinatori"
GRUPPO_COORDINATORI_PRIME="coordinatori_prime"
GRUPPO_COORDINATORI_SECONDE="coordinatori_seconde"
GRUPPO_COORDINATORI_TERZE="coordinatori_terze"
GRUPPO_COORDINATORI_QUARTE="coordinatori_quarte"
GRUPPO_COORDINATORI_QUINTE="coordinatori_quinte"

QUERY_COORDINATORI="
    FROM $TABELLA_SEZIONI sz 
        LEFT JOIN $TABELLA_PERSONALE d 
        ON LOWER(sz.email_coordinatore) = LOWER(d.email_gsuite) 
          AND LOWER(sz.email_coordinatore) IS NOT NULL 
          AND LOWER(sz.email_coordinatore) != '' 
    WHERE 1=1 
        AND (
            (d.email_gsuite IS NOT NULL AND TRIM(d.email_gsuite != ''))
            AND UPPER(tipo_personale)=UPPER('docente') 
            AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
        ) "

add_to_map "$GRUPPO_COORDINATORI" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (1, 2, 3, 4, 5)
ORDER BY LOWER(email_coordinatore);"

add_to_map "$GRUPPO_COORDINATORI_PRIME" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (1)
ORDER BY LOWER(email_coordinatore);"

add_to_map "$GRUPPO_COORDINATORI_SECONDE" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (2)
ORDER BY LOWER(email_coordinatore);"

add_to_map "$GRUPPO_COORDINATORI_TERZE" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (3)
ORDER BY LOWER(email_coordinatore);"

add_to_map "$GRUPPO_COORDINATORI_QUARTE" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (4)
ORDER BY LOWER(email_coordinatore);"

add_to_map "$GRUPPO_COORDINATORI_QUINTE" "
SELECT DISTINCT LOWER(email_coordinatore) as email_coordinatore 
    $QUERY_COORDINATORI
    AND cl IN (5)
ORDER BY LOWER(email_coordinatore);"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione Coordinatori"
    echo "-------------"
    echo "2. Crea tutti i gruppi coordinatori da GSuite"
    echo "3. Cancella tutti i gruppi coordinatori su GSuite ..."
    echo "4. "
    echo "5. Visualizza $GRUPPO_COORDINATORI con classi associate"
    echo "6. Salva $GRUPPO_COORDINATORI con classi associate su CSV"
    echo "7. "
    echo "8. Inserisci membri nei gruppi  ..."
    echo "9. Rimuovi membri dai gruppi  ..."
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            2)
                echo "Crea tutti i gruppi coordinatori su GSuite ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            3)
                echo "Cancella tutti i gruppi coordinatori su GSuite ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Cancello gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            5)
                echo "Visualizza coordinatori con classi associate"
                
                $SQLITE_CMD studenti.db -header -table "
                SELECT UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
                    LOWER(sz.email_coordinatore) as email_coordinatore, 
                    UPPER(d.cognome) AS cognome, UPPER(d.nome) AS nome
                $QUERY_COORDINATORI
                    -- visualizzo classi con coordinatori non presenti
                    OR (d.email_gsuite IS NULL OR TRIM(d.email_gsuite = ''))
                ORDER BY UPPER(sezione_gsuite);"
                ;;
            6)
                echo "6. Salva $GRUPPO_COORDINATORI con classi associate su CSV"

                mkdir -p "$EXPORT_DIR_DATE"

                $SQLITE_CMD studenti.db -header -csv "
                SELECT UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
                    LOWER(sz.email_coordinatore) as email_coordinatore, 
                    UPPER(d.cognome) AS cognome, UPPER(d.nome) AS nome
                $QUERY_COORDINATORI
                    -- visualizzo classi con coordinatori non presenti
                    OR (d.email_gsuite IS NULL OR TRIM(d.email_gsuite = ''))
                ORDER BY UPPER(sezione_gsuite);
                " > "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.csv"
                ;;
            7)
                echo "6. Salva $GRUPPO_COORDINATORI con classi associate su file SQL"

                mkdir -p "$EXPORT_DIR_DATE"
                
                {
                      echo "#!/bin/bash"
                      echo 'source "_environment.sh"'
                      echo 'source "_environment_working_tables.sh"'
                      echo 'source "./_maps.sh"'
                      echo " "
                } > "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.sh"
                
                while IFS="," read -r sezione_gsuite email_coordinatore cognome nome; do
                    {
                        echo '$SQLITE_CMD studenti.db -csv "'
                        echo 'UPDATE $TABELLA_SEZIONI'
                        echo "SET email_coordinatore='$email_coordinatore'"
                        echo "WHERE sezione_gsuite='$sezione_gsuite'; -- $cognome $nome"
                        echo '"'
                    } >> "${EXPORT_DIR_DATE}/coordinatori_${CURRENT_DATE}.sh"
                done < <($SQLITE_CMD studenti.db -csv "
                SELECT UPPER(sz.sezione_gsuite) AS sezione_gsuite, 
                    LOWER(sz.email_coordinatore) as email_coordinatore, 
                    UPPER(d.cognome) AS cognome, UPPER(d.nome) AS nome
                $QUERY_COORDINATORI
                    -- visualizzo classi con coordinatori non presenti
                    OR (d.email_gsuite IS NULL OR TRIM(d.email_gsuite = ''))
                ORDER BY UPPER(sezione_gsuite);" | sed "s/\"//g")
                ;;
            8)
                echo "Inserisci membri nei gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            9)
                echo "Rimuovi membri dai gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ..."

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
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
