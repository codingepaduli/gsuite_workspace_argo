#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

##########################
# Gestione tutti docenti #
##########################

GRUPPO_DOCENTI="docenti_volta"

add_to_map "$GRUPPO_DOCENTI" "
    SELECT LOWER(email_gsuite) AS email_gsuite
    FROM $TABELLA_PERSONALE
    WHERE (email_gsuite IS NOT NULL AND TRIM(email_gsuite != ''))
        AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
            AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
        ) 
        AND UPPER(tipo_personale)=UPPER('docente') 
        AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
    ORDER BY LOWER(email_gsuite); "

###############################
# Fine Gestione tutti docenti #
###############################

###################
# Gestione BIENNI #
###################

SQL_FILTRO_ANNI_PRIMO_BIENNIO=" AND sz.cl IN (1,2)"
SQL_FILTRO_ANNI_SECONDO_BIENNIO=" AND sz.cl IN (3,4)"

SQL_FILTRO_SEZIONI_ELETTRONICA=" AND sz.addr_argo IN ( 'en', 'et' )"
SQL_FILTRO_SEZIONI_INFORMATICA=" AND sz.addr_argo IN ( 'in', 'idd', 'tlt' )"
SQL_FILTRO_SEZIONI_MECCANICA=" AND sz.addr_argo IN ( 'm' )"
SQL_FILTRO_SEZIONI_ODONTOTECNICA=" AND sz.addr_argo IN ( 'od' )"
SQL_FILTRO_SEZIONI_AEREONAUTICA=" AND sz.addr_argo IN ( 'tr' )"

QUERY_DOCENTI_CDC="
SELECT DISTINCT d.email_gsuite
FROM $TABELLA_CDC_ARGO cdc
  INNER JOIN $TABELLA_SEZIONI sz
  ON cdc.classi = (sz.cl || sz.sez_argo)
  INNER JOIN $TABELLA_PERSONALE d
  ON (d.cognome || ' ' || d.nome) = cdc.docente 
WHERE d.email_gsuite is NOT NULL AND d.email_gsuite != '' 
AND d.tipo_personale = 'docente'
"

QUERY_DOCENTI_PRIMO_BIENNIO="$QUERY_DOCENTI_CDC $SQL_FILTRO_ANNI_PRIMO_BIENNIO"

QUERY_DOCENTI_SECONDO_BIENNIO="$QUERY_DOCENTI_CDC $SQL_FILTRO_ANNI_SECONDO_BIENNIO"

add_to_map "primo_biennio_elettronica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_ELETTRONICA ORDER BY docente"
add_to_map "primo_biennio_informatica"  " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_INFORMATICA ORDER BY docente;"
add_to_map "primo_biennio_meccanica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_MECCANICA ORDER BY docente; "
add_to_map "primo_biennio_odontotecnica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_ODONTOTECNICA ORDER BY docente; "
add_to_map "primo_biennio_aereonautica"   " $QUERY_DOCENTI_PRIMO_BIENNIO $SQL_FILTRO_SEZIONI_AEREONAUTICA ORDER BY docente; "

add_to_map "secondo_biennio_elettronica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_ELETTRONICA ORDER BY docente"
add_to_map "secondo_biennio_informatica"  " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_INFORMATICA ORDER BY docente;"
add_to_map "secondo_biennio_meccanica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_MECCANICA ORDER BY docente; "
add_to_map "secondo_biennio_odontotecnica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_ODONTOTECNICA ORDER BY docente; "
add_to_map "secondo_biennio_aereonautica"   " $QUERY_DOCENTI_SECONDO_BIENNIO $SQL_FILTRO_SEZIONI_AEREONAUTICA ORDER BY docente; "

########################
# Fine Gestione BIENNI #
########################

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi docenti (da tabella $TABELLA_GRUPPI)"
    echo "-------------"
    echo "1. Creo la tabella $TABELLA_GRUPPI"
    echo "2. Crea tutti i gruppi su GSuite"
    echo "3. Backup tutti i gruppi su CSV distinti..."
    echo "7. "
    echo "8. Inserisci membri nei gruppi  ..."
    echo "9. Rimuovi membri dai gruppi  ..."
    echo "10. "
    echo "11. Normalizza tabella"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            10)
                echo "Creo la tabella $TABELLA_GRUPPI"

                # Cancello la tabella
                # $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_GRUPPI';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_GRUPPI' (nome_gruppo VARCHAR(200), codice_fiscale VARCHAR(200), email_gsuite VARCHAR(200), email_personale VARCHAR(200), aggiunto_il VARCHAR(200));"
                ;;
            2)
                echo "Crea tutti i gruppi su GSuite ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            3)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Backup tutti i gruppi su CSV distinti ..."

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}" > "$EXPORT_DIR_DATE/${nome_gruppo}_${CURRENT_DATE}.csv"

                  echo "Saved in file $EXPORT_DIR_DATE/${nome_gruppo}_${CURRENT_DATE}.csv"
                done
                ;;
            8)
                echo "Inserisci membri nei gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Inserisco membri nel gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"
                  $SQLITE_CMD studenti.db "${gruppi[$nome_gruppo]}"

                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            9)
                echo "Rimuovi membri dai gruppi  ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Rimuovo membri dal gruppo $nome_gruppo ...!"
                  echo "query ${gruppi[$nome_gruppo]} ...!"

                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            11)
                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_GRUPPI 
                SET nome_gruppo = TRIM(LOWER(nome_gruppo)),
                    codice_fiscale = TRIM(UPPER(codice_fiscale)),
                    email_gsuite = TRIM(UPPER(email_gsuite)),
                    email_personale = TRIM(UPPER(email_personale));"
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
