#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 

FILE_CSV="$BASE_DIR/dati_argo/studenti_gsuite/${TABELLA_STUDENTI_GSUITE}_20241224.csv"

# add_to_map "5b_inf_2022_23"  " NO "
add_to_map "5a_et"   " NO "
# add_to_map "5a_inf"  " NO "
# add_to_map "5a_mec"  " NO "
# add_to_map "5a_od"   " NO "
# add_to_map "5b_inf"  " NO "
# add_to_map "5b_mec"  " NO "
# add_to_map "5b_od"   " NO "
# add_to_map "5c_tlc"  " NO "
# add_to_map "5d_tlc"  " NO "
# add_to_map "5f_idd"  " NO "

# Query studenti su GSuite non presenti su Argo
PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
FROM ${TABELLA_STUDENTI_GSUITE} c 
WHERE c.email NOT IN (
    SELECT LOWER(s.email_gsuite) 
    FROM $TABELLA_STUDENTI s
) AND c.email NOT IN (
    SELECT LOWER(ss.email_gsuite) 
    FROM $TABELLA_STUDENTI_SERALE ss
)
ORDER BY c.email;"

# AND c.type = 'Suspended'
# AND c.status = 'Never logged in'
# AND cast(substr(c.status, 1, min(4, length(c.status))) AS INTEGER) < 2024

# Query (tutte le info) studenti su GSuite non presenti su Argo
FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
SELECT c.id, c.name, c.email, c.type, c.status
$PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO"

# Query email studenti su GSuite non presenti su Argo
QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
SELECT c.email
$PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO"

# Importa il file CSV dei docenti (da workspace) e seleziona 
# # quelli che non esistono in tabella personale_argo
# add_to_map "docenti_esportati_da_cancellare" "
# SELECT csv.email
# FROM tabella_CSV csv 
# WHERE SUBSTR(csv.email, 1, 2) = 'd.'
# AND csv.email NOT IN (
#     SELECT pa.email_gsuite
#     FROM personale_argo_2024_11_28 pa
#     WHERE pa.tipo_personale = 'docente' 
# )"

# add_to_map "tutti" "
# SELECT d.email 
# FROM ${TABELLA_STUDENTI_GSUITE} d 
# WHERE d.email IS NOT NULL 
# ORDER BY d.name"

# add_to_map "tutti" " NO "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di GSuite su tabella CSV"
    echo "-------------"
    echo "1. Creo la tabella ${TABELLA_STUDENTI_GSUITE}"
    echo "2. Inporta in tabella i gruppi GSuite"
    echo "3. Importa tutti gli studenti da singolo file CSV nella tabella CSV"
    echo "4. Visualizza studenti nei gruppi GSuite che non sono in Argo"
    echo "5. Rimuovi dai gruppi GSuite gli studenti che non sono in Argo"
    echo "6. Svuota gruppi GSuite"
    echo "7, Cancella gruppi GSuite"
    echo "8. Visualizza studenti su GSuite non presenti su Argo"
    echo "9. Esporta studenti su GSuite non presenti su Argo"
    echo "10. Sospendi studenti su GSuite non presenti su Argo"
    echo "11. Cancella account studenti su GSuite non presenti su Argo"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Creo la tabella ${TABELLA_STUDENTI_GSUITE} ..."

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '${TABELLA_STUDENTI_GSUITE}' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            2)
                echo "Inporta in tabella i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " | $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_STUDENTI_GSUITE}" - --csv --empty-null
                done

                 # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE ${TABELLA_STUDENTI_GSUITE} 
                SET \"group\" = substr(\"group\", 1, instr(\"group\", '@') - 1)"
                ;;
            3)
                echo "Importa tutti gli studenti da singolo file CSV nella tabella CSV"
                
                $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_STUDENTI_GSUITE}" "$FILE_CSV" --csv --empty-null
                ;;
            4)
                echo "Visualizza studenti nei gruppi GSuite che non sono in elenco Argo"
                
                $SQLITE_CMD studenti.db --csv --header "SELECT c.\"group\", c.id, c.name, c.email FROM ${TABELLA_STUDENTI_GSUITE} c WHERE c.email NOT IN (SELECT s.email_gsuite FROM $TABELLA_STUDENTI s)"
                ;;
            5)
                echo "Rimuovi dai gruppi GSuite gli studenti che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do                
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email FROM ${TABELLA_STUDENTI_GSUITE} c WHERE c.\"group\" = '$nome_gruppo' AND c.email NOT IN (SELECT s.email_gsuite FROM $TABELLA_STUDENTI s);"
                done
                ;;
            6)
                echo "Svuota gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email FROM ${TABELLA_STUDENTI_GSUITE} c WHERE c.\"group\" = '$nome_gruppo';"
                done
                ;;
            7)
                echo "Cancella gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            8)
                echo "Visualizza studenti su GSuite non in elenco studenti"

                $SQLITE_CMD studenti.db --csv --header "$FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
                ;;
            9)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Esporta studenti su GSuite non presenti su Argo"

                $SQLITE_CMD studenti.db --csv --header "$FULL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO" > "${EXPORT_DIR_DATE}/studentiSuGSuiteNonInArgo_${CURRENT_DATE}.csv"
                ;;
            10)
                echo "Sospendi studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "$QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
                ;;
            11)
                echo "Cancella account studenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "$QUERY_STUDENTI_SU_GSUITE_NON_ARGO"
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

