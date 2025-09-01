#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 
FILE_CSV="$BASE_DIR/dati_argo/studenti_gsuite/${TABELLA_STUDENTI_GSUITE}.csv"

# Seleziona le classi
SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Popolo le classi
while IFS="," read -r sezione_gsuite; do
    add_to_map "$sezione_gsuite"   " NO "
    true;
done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                
# add_to_map "5b_inf_2022_23"  " NO "

# Query studenti su GSuite non presenti su Argo
PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
FROM ${TABELLA_STUDENTI_GSUITE} c 
    INNER JOIN $TABELLA_SEZIONI sz 
    ON UPPER(sz.sezione_gsuite) = UPPER(c.\"group\")
    WHERE
        -- filtri sezioni
        1=1 
        $SQL_FILTRO_ANNI 
        $SQL_FILTRO_SEZIONI
        AND LOWER(c.email) NOT IN (
            SELECT LOWER(sa.email_gsuite) 
            FROM $TABELLA_STUDENTI sa
                INNER JOIN $TABELLA_SEZIONI sz 
                ON sa.sez = sz.sez_argo AND sa.cl =sz.cl
            WHERE 
                -- filtri sezioni
                1=1 
                $SQL_FILTRO_ANNI 
                $SQL_FILTRO_SEZIONI
        )
"

# AND c.type = 'Suspended'
# AND c.status = 'Never logged in'
# AND CAST(SUBSTR(c.status, 1, MIN(4, LENGTH(c.status))) AS INTEGER) < 2024
# AND LOWER(SUBSTR(c.email, 1, MIN(2, LENGTH(c.email)))) IN ('s.')

# Query (tutte le info) studenti su GSuite non presenti su Argo
FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
SELECT c.id, c.name, c.email, c.type, c.status
$PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Query email studenti su GSuite non presenti su Argo
QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
SELECT c.email
$PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Query studenti su Argo non presenti su GSuite 
QUERY_STUDENTI_SU_ARGO_NON_GSUITE="
  SELECT sz.cl AS cl, sz.sez_argo AS sez_argo, sz.sezione_gsuite AS sez_gsuite, sa.cognome AS cognome, sa.nome AS nome, sa.email_gsuite as email_gsuite
  FROM $TABELLA_STUDENTI sa 
    INNER JOIN $TABELLA_SEZIONI sz 
    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl
  WHERE 
    -- filtri sezioni
    1=1 
    $SQL_FILTRO_ANNI 
    $SQL_FILTRO_SEZIONI
    -- filtri studenti
    AND sa.email_gsuite IS NOT NULL
    AND sa.email_gsuite != ''
    AND (sa.datar IS NULL OR sa.datar = '') 
    AND LOWER(sa.email_gsuite) NOT IN (
      SELECT LOWER(c.email)
      FROM ${TABELLA_STUDENTI_GSUITE} c
        INNER JOIN $TABELLA_SEZIONI sz 
        ON UPPER(sz.sezione_gsuite) = UPPER(c.\"group\")
      WHERE 
        -- filtri sezioni
        1=1 
        $SQL_FILTRO_ANNI 
        $SQL_FILTRO_SEZIONI
  )
"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di GSuite su tabella ${TABELLA_STUDENTI_GSUITE}"
    echo "-------------"
    echo "1. Creo la tabella ${TABELLA_STUDENTI_GSUITE}"
    echo "2. Importa in tabella i gruppi GSuite"
    echo "3. Importa tutti gli studenti da singolo file CSV nella tabella"
    echo "4. Visualizza studenti nei gruppi GSuite che non sono in Argo"
    echo "5. Rimuovi dai gruppi GSuite gli studenti che non sono in Argo"
    echo "6. Svuota gruppi GSuite"
    echo "7, Cancella gruppi GSuite"
    echo "8. Visualizza studenti su GSuite non presenti su Argo"
    echo "9. Esporta studenti su GSuite non presenti su Argo"
    echo "10. Sospendi studenti su GSuite non presenti su Argo"
    echo "11. Cancella account studenti su GSuite non presenti su Argo"
    echo "13. Visualizza studenti su Argo con mail non presente su GSuite"
    
    echo "18. Sospendi tutti gli studenti in tabella GSUITE ${TABELLA_STUDENTI_GSUITE}"
    echo "19. ELIMINA tutti gli studenti in tabella GSUITE ${TABELLA_STUDENTI_GSUITE}"
    
    echo "20. Esci"
}

# Funzione principale
main() {

    if ! checkAllVarsNotEmpty "DOMAIN" "TABELLA_STUDENTI" "TABELLA_STUDENTI_GSUITE" "TABELLA_SEZIONI"; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Creo la tabella ${TABELLA_STUDENTI_GSUITE} ..."

                # Creo la tabella
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "CREATE TABLE IF NOT EXISTS '${TABELLA_STUDENTI_GSUITE}' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            2)
                echo "Importa in tabella i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO; " | $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_STUDENTI_GSUITE}" - --csv --empty-null
                done

                echo "Normalizzo dati"

                # Normalizza dati (rimuove @$DOMAIN)"
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE ${TABELLA_STUDENTI_GSUITE} 
                SET \"group\" = substr(\"group\", 1, instr(\"group\", '@') - 1)
                WHERE \"group\" LIKE '%@%';"

                # Normalizza dati (uppercase group)"
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE ${TABELLA_STUDENTI_GSUITE} 
                SET \"group\" = UPPER(\"group\");"
                ;;
            3)
                echo "Importa tutti gli studenti da singolo file CSV nella tabella"
                
                $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_STUDENTI_GSUITE}" "$FILE_CSV" --csv --empty-null
                ;;
            4)
                echo "Visualizza studenti nei gruppi GSuite che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "SELECT c.\"group\", c.id, c.name, c.email $PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO
                  AND c.\"group\" = '$nome_gruppo'
                  ORDER BY c.email;"
                done
                ;;
            5)
                echo "Rimuovi dai gruppi GSuite gli studenti che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do                
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email $PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO 
                  AND c.\"group\" = '$nome_gruppo'
                  ORDER BY c.email;"
                done
                ;;
            6)
                echo "Svuota gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email FROM ${TABELLA_STUDENTI_GSUITE} c WHERE c.\"group\" = '$nome_gruppo' ORDER BY c.email;"
                done
                ;;
            7)
                echo "Cancella gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            8)
                echo "Visualizza studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query  "$FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
                ;;
            9)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Esporta studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "$FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO" > "${EXPORT_DIR_DATE}/studentiSuGSuiteNonInArgo_${CURRENT_DATE}.csv"
                ;;
            10)
                echo "Sospendi studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "$QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
                ;;
            11)
                echo "Cancella account studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "$QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
                ;;
            13)
                echo "Visualizza studenti su Argo con mail non presente su GSuite"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query  "$QUERY_STUDENTI_SU_ARGO_NON_GSUITE
                "
                ;;
            18)
                echo "18. Sospendi tutti gli studenti in tabella GSUITE ${TABELLA_STUDENTI_GSUITE}"

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "select c.email FROM ${TABELLA_STUDENTI_GSUITE} c ORDER BY c.\"group\";"
                ;;
            19)
                echo "19. ELIMINA tutti gli studenti in tabella GSUITE ${TABELLA_STUDENTI_GSUITE}"

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "select c.email FROM ${TABELLA_STUDENTI_GSUITE} c ORDER BY c.\"group\""
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
  if log::level_is_active "CONFIG"; then
    log::_write_log "CONFIG" "Checking config - $(date --date='today' '+%Y-%m-%d %H:%M:%S')"
    log::_write_log "CONFIG" "-----------------------------------------"
    log::_write_log "CONFIG" "Current date: $CURRENT_DATE"
    log::_write_log "CONFIG" "Tabella studenti diurno: $TABELLA_STUDENTI"
    log::_write_log "CONFIG" "Tabella sezioni: $TABELLA_SEZIONI"
    log::_write_log "CONFIG" "Tabella studenti gSuite: $TABELLA_STUDENTI_GSUITE"
    log::_write_log "CONFIG" "File CSV import: $FILE_CSV"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

# Show config vars
showConfig

# Avvia la funzione principale
main
