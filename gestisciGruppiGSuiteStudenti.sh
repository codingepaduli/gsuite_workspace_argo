#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV 
FILE_CSV="$BASE_DIR/dati_argo/studenti_gsuite/${TABELLA_STUDENTI_GSUITE}.csv"

# Importa le classi

SQL_FILTRO_ANNI=" AND sz.cl IN (1) " 
#SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "
#SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('m_sirio', 'et_sirio') "

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
WHERE LOWER(c.email) NOT IN (
    SELECT LOWER(s.email_gsuite) 
    FROM $TABELLA_STUDENTI s
) AND LOWER(c.email) NOT IN (
    SELECT LOWER(ss.email_gsuite) 
    FROM $TABELLA_STUDENTI_SERALE ss
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
  SELECT s.cl AS cl, s.sez_argo AS sez_argo, s.sezione_gsuite AS sez_gsuite, sa.cognome AS cognome, sa.nome AS nome, sa.email_gsuite as email_gsuite
  FROM $TABELLA_STUDENTI sa 
  INNER JOIN $TABELLA_SEZIONI s 
  ON sa.sez = s.sez_argo AND sa.cl =s.cl
  WHERE LOWER(sa.email_gsuite) NOT IN (
      SELECT LOWER(c.email)
      FROM ${TABELLA_STUDENTI_GSUITE} c
  )
  UNION
  SELECT ss.cl AS cl, ss.sez_argo AS sez_argo, ss.sezione_gsuite AS sez_gsuite, sas.cognome AS cognome, sas.nome AS nome, sas.email_gsuite as email_gsuite
  FROM $TABELLA_STUDENTI_SERALE sas
  INNER JOIN $TABELLA_SEZIONI ss 
  ON sas.sez = ss.sez_argo AND sas.cl =ss.cl
  WHERE LOWER(sas.email_gsuite) NOT IN (
      SELECT LOWER(c.email)
      FROM ${TABELLA_STUDENTI_GSUITE} c
  )
"

PARTIAL_QUERY_STUDENTI_DIURNO_OU_ERRATA="
FROM $TABELLA_STUDENTI sa 
INNER JOIN $TABELLA_SEZIONI s 
  ON sa.sez = s.sez_argo AND sa.cl =s.cl
INNER JOIN $TABELLA_STUDENTI_GSUITE sg
  ON sa.email_gsuite = sg.email
WHERE LOWER(SUBSTR(sg.email, 1, MIN(2, LENGTH(sg.email)))) IN ('s.')
  AND sg.\"group\" NOT IN ('/Studenti/Diurno')
ORDER BY sa.email_gsuite
"

QUERY_STUDENTI_DIURNO_OU_ERRATA="
SELECT sa.email_gsuite
$PARTIAL_QUERY_STUDENTI_DIURNO_OU_ERRATA
"

FULL_QUERY_STUDENTI_DIURNO_OU_ERRATA="
SELECT sg.\"group\", sa.email_gsuite
$PARTIAL_QUERY_STUDENTI_DIURNO_OU_ERRATA
"

PARTIAL_QUERY_STUDENTI_SERALE_OU_ERRATA="
FROM $TABELLA_STUDENTI_SERALE sa 
INNER JOIN $TABELLA_SEZIONI s 
  ON sa.sez = s.sez_argo AND sa.cl =s.cl
INNER JOIN $TABELLA_STUDENTI_GSUITE sg
  ON sa.email_gsuite = sg.email
WHERE LOWER(SUBSTR(sg.email, 1, MIN(2, LENGTH(sg.email)))) IN ('s.')
  AND sg.\"group\" NOT IN ('/Studenti/Serale')
ORDER BY sa.email_gsuite
"

QUERY_STUDENTI_SERALE_OU_ERRATA="
SELECT sa.email_gsuite
$PARTIAL_QUERY_STUDENTI_SERALE_OU_ERRATA
"

FULL_QUERY_STUDENTI_SERALE_OU_ERRATA="
SELECT sg.\"group\", sa.email_gsuite
$PARTIAL_QUERY_STUDENTI_SERALE_OU_ERRATA
"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi di GSuite su tabella ${TABELLA_STUDENTI_GSUITE}"
    echo "-------------"
    echo "1. Creo la tabella ${TABELLA_STUDENTI_GSUITE}"
    echo "2. Inporta in tabella i gruppi GSuite"
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
    echo "14. Visualizza studenti diurno con OU errata"
    echo "15. Sposta studenti diurno con OU errata su OU 'Diurno'"
    echo "16. Visualizza studenti serale con OU errata"
    echo "17. Sposta studenti serale con OU errata su OU 'Serale'"

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

                # Normalizza dati (rimuove @$DOMAIN)"
                $SQLITE_CMD studenti.db "UPDATE ${TABELLA_STUDENTI_GSUITE} 
                SET \"group\" = substr(\"group\", 1, instr(\"group\", '@') - 1)
                WHERE \"group\" LIKE '%@%';"
                ;;
            3)
                echo "Importa tutti gli studenti da singolo file CSV nella tabella"
                
                $SQLITE_UTILS_CMD insert studenti.db "${TABELLA_STUDENTI_GSUITE}" "$FILE_CSV" --csv --empty-null
                ;;
            4)
                echo "Visualizza studenti nei gruppi GSuite che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  $SQLITE_CMD studenti.db --csv --header "SELECT c.\"group\", c.id, c.name, c.email $PARTIAL_QUERY_STUDENTI_SU_GSUITE_NON_ARGO
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
            13)
                echo "Visualizza studenti su Argo con mail non presente su GSuite"

                $SQLITE_CMD -header -csv studenti.db "$QUERY_STUDENTI_SU_ARGO_NON_GSUITE
                "
                ;;
            14)
                echo "Visualizza studenti diurno con OU errata"

                $SQLITE_CMD -csv -header studenti.db "$FULL_QUERY_STUDENTI_DIURNO_OU_ERRATA"
                ;;
            15)
                echo "Sposta studenti diurno con OU errata su OU 'Diurno'"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/Studenti/Diurno" --query "$QUERY_STUDENTI_DIURNO_OU_ERRATA"
                ;;
            16)
                echo "Visualizza studenti serale con OU errata"

                $SQLITE_CMD -header -csv studenti.db "$FULL_QUERY_STUDENTI_SERALE_OU_ERRATA"
                ;;
            17)
                echo "Sposta studenti serale con OU errata su OU 'Serale'"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/Studenti/Serale" --query "$QUERY_STUDENTI_SERALE_OU_ERRATA"
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

