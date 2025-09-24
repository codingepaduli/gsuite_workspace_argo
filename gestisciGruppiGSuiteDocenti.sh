#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

##########################################################################
# Progettato per gestire il personale, non per CdC, non per dipartimenti # 
##########################################################################

# Gruppo insegnanti
GRUPPO_DOCENTI="docenti_volta"

# Gruppo insegnanti abilitati a classroom
GRUPPO_CLASSROOM="insegnanti_classe"

# Query personale tutto
QUERY_PERSONALE="
    FROM $TABELLA_PERSONALE
    WHERE (email_gsuite IS NOT NULL AND TRIM(email_gsuite != ''))
        AND UPPER(tipo_personale)=UPPER('docente') 
        AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')"

add_to_map "$GRUPPO_DOCENTI" " 
    SELECT LOWER(email_gsuite) AS email_gsuite 
    $QUERY_PERSONALE
    ORDER BY LOWER(email_gsuite);"

add_to_map "$GRUPPO_CLASSROOM" "
    SELECT LOWER(email_gsuite) AS email_gsuite 
    $QUERY_PERSONALE
    ORDER BY LOWER(email_gsuite);"

# Query personale aggiunto in un certo periodo
QUERY_DELTA_PERSONALE="
    $QUERY_PERSONALE
    AND ( aggiunto_il IS NOT NULL AND TRIM(aggiunto_il) != ''
        AND aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
    )"

# Query docenti su GSuite non presenti su Argo
PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
FROM ${TABELLA_DOCENTI_GSUITE} dg 
WHERE 1=1
    -- filtro studenti
    AND LOWER(SUBSTR(dg.email_gsuite, 1, MIN(2, LENGTH(dg.email_gsuite)))) IN ('d.')
    AND UPPER(dg.stato_utente) = 'SUSPENDED'
    AND LOwER(dg.email) NOT IN (
        SELECT LOWER(email_gsuite) AS email_gsuite 
        FROM $TABELLA_PERSONALE
        WHERE 1=1
            AND (email_gsuite IS NOT NULL AND TRIM(email_gsuite != ''))
            AND UPPER(tipo_personale)=UPPER('docente') 
            AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
    )
"

# AND d.type = 'Suspended'
# AND d.status = 'Never logged in'
# AND cast(substr(d.status, 1, min(4, length(d.status))) AS INTEGER) < 2024
# AND SUBSTR(csv.email, 1, 2) = 'd.'

# Query (tutte le info) docenti su GSuite non presenti su Argo
FULL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
SELECT UPPER(dg.name) AS name, LOWER(dg.email) AS email
$PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Query email docenti su GSuite non presenti su Argo
QUERY_DOCENTI_SU_GSUITE_NON_ARGO="
SELECT c.email
$PARTIAL_QUERY_DOCENTI_SU_GSUITE_NON_ARGO
ORDER BY c.email;"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi GSuite del personale:"
    echo "-------------"
    echo "1. Aggiungi tutti i membri ai gruppi GSuite"
    echo "2. Importa in tabella GRUPPI i gruppi GSuite"
    echo "3. Visualizza nuovo personale da aggiungere ai gruppi GSuite"
    echo "4. Aggiungi nuovo personale ai gruppi GSuite"
    echo "5. Visualizza docenti nei gruppi GSuite che non sono in Argo"
    echo "6. Disabilito i docenti GSuite che non sono in elenco Argo"
    echo "8. Visualizza docenti su GSuite non presenti su Argo"
    echo "9. Esporta docenti su GSuite non presenti su Argo"
    echo "10. Sospendi docenti su GSuite non presenti su Argo"
    echo "11. Cancella account docenti su GSuite non presenti su Argo"
    echo "18. Crea i gruppi su GSuite ..."
    echo "19. Cancella i gruppi da GSuite ..."
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Aggiungi tutti i membri ai gruppi GSuite ..."
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite...!"
                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi[$nome_gruppo]}"
                done
                ;;
            2)
                echo "Importa in tabella GRUPPI i gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                    echo "Salvo gruppo GSuite $nome_gruppo in tabella"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query " NO " | $SQLITE_UTILS_CMD insert studenti.db "$TABELLA_GRUPPI" - --csv --empty-null
                done
                ;;
            3)
                echo "Visualizza nuovo personale da aggiungere ai gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Nuovo personale da aggiungere al gruppo $nome_gruppo "
                  $RUN_CMD_WITH_QUERY --command executeQuery --group " /* NO */ " --query "
                      SELECT LOWER(tipo_personale) as tipo, UPPER(cognome) as cognome, 
                          UPPER(nome) as nome, LOWER(email_personale) as email_personale, 
                          LOWER(email_gsuite) as email_gsuite
                      $QUERY_DELTA_PERSONALE
                      ORDER BY LOWER(email_gsuite);
                  "
                done
                ;;
            4)
                echo "Aggiungi nuovo personale ai gruppi GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Nuovo personale da aggiungere al gruppo $nome_gruppo "
                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "
                      SELECT LOWER(email_gsuite) as email_gsuite
                      $QUERY_DELTA_PERSONALE
                      ORDER BY LOWER(email_gsuite);
                  "
                done
                ;;
            5)
                echo "Visualizza personale nei gruppi GSuite che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "disabilito utenti del gruppo $nome_gruppo"

                  $SQLITE_CMD studenti.db --csv --header "
                  SELECT g.\"group\", LOWER(g.name) AS name, LOWER(g.email) AS email
                  FROM $TABELLA_GRUPPI g
                  WHERE 1=1
                    AND g.\"group\" = '$nome_gruppo'
                    -- filtro email
                    AND LOWER(g.email) NOT NULL AND TRIM(LOWER(g.email)) != ''
                    AND LOWER(SUBSTR(g.email, 1, MIN(2, LENGTH(g.email)))) IN ('d.', 'a.')
                    AND LOWER(g.email) IN (
                      SELECT LOWER(pa.email_gsuite)
                      FROM $TABELLA_PERSONALE pa
                      WHERE 1=1
                        AND (pa.email_gsuite IS NOT NULL AND TRIM(pa.email_gsuite) != '') 
                        -- seleziono i cancellati
                        AND (cancellato_il IS NOT NULL AND TRIM(cancellato_il) != '')
                    )
                    ORDER BY LOWER(g.email);"
                done
                ;;
            6)
                echo "Disabilito i docenti GSuite che non sono in elenco Argo"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "disabilito utenti del gruppo $nome_gruppo"

                  $SQLITE_CMD studenti.db --csv --header "
                  UPDATE $TABELLA_UTENTI_GSUITE
                  SET stato_utente = 'SUSPENDED'
                  WHERE LOWER(email_gsuite) IN (
                    SELECT LOWER(g.email) AS email
                    FROM $TABELLA_GRUPPI g
                    WHERE 1=1
                      AND g.\"group\" = '$nome_gruppo'
                      -- filtro email
                      AND LOWER(g.email) NOT NULL AND TRIM(LOWER(g.email)) != ''
                        AND LOWER(SUBSTR(g.email, 1, MIN(2, LENGTH(g.email)))) IN ('d.', 'a.')
                      AND LOWER(g.email) IN (
                        SELECT LOWER(pa.email_gsuite)
                        FROM $TABELLA_PERSONALE pa
                        WHERE 1=1
                          AND (pa.email_gsuite IS NOT NULL AND TRIM(pa.email_gsuite) != '') 
                          -- seleziono i cancellati
                          AND (cancellato_il IS NOT NULL AND TRIM(cancellato_il) != '')
                      )
                    );"
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
            18)
                echo "Crea i gruppi su GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Creo gruppo $nome_gruppo su GSuite"
                  $RUN_CMD_WITH_QUERY --command createGroup --group "$nome_gruppo" --query " NO "
                done
                ;;
            19)
                echo "Cancella i gruppi da GSuite"
                
                for nome_gruppo in "${!gruppi[@]}"; do
                  echo "Cancello gruppo $nome_gruppo da GSuite"
                  # $RUN_CMD_WITH_QUERY --command deleteGroup --group "$nome_gruppo" --query " NO "
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

