#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# File CSV di lavoro con personale versionata alla data indicata
FILE_UTENTI_CSV="$BASE_DIR/dati_gsuite/$TABELLA_UTENTI_GSUITE.csv"

# Query studenti su GSuite non presenti su Argo
QUERY_STUDENTI_SU_GSUITE_NON_ARGO="
    FROM ${TABELLA_UTENTI_GSUITE} sg 
    WHERE
        -- filtro studenti
        LOWER(SUBSTR(sg.email_gsuite, 1, MIN(2, LENGTH(sg.email_gsuite)))) IN ('s.')
        AND LOWER(sg.email_gsuite) NOT IN (
            SELECT LOWER(sa.email_gsuite) 
            FROM $TABELLA_STUDENTI sa
        )
"
# Query personale su GSuite non in servizio su Argo
QUERY_PERSONALE_SU_GSUITE_NON_ARGO="
    FROM $TABELLA_UTENTI_GSUITE sg 
    WHERE
        -- filtro personale
        LOWER(SUBSTR(sg.email_gsuite, 1, MIN(2, LENGTH(sg.email_gsuite)))) IN ('d.', 'a.')
        AND LOWER(sg.email_gsuite) NOT IN (
            -- personale in servizio
            SELECT LOWER(email_gsuite) 
            FROM $TABELLA_PERSONALE
            WHERE 1=1
                AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '')
        )
"

# Query studenti
QUERY_STUDENTI_DIURNO_OU_ERRATA="
  FROM $TABELLA_STUDENTI sa 
  INNER JOIN $TABELLA_SEZIONI sz 
    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl
  INNER JOIN $TABELLA_UTENTI_GSUITE sg
    ON UPPER(sa.email_gsuite) = UPPER(sg.email_gsuite) 
  WHERE 
      -- filtri sezioni
      1=1 
      $SQL_FILTRO_ANNI 
      $SQL_FILTRO_SEZIONI
      -- filtro studenti
      AND LOWER(SUBSTR(sg.email_gsuite, 1, MIN(2, LENGTH(sg.email_gsuite)))) IN ('s.')
      -- filtro studenti diurno / serale
      AND sz.sez_argo NOT LIKE '%_sirio'
      -- filtro unità organizzativa
      AND sg.org_unit NOT IN ('/STUDENTI/DIURNO') "

QUERY_STUDENTI_SERALE_OU_ERRATA="
  FROM $TABELLA_STUDENTI sa 
  INNER JOIN $TABELLA_SEZIONI sz 
    ON sa.sez = sz.sez_argo AND sa.cl =sz.cl
  INNER JOIN $TABELLA_UTENTI_GSUITE sg
    ON UPPER(sa.email_gsuite) = UPPER(sg.email_gsuite) 
  WHERE 
      -- filtri sezioni
      1=1 
      $SQL_FILTRO_ANNI 
      $SQL_FILTRO_SEZIONI
      -- filtro studenti
      AND LOWER(SUBSTR(sg.email_gsuite, 1, MIN(2, LENGTH(sg.email_gsuite)))) IN ('s.')
      -- filtro studenti diurno / serale
      AND sz.sez_argo LIKE '%_sirio'
      -- filtro unità organizzativa
      AND sg.org_unit NOT IN ('/STUDENTI/SERALE') "

QUERY_PERSONALE_OU_ERRATA="
FROM $TABELLA_UTENTI_GSUITE t
    INNER JOIN $TABELLA_PERSONALE p
    ON UPPER(t.email_gsuite) = UPPER(p.email_gsuite) 
WHERE 
    1 = 1
    AND (p.email_gsuite IS NOT NULL AND TRIM(p.email_gsuite) != '') 
    -- filtro personale inserito e non cancellato
    AND ( p.aggiunto_il IS NOT NULL AND TRIM(p.aggiunto_il) != ''
        AND p.aggiunto_il BETWEEN '$PERIODO_PERSONALE_DA' AND '$PERIODO_PERSONALE_A'
    ) 
    AND (p.cancellato_il IS NULL OR TRIM(p.cancellato_il) = '')
"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione tabella di tutti gli utenti GSuite"
    echo "-------------"
    echo "1. Cancello e ricreo la tabella di tutti gli utenti GSuite"
    echo "2. Importo e normalizzo i dati dal file CSV"
    echo "3. Visualizza personale segnato come disabilitato"
    echo "4. Disabilita su GSuite il personale segnato come disabilitato"
    echo "5. Visualizza studenti su GSuite e non su Argo"

    echo "12. Visualizza personale su GSuite e non su Argo"
    echo "14. Visualizza studenti diurno con OU errata"
    echo "15. Sposta studenti diurno con OU errata su OU 'Diurno'"
    echo "16. Visualizza studenti serale con OU errata"
    echo "17. Sposta studenti serale con OU errata su OU 'Serale'"
    echo "18. Visualizza personale con OU errata"
    echo "19. Sposta personale con OU errata"

    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "1. Cancello e ricreo la tabella del personale"
                
                # Cancello la tabella
                $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$TABELLA_UTENTI_GSUITE';"

                # Creo la tabella
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_UTENTI_GSUITE' ( 
                    nome VARCHAR(200),
                    cognome VARCHAR(200),
                    email_gsuite VARCHAR(200),
                    org_unit VARCHAR(200),
                    stato_utente VARCHAR(200),
                    ultimo_login TEXT,
                    spazio_email REAL,
                    spazio_gdrive REAL,
                    spazio_storage REAL,
                    selezionato_il TEXT);"
                ;;
            2)
                echo "2. Importo e normalizzo i dati dal file CSV $FILE_UTENTI_CSV ..."
                
                # Importa CSV dati
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query ".import --skip 1 $FILE_UTENTI_CSV $TABELLA_UTENTI_GSUITE"

                # Normalizza dati
                $SQLITE_CMD studenti.db "UPDATE $TABELLA_UTENTI_GSUITE 
                SET nome = TRIM(UPPER(nome)),
                    cognome = TRIM(UPPER(cognome)),
                    email_gsuite = TRIM(LOWER(email_gsuite)),
                    org_unit = TRIM(UPPER(org_unit)),
                    stato_utente = TRIM(UPPER(stato_utente)),
                    ultimo_login = TRIM(UPPER(ultimo_login)),
                    spazio_email = CAST(spazio_email AS REAL) * 1000,
                    spazio_gdrive = CAST(spazio_gdrive AS REAL) * 1000,
                    spazio_storage = CAST(spazio_storage AS REAL) * 1000,
                    selezionato_il = TRIM(UPPER(selezionato_il));"
                
                # Normalizza data ultimo_login
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_UTENTI_GSUITE 
                SET ultimo_login = date(substr(ultimo_login, 1, 4) || '-' || substr(ultimo_login, 6, 2) || '-' || substr(ultimo_login, 9, 2))
                WHERE ultimo_login is NOT NULL AND TRIM(UPPER(ultimo_login)) != UPPER('Never logged in');"

                # Imposto data ultimo_login per "Never logged in"
                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query "UPDATE $TABELLA_UTENTI_GSUITE 
                SET ultimo_login = date('2000-01-01')
                WHERE ultimo_login is NOT NULL AND TRIM(UPPER(ultimo_login)) = UPPER('Never logged in');"
                ;;
            3)
                echo "3. Visualizza utenti disabilitati"

                $SQLITE_CMD -header -table studenti.db "SELECT UPPER(sg.cognome) AS cognome, UPPER(sg.nome) AS nome, LOWER(sg.org_unit) AS org_unit, LOWER(sg.email_gsuite) AS email_gsuite, UPPER(stato_utente) AS stato_utente
                FROM $TABELLA_UTENTI_GSUITE sg
                WHERE 1=1 
                    AND UPPER(stato_utente) = 'SUSPENDED'
                    -- filtro personale
                    AND LOWER(SUBSTR(sg.email_gsuite, 1, MIN(2, LENGTH(sg.email_gsuite)))) IN ('d.', 'a.', 's.')
                    AND UPPER(sg.org_unit) IN ('/DOCENTI', '/ATA', '/STUDENTI/DIURNO', '/STUDENTI/SERALE')
                ORDER BY UPPER(sg.cognome);"
                ;;
            4)
                echo "4. Disabilita su GSuite il personale segnato come disabilitato"

                $RUN_CMD_WITH_QUERY --command suspendUsers --group " NO " --query "
                SELECT LOWER(email_gsuite) AS email_gsuite
                FROM $TABELLA_UTENTI_GSUITE
                WHERE 1=1 
                    AND UPPER(stato_utente) = 'SUSPENDED'
                    -- filtro personale
                    AND LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) IN ('d.', 'a.')
                    AND UPPER(org_unit) IN ('/DOCENTI', '/ATA')
                ORDER BY UPPER(cognome);"
                ;;
            5)
                echo "5. Visualizza studenti su GSuite e non su Argo"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query  "SELECT UPPER(sg.cognome) as cognome, UPPER(sg.nome) as nome, LOWER(sg.org_unit) as org_unit, LOWER(sg.email_gsuite) as email_gsuite $QUERY_STUDENTI_SU_GSUITE_NON_ARGO 
                ORDER BY LOWER(sg.email_gsuite);"
                ;;
            12)
                echo "12. Visualizza personale su GSuite e non su Argo"

                $SQLITE_CMD -header -table studenti.db "SELECT UPPER(sg.cognome) as cognome, UPPER(sg.nome) as nome, LOWER(sg.org_unit) as org_unit, LOWER(sg.email_gsuite) as email_gsuite $QUERY_PERSONALE_SU_GSUITE_NON_ARGO 
                ORDER BY UPPER(sg.cognome);"
                ;;
            14)
                echo "Visualizza studenti diurno con OU errata"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query  "SELECT sa.email_gsuite, sg.org_unit, sz.sezione_gsuite $QUERY_STUDENTI_DIURNO_OU_ERRATA ORDER BY sa.email_gsuite;"
                ;;
            15)
                echo "Sposta studenti diurno con OU errata su OU 'Diurno'"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/Studenti/Diurno" --query "SELECT sa.email_gsuite $QUERY_STUDENTI_DIURNO_OU_ERRATA ORDER BY sa.email_gsuite;"
                ;;
            16)
                echo "Visualizza studenti serale con OU errata"

                $RUN_CMD_WITH_QUERY --command "executeQuery" --group " NO; " --query  "SELECT sa.email_gsuite, sg.org_unit, sz.sezione_gsuite $QUERY_STUDENTI_SERALE_OU_ERRATA ORDER BY sa.email_gsuite;"
                ;;
            17)
                echo "Sposta studenti serale con OU errata su OU 'Serale'"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/Studenti/Serale" --query "SELECT sa.email_gsuite $QUERY_STUDENTI_SERALE_OU_ERRATA ORDER BY sa.email_gsuite;"
                ;;
            18)
                echo "18. Visualizza personale con OU errata"

                $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "
                SELECT UPPER(t.cognome) as cognome, UPPER(t.nome) as nome, LOWER(t.org_unit) as org_unit, LOWER(t.email_gsuite) as email_gsuite 
                $QUERY_PERSONALE_OU_ERRATA 
                  -- filtro personale docente
                  AND UPPER(p.tipo_personale) = UPPER('docente')
                  AND LOWER(SUBSTR(p.email_gsuite, 1, MIN(2, LENGTH(p.email_gsuite)))) IN ('d.')
                  AND LOWER(t.org_unit) NOT IN ('/docenti')  
                ORDER BY p.email_gsuite;"

                $RUN_CMD_WITH_QUERY --command executeQuery --group " NO " --query "
                SELECT UPPER(t.cognome) as cognome, UPPER(t.nome) as nome, LOWER(t.org_unit) as org_unit, LOWER(t.email_gsuite) as email_gsuite
                $QUERY_PERSONALE_OU_ERRATA 
                  -- filtro personale ATA
                  AND UPPER(p.tipo_personale) = UPPER('ata')
                  AND LOWER(SUBSTR(p.email_gsuite, 1, MIN(2, LENGTH(p.email_gsuite)))) IN ('a.')
                  AND LOWER(t.org_unit) NOT IN ('/ata')  
                ORDER BY p.email_gsuite;"
                ;;
            19)
                echo "19. Sposta personale con OU errata"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/docenti" --query "
                SELECT p.email_gsuite 
                $QUERY_PERSONALE_OU_ERRATA 
                  -- filtro personale docente
                  AND UPPER(p.tipo_personale) = UPPER('docente')
                  AND LOWER(SUBSTR(p.email_gsuite, 1, MIN(2, LENGTH(p.email_gsuite)))) IN ('d.')
                  AND LOWER(t.org_unit) NOT IN ('/docenti')  
                ORDER BY p.email_gsuite;"

                $RUN_CMD_WITH_QUERY --command moveUsersToOU --group "/ATA" --query "
                SELECT p.email_gsuite 
                $QUERY_PERSONALE_OU_ERRATA 
                  -- filtro personale ATA
                  AND UPPER(p.tipo_personale) = UPPER('ata')
                  AND LOWER(SUBSTR(p.email_gsuite, 1, MIN(2, LENGTH(p.email_gsuite)))) IN ('a.')
                  AND LOWER(t.org_unit) NOT IN ('/ata')  
                ORDER BY p.email_gsuite;"
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
