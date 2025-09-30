#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

#SQL_FILTRO_ANNI=" AND sz.cl IN (5) " 
#SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "
#SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('m_sirio', 'et_sirio') "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Crea la query per gruppi GSUITE aggiuntivi, indicati nel file di configurazione
SQL_QUERY_ADDITIONAL_GROUPS="WITH temp AS ( SELECT NULL AS value "
# Itera sull'array
for value in "${GSUITE_ADDITIONAL_GROUPS[@]}"; do
    # Aggiungi il valore alla lista, racchiudendolo tra apici
    SQL_QUERY_ADDITIONAL_GROUPS+=" UNION ALL"
    SQL_QUERY_ADDITIONAL_GROUPS+=" SELECT '$value' AS value"
done
SQL_QUERY_ADDITIONAL_GROUPS+=") SELECT value FROM temp WHERE value IS NOT NULL "

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi classe attraverso la tabella studenti ARGO"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "1. Crea le classi ed i gruppi aggiuntivi su GSuite (solo classi e gruppi, senza studenti)"
    echo "2. Cancella le classi ed i gruppi aggiuntivi da GSuite"
    echo "3. Esporta le classi da tabella studenti, un file CSV per ogni classe"
    echo "4. Aggiungi studenti alle classi"
    echo "5. Visualizza numero studenti per classe"
    echo "6. Esporta le classi da tabella studenti, un unico file CSV con tutte le classi"
    echo "8. Toglie i ritirati dalle classi e effettua i cambi di classe"
    echo "9. Aggiungi nuovi studenti (vedi periodo) alle classi"
    
    echo "11. Esporta le classi ed i gruppi aggiuntivi da GSuite, un file CSV per ogni classe"
    echo "12. Esporta le classi ed i gruppi aggiuntivi da GSuite, un unico file CSV con tutte le classi"
    
    echo "20. Esci"
}

# Funzione principale
main() {

    if ! checkAllVarsNotEmpty "DOMAIN" "TABELLA_STUDENTI" "TABELLA_STUDENTI_SERALE" "TABELLA_SEZIONI"; then
        echo "Errore: Definisci le variabili nel file di configurazione." >&2
        exit 1  # Termina lo script con codice di stato 1
    fi

    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Crea le classi ed i gruppi aggiuntivi su GSuite (solo classi e gruppi, senza studenti)"

                while IFS="," read -r sezione_gsuite; do
                    echo "Creo classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$sezione_gsuite" --query " /* NO */ "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_ADDITIONAL_GROUPS UNION $SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            2)
                echo "Cancella le classi ed i gruppi aggiuntivi da GSUITE"

                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$sezione_gsuite" --query " /* NO */ "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_ADDITIONAL_GROUPS UNION $SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            3)
                echo "3. Esporta le classi da tabella studenti, un file CSV per ogni classe"

                mkdir -p "$EXPORT_DIR_DATE"
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sz.sezione_gsuite AS classe, UPPER(sa.cognome) AS cognome,
                        UPPER(sa.nome) AS nome, LOWER(sa.email_gsuite) as email_gsuite,  UPPER(sa.cod_fisc) AS cod_fisc, sa.datan, sa.datar
                                  FROM $TABELLA_STUDENTI sa 
                                    INNER JOIN $TABELLA_SEZIONI sz 
                                    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                  WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                    AND (sa.email_gsuite IS NOT NULL AND TRIM(sa.email_gsuite) != '')
                                    AND (sa.aggiunto_il IS NOT NULL AND TRIM(sa.aggiunto_il) != ''
                                        AND sa.aggiunto_il BETWEEN '$PERIODO_STUDENTI_DA' AND '$PERIODO_STUDENTI_A'
                                    )
                                    AND (sa.datar IS NULL OR sa.datar = '')
                                  ORDER BY sz.sezione_gsuite, UPPER(sa.cognome);"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command executeQuery --group " NO; " --query "${gruppi_classe[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
                done
                ;;
            4)
                echo "Aggiungo studenti alle classi"

                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="
                                SELECT sa.email_gsuite
                                FROM $TABELLA_STUDENTI sa 
                                  INNER JOIN $TABELLA_SEZIONI sz 
                                  ON sa.sez = sz.sez_argo AND sa.cl =sz.cl 
                                WHERE sz.sezione_gsuite = '$sezione_gsuite'
                                  AND sa.email_gsuite IS NOT NULL
                                  AND sa.email_gsuite != ''
                                  AND (sa.datar IS NULL OR sa.datar = '')
                                ORDER BY sa.email_gsuite;"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )

                for nome_gruppo in "${!gruppi_classe[@]}"; do
                    # echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}"
                done
                ;;
            5)
                echo "Esportato numero studenti per classe in file CSV"

                mkdir -p "$EXPORT_DIR_DATE"

                $SQLITE_CMD -header -csv studenti.db "
                SELECT s.cl AS cl, s.sez_argo AS sez_argo, s.sezione_gsuite AS sez_gsuite, COUNT(*) as numero_alunni 
                FROM $TABELLA_STUDENTI sa 
                  INNER JOIN $TABELLA_SEZIONI s 
                  ON sa.sez = s.sez_argo AND sa.cl =s.cl 
                WHERE sa.email_gsuite IS NOT NULL
                  AND sa.email_gsuite != ''
                  AND (sa.datar IS NULL OR sa.datar = '')
                GROUP BY s.sez_argo, s.cl
                ORDER BY cl, sez_argo;" > "$EXPORT_DIR_DATE/num_studenti_per_classe.csv"
                ;;
            6)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporta le classi da tabella studenti, un unico file CSV con tutte le classi ..."
                
                $SQLITE_CMD studenti.db -header -csv "
                SELECT s.sezione_gsuite AS classe, s.cl AS anno, s.letter AS sezione, s.addr_gsuite AS indirizzo,
                sa.cognome, sa.nome, LOWER(sa.email_gsuite) AS email
                FROM $TABELLA_STUDENTI sa 
                  INNER JOIN $TABELLA_SEZIONI s 
                  ON sa.sez = s.sez_argo AND sa.cl =s.cl 
                WHERE sa.email_gsuite IS NOT NULL
                  AND sa.email_gsuite != ''
                  AND (sa.datar IS NULL OR sa.datar = '')
                  ORDER BY s.sezione_gsuite, sa.cognome, sa.nome;
                " > "$EXPORT_DIR_DATE/studenti_per_classe_$CURRENT_DATE.csv"
                ;;
            8)
                checkAllVarsNotEmpty "TABELLA_STUDENTI_PRECEDENTE"

                echo "Toglie i ritirati dalle classi e effettua i cambi di classe, confrontando le tabelle $TABELLA_STUDENTI e $TABELLA_STUDENTI_PRECEDENTE ..."

                local QUERY_DIFF="
                  -- SELECT stP.email_gsuite, szp.sezione_gsuite 
                  --, stP.cl, stP.sez, stP.datar, stD.email_gsuite, stD.cl, stD.sez, szd.sezione_gsuite, stD.datar
                  FROM $TABELLA_STUDENTI stD
                    INNER JOIN $TABELLA_STUDENTI_PRECEDENTE stP 
                    ON stD.email_gsuite = stP.email_gsuite
                    INNER JOIN $TABELLA_SEZIONI szp 
                    ON stP.sez = szp.sez_argo AND stP.cl = szp.cl 
                    INNER JOIN $TABELLA_SEZIONI szd 
                    ON stD.sez = szd.sez_argo AND stD.cl = szd.cl 
                  WHERE stD.email_gsuite IS NOT NULL 
                    AND stD.email_gsuite != ''  
                    AND (stP.datar IS NULL OR stP.datar = '')
                    AND (
                      -- cambia classe, sezione o si è ritirato
                      stP.cl != stD.cl OR stP.sez != stD.sez OR stD.datar != ''
                    )
                "

                while IFS="," read -r email_gsuite sezione_gsuite; do
                  echo "cancello $email_gsuite da classe $sezione_gsuite"
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$sezione_gsuite" --query "SELECT '$email_gsuite' as email_gsuite;"
                done < <($SQLITE_CMD -csv studenti.db "
                  SELECT stP.email_gsuite, szp.sezione_gsuite 
                  $QUERY_DIFF
                  ORDER BY stD.cl, stD.sez, LOWER(stD.email_gsuite);
                  " | sed "s/\"//g")
                
                while IFS="," read -r email_gsuite sezione_gsuite; do
                  echo "inserisco $email_gsuite in classe $sezione_gsuite"
                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$sezione_gsuite" --query "SELECT '$email_gsuite' as email_gsuite;"
                done < <($SQLITE_CMD -csv studenti.db "
                  SELECT stD.email_gsuite, szd.sezione_gsuite 
                  $QUERY_DIFF 
                      -- aggiungo solo gli studenti che NON si sono ritirati
                      AND (stD.datar IS NULL OR stD.datar = '')
                  ORDER BY stD.cl, stD.sez, LOWER(stD.email_gsuite);
                  " | sed "s/\"//g")
                ;;
            9)
                checkAllVarsNotEmpty "PERIODO_STUDENTI_DA" "PERIODO_STUDENTI_A"
                
                echo "8. Aggiungi nuovi studenti (aggiunti tra $PERIODO_STUDENTI_DA e $PERIODO_STUDENTI_A) alle classi"

                local QUERY_DIFF2="
                  -- SELECT s.email_gsuite, sz.sezione_gsuite, s.aggiunto_il, s.datar
                  FROM $TABELLA_STUDENTI s
                    INNER JOIN $TABELLA_SEZIONI sz
                    ON s.sez = sz.sez_argo AND s.cl = sz.cl
                  WHERE s.email_gsuite IS NOT NULL 
                    AND s.email_gsuite != ''  
                    AND (s.datar IS NULL OR  s.datar = '')
                    AND s.aggiunto_il BETWEEN '$PERIODO_STUDENTI_DA' AND '$PERIODO_STUDENTI_A'
                    ORDER BY sz.sezione_gsuite, s.email_gsuite;
                "

                while IFS="," read -r email_gsuite sezione_gsuite; do
                    echo "inserisco $email_gsuite in classe $sezione_gsuite"
                    $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$sezione_gsuite" --query "SELECT '$email_gsuite' as email_gsuite;"
                done < <($SQLITE_CMD -csv studenti.db "
                  SELECT s.email_gsuite, sz.sezione_gsuite $QUERY_DIFF2
                  " | sed "s/\"//g")
                ;;
            11)
                echo "11. Esporta le classi ed i gruppi aggiuntivi da GSuite, un file CSV per ogni classe"
                mkdir -p "$EXPORT_DIR_DATE"

                while IFS="," read -r sezione_gsuite; do
                    echo "Salvo gruppo GSuite $sezione_gsuite"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$sezione_gsuite" --query " /* NO; */ " > "$EXPORT_DIR_DATE/classe_$sezione_gsuite.csv"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_ADDITIONAL_GROUPS UNION $SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            12)
                echo "12. Esporta le classi ed i gruppi aggiuntivi da GSuite, un unico file CSV con tutte le classi"
                mkdir -p "$EXPORT_DIR_DATE"
                touch "$EXPORT_DIR_DATE/classi_tutte.csv"
                echo "group,name,id,email,role,type,status" >> "$EXPORT_DIR_DATE/classi_tutte.csv"

                while IFS="," read -r sezione_gsuite; do
                    echo "Salvo gruppo GSuite $sezione_gsuite"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$sezione_gsuite" --query " /* NO; */ " | sed "1d" >> "$EXPORT_DIR_DATE/classi_tutte.csv"
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_ADDITIONAL_GROUPS UNION $SQL_QUERY_SEZIONI" | sed 's/"//g' )
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
    log::_write_log "CONFIG" "Tabella studenti precedente per confronto: $TABELLA_STUDENTI_PRECEDENTE"
    log::_write_log "CONFIG" "Tabella sezioni: $TABELLA_SEZIONI"
    log::_write_log "CONFIG" "Inizio periodo (compreso): $PERIODO_STUDENTI_DA" 
    log::_write_log "CONFIG" "Fine periodo (compreso): $PERIODO_STUDENTI_A"
    log::_write_log "CONFIG" "Cartella di esportazione: $EXPORT_DIR_DATE"
    log::_write_log "CONFIG" "Query sezioni: $SQL_QUERY_SEZIONI"
    log::_write_log "CONFIG" "Query altri gruppi: $SQL_QUERY_ADDITIONAL_GROUPS"
    log::_write_log "CONFIG" "-----------------------------------------"
    read -p "Premi Invio per continuare..." -r _
  fi
}

# Show config vars
showConfig

# Avvia la funzione principale
main

