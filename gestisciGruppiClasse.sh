#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

#SQL_FILTRO_ANNI=" AND sz.cl IN (5) " 
#SQL_FILTRO_SEZIONI=" AND sz.sez_argo IN ( 'Cm' ) "
#SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('m_sirio', 'et_sirio') "

SQL_QUERY_SEZIONI="SELECT sz.sezione_gsuite FROM $TABELLA_SEZIONI sz WHERE 1=1 $SQL_FILTRO_ANNI $SQL_FILTRO_SEZIONI ORDER BY sz.sezione_gsuite"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione gruppi su GSuite"
    echo "-------------"
    echo "Esecuzione in DRY-RUN mode: $dryRunFlag"
    echo "-------------"
    echo "1. Crea le classi su GSUITE (solo classi, senza studenti)"
    echo "2. Cancella le classi da GSUITE"
    echo "3. Esporta, un file CSV per ogni classe"
    echo "4. Aggiungi studenti alle classi"
    echo "5. Visualizza numero studenti per classe"
    echo "6. Esporta, un unico file CSV con tutte le classi"
    echo "7. Gestisci differenza tra tabella prima e dopo"
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
                echo "Crea le classi su GSUITE (solo classi, senza studenti)"

                while IFS="," read -r sezione_gsuite; do
                    echo "Creo classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command createGroup --group "$sezione_gsuite" --query " /* NO */ "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            2)
                echo "Cancello le classi da GSUITE"

                while IFS="," read -r sezione_gsuite; do
                    echo "Cancello classe $sezione_gsuite ...!"
                    $RUN_CMD_WITH_QUERY --command deleteGroup --group "$sezione_gsuite" --query " /* NO */ "
                done < <($SQLITE_CMD -csv studenti.db "$SQL_QUERY_SEZIONI" | sed 's/"//g' )
                ;;
            3)
                echo "3. Esporta, un file CSV per ogni classe"

                mkdir -p "$EXPORT_DIR_DATE"
                declare -A gruppi_classe

                while IFS="," read -r sezione_gsuite; do
                    gruppi_classe[$sezione_gsuite]="SELECT sa.email_gsuite
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
                    echo "$nome_gruppo" "${gruppi_classe[$nome_gruppo]}"
                    $RUN_CMD_WITH_QUERY --command printGroup --group "$nome_gruppo" --query "${gruppi_classe[$nome_gruppo]}" > "$EXPORT_DIR_DATE/$nome_gruppo.csv"
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
                WHERE sz.sezione_gsuite = '$sezione_gsuite'
                  AND sa.email_gsuite IS NOT NULL
                  AND sa.email_gsuite != ''
                  AND (sa.datar IS NULL OR sa.datar = '')
                GROUP BY s.sez_argo, s.cl
                ORDER BY cl, sez_argo;" > "$EXPORT_DIR_DATE/num_studenti_per_classe.csv"
                ;;
            6)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporta, un unico file CSV con tutte le classi ..."
                
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
            7)
                echo "Gestisci differenza tra tabella prima e dopo ..."

                local QUERY_DIFF="
                  
                  --, sp.cl, sp.sez, sp.datar, sd.email_gsuite, sd.cl, sd.sez, szd.sezione_gsuite, sd.datar
                  FROM $TABELLA_STUDENTI sp
                    INNER JOIN $TABELLA_STUDENTI_DOPO sd 
                    ON sp.email_gsuite = sd.email_gsuite
                    INNER JOIN $TABELLA_SEZIONI szp 
                    ON sp.sez = szp.sez_argo AND sp.cl = szp.cl 
                    INNER JOIN $TABELLA_SEZIONI szd 
                    ON sd.sez = szd.sez_argo AND sd.cl = szd.cl 
                  WHERE sd.email_gsuite IS NOT NULL 
                    AND sd.email_gsuite != ''  
                    AND (sp.datar IS NULL OR sp.datar = '')
                    AND (
                      (sp.cl != sd.cl OR sp.sez != sd.sez)
                    	OR (sp.datar = '' AND sd.datar != '')
                    );
                "

                while IFS="," read -r email_gsuite sezione_gsuite; do

                  echo "cancello $email_gsuite da classe $sezione_gsuite"
                  $RUN_CMD_WITH_QUERY --command deleteMembersFromGroup --group "$sezione_gsuite" --query "SELECT '$email_gsuite' as email_gsuite;"

                done < <($SQLITE_CMD -csv studenti.db "
                  SELECT sp.email_gsuite, szp.sezione_gsuite $QUERY_DIFF
                  " | sed "s/\"//g")
                
                while IFS="," read -r email_gsuite sezione_gsuite; do

                  echo "inserisco $email_gsuite in classe $sezione_gsuite"
                  $RUN_CMD_WITH_QUERY --command addMembersToGroup --group "$sezione_gsuite" --query "SELECT '$email_gsuite' as email_gsuite;"

                done < <($SQLITE_CMD -csv studenti.db "
                  SELECT sp.email_gsuite, szd.sezione_gsuite $QUERY_DIFF
                  " | sed "s/\"//g")
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

