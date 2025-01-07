#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 
FILE_CSV="$BASE_DIR/dati_argo/docenti_gsuite/${TABELLA_DOCENTI_GSUITE}.csv"

add_to_map "coordinatori"   " NO "

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# add_to_map "$GRUPPO_CLASSROOM"   " NO "

# add_to_map "docenti_volta" "
# SELECT csv.email
# FROM tabella_CSV csv 
# WHERE SUBSTR(csv.email, 1, 2) = 'd.'
# AND csv.email NOT IN (
#     SELECT pa.email_gsuite
#     FROM personale_argo_2024_11_28 pa
#     WHERE pa.tipo_personale = 'docente' 
# ); "

# Query docenti su GSuite non presenti su Argo
PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
FROM ${TABELLA_DOCENTI_GSUITE} c 
WHERE c.email NOT IN (
    SELECT LOWER(d.email_gsuite) 
    FROM $TABELLA_PERSONALE d
    WHERE d.tipo_personale = 'docente'
)
"

# AND d.type = 'Suspended'
# AND d.status = 'Never logged in'
# AND cast(substr(d.status, 1, min(4, length(d.status))) AS INTEGER) < 2024
# AND SUBSTR(csv.email, 1, 2) = 'd.'

# Query (tutte le info) docenti su GSuite non presenti su Argo
FULL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
SELECT c.id, c.name, c.email, c.type, c.status
$PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Query email docenti su GSuite non presenti su Argo
QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
SELECT c.email
$PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di GSuite su tabella ${TABELLA_DOCENTI_GSUITE}"
    echo "-------------"
    echo "1. Creo la tabella ${TABELLA_DOCENTI_GSUITE}"
    echo "2. Inporta in tabella i gruppi GSuite"
    echo "3. Importa tutti i docenti da singolo file CSV nella tabella"
    echo "4. Visualizza docenti nei gruppi GSuite che non sono in Argo"
    echo "5. Rimuovi dai gruppi GSuite i docenti che non sono in Argo"
    echo "6. Svuota gruppi GSuite"
    echo "7, Cancella gruppi GSuite"
    echo "8. Visualizza docenti su GSuite non presenti su Argo"
    echo "9. Esporta docenti su GSuite non presenti su Argo"
    echo "10. Sospendi docenti su GSuite non presenti su Argo"
    echo "11. Cancella account docenti su GSuite non presenti su Argo"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " choice
        
        case $choice in
            1)
                echo "Creo la tabella ${TABELLA_DOCENTI_GSUITE} ..."

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '${TABELLA_DOCENTI_GSUITE}' (\"group\" VARCHAR(200), name VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200),	type VARCHAR(200), status VARCHAR(200));"
                ;;
            2)
                echo "Inporta in tabella i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " | $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_DOCENTI_GSUITE}" - --csv --empty-null
                done

                 # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE ${TABELLA_DOCENTI_GSUITE} 
                SET \"group\" = substr(\"group\", 1, instr(\"group\", '@') - 1)"
                ;;
            3)
                echo "Importa tutti i docenti da singolo file CSV nella tabella"
                
                $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_DOCENTI_GSUITE}" "$FILE_CSV" --csv --empty-null
                ;;
            4)
                echo "Visualizza docenti nei gruppi GSuite che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  $SQLITE_CMD studenti.db --csv --header "SELECT c.\"group\", c.id, c.name, c.email $PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO AND c.\"group\" = '$nome_gruppo' ORDER BY c.email;"
                done
                ;;
            5)
                echo "Rimuovi dai gruppi GSuite i docenti che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do                
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email $PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO AND c.\"group\" = '$nome_gruppo' ORDER BY c.email;"
                done
                ;;
            6)
                echo "Svuota gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$nome_gruppo" --query "SELECT c.email FROM ${TABELLA_DOCENTI_GSUITE} c WHERE c.\"group\" = '$nome_gruppo' ORDER BY c.email;"
                done
                ;;
            7)
                echo "Cancella gruppi GSuite"

                for nome_gruppo in "${!gruppi[@]}"; do
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            8)
                echo "Visualizza docenti su GSuite non in elenco docenti"

                $SQLITE_CMD studenti.db --csv --header "$FULL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO"
                ;;
            9)
                mkdir -p "$EXPORT_DIR_DATE"

                echo "Esporta docenti su GSuite non presenti su Argo"

                $SQLITE_CMD studenti.db --csv --header "$FULL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO" > "${EXPORT_DIR_DATE}/docentiSuGSuiteNonInArgo_${CURRENT_DATE}.csv"
                ;;
            10)
                echo "Sospendi docenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "$QUERY_DOCENTI_SU_GSUITE_NON_ARGO"
                ;;
            11)
                echo "Cancella account docenti su GSuite non presenti su Argo"

                $RUN_CMD_WITH_QUERY --command deleteUsers --group " NO " --query "$QUERY_DOCENTI_SU_GSUITE_NON_ARGO"
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

