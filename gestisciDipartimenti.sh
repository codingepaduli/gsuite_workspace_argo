#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

# Funzione per mostrare il menu
show_menu() {
    echo "Gestione Dipartimenti su GSuite"
    echo "-------------"
    echo "1. Crea la tabella $TABELLA_DIPARTIMENTI"
    echo "2. Importa dati in $TABELLA_DIPARTIMENTI da $TABELLA_CDC_ARGO e normalizza"
    echo "3. Esporta lista dipartimenti"
    echo "4. "
    echo "5. Esporta lista delle sigole materie"
    echo "20. Esci"
}

# Funzione principale
main() {
    while true; do
        show_menu
        read -p "Scegli un'opzione (1-20): " -r choice
        
        case $choice in
            1)
                echo "Creo la tabella $TABELLA_DIPARTIMENTI ..."
                
                $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$TABELLA_DIPARTIMENTI' (materie VARCHAR(200), dipartimento VARCHAR(200));"
                ;;
            2)
                echo "Importa dati in $TABELLA_DIPARTIMENTI da $TABELLA_CDC_ARGO e normalizza ..."
                
                $SQLITE_CMD studenti.db "insert into $TABELLA_DIPARTIMENTI (materie)
                SELECT DISTINCT UPPER(cdc.materie)
                  FROM $TABELLA_CDC_ARGO cdc
                  INNER JOIN $TABELLA_PERSONALE d 
                  ON (d.cognome || ' ' || d.nome) = cdc.docente 
                  WHERE d.email_gsuite is NOT NULL 
                  AND d.email_gsuite != '' 
                  AND d.tipo_personale = 'docente'
                  AND UPPER(cdc.materie) NOT IN ('EDUCAZIONE CIVICA', 'ORIENTAMENTO', 'POTENZIAMENTO', 'SOST')
                  ORDER BY cdc.materie"

                $SQLITE_CMD studenti.db "UPDATE $TABELLA_DIPARTIMENTI 
                SET dipartimento = 
                    CASE
                      WHEN materie = 'COMPLEMENTI' THEN 'MATEMATICA'
                      WHEN materie = 'MAT' THEN 'MATEMATICA'
                      WHEN materie = 'MAT+ COMPLEMENTI' THEN 'MATEMATICA'
                      WHEN materie = 'MATEMATICA+COMPLEMEN' THEN 'MATEMATICA'

                      -- O LETTERE?
                      WHEN materie = 'DIRITTO E PRATICA' THEN 'DIRITTO'
                      WHEN materie = 'DIRITTO ED ECONOMIA' THEN 'DIRITTO'

                      WHEN materie = 'GEOGRAFIA' THEN 'LETTERE'
                      WHEN materie = 'LINGUA E LETT. ITAL.' THEN 'LETTERE'
                      WHEN materie = 'STORIA' THEN 'LETTERE'

                      WHEN materie = 'INGLESE' THEN 'INGLESE'

                      -- O LETTERE?
                      WHEN materie = 'RELIGIONE/ATT.ALTERN' THEN 'RELIGIONE'

                      WHEN materie = 'SCIEN. MOTOR. E SPOR' THEN 'SCIENZE_MOTORIE'

                      WHEN materie = 'SC.TERRA E BIOLOGIA' THEN 'SCIENZE'
                      WHEN materie = 'SCIEN. INTE(CHIMICA)' THEN 'SCIENZE'
                      WHEN materie = 'SCIEN.INTEG.(FISICA)' THEN 'SCIENZE'
                      WHEN materie = 'SCIENZE DELLA TERRA' THEN 'SCIENZE'
                      -- WHEN materie = 'SCIENZE E TECN.APPLI' THEN 'SCIENZE'
                      
                      -- O DISEGNO ?
                      WHEN materie = 'TECN.DI RAPP.GRAFICA' THEN 'SCIENZE'

                      WHEN materie = 'ANATOMIA.FISILIO' THEN 'ODONTOTECNICO'
                      WHEN materie = 'ESER. LABOR.ODONTOT' THEN 'ODONTOTECNICO'
                      WHEN materie = 'GNATOLOGIA' THEN 'ODONTOTECNICO'
                      WHEN materie = 'RAPPR.MODELLAZIONEOD' THEN 'ODONTOTECNICO'

                      WHEN materie = 'D.P.O.' THEN 'MACCANICA'
                      WHEN materie = 'MECC E SIS.PROPULSIV' THEN 'MACCANICA'
                      WHEN materie = 'MECC. MACCH. ED ENER' THEN 'MACCANICA'
                      WHEN materie = 'TECN.MECC.DI PROC.E' THEN 'TRASPORTI'

                      -- O MACCANICA ?
                      WHEN materie = 'SISTEMI AUTOMATICI' THEN 'ELETTRONICA'
                      WHEN materie = 'ELETTRONICA ED ELETT' THEN 'ELETTRONICA'
                      WHEN materie = 'ELETTROTECNICA ED EL' THEN 'ELETTRONICA'

                      -- WHEN materie = 'GESTIONE PROGETTO OR' THEN ''
                      
                      WHEN materie = 'INFORMATICA' THEN 'INFORMATICA'
                      WHEN materie = 'SISTEMI E RETI' THEN 'INFORMATICA'
                      WHEN materie = 'TECN SISTEMI INF' THEN 'INFORMATICA'
                      WHEN materie = 'TECNOLOGIE INFORMAT.' THEN 'INFORMATICA'
                      WHEN materie = 'TECNOLOGIA DELLINFOR' THEN 'INFORMATICA'

                      WHEN materie = 'LOGISTICA' THEN 'TRASPORTI'
                      WHEN materie = 'STRUTTURA.COST.MEZZO' THEN 'TRASPORTI'

                      WHEN materie = 'TELECOMUNICAZIONI' THEN 'TELECOMUNICAZIONI'

                    END"
                ;;
            3)
                echo "Esporta lista docenti con possibili dipartimenti ..."
                
                test estrazione dati con
                $SQLITE_CMD -header -table studenti.db "SELECT DISTINCT dip.dipartimento, UPPER(cdc.materie), cdc.docente
                  FROM $TABELLA_CDC_ARGO cdc
                  INNER JOIN $TABELLA_PERSONALE d 
                  ON (d.cognome || ' ' || d.nome) = cdc.docente 
                  INNER JOIN $TABELLA_DIPARTIMENTI dip 
                  ON UPPER(cdc.materie) = UPPER(dip.materie)
                  WHERE d.email_gsuite is NOT NULL 
                  AND d.email_gsuite != '' 
                  AND d.tipo_personale = 'docente'
                  AND UPPER(cdc.materie) NOT IN ('EDUCAZIONE CIVICA', 'ORIENTAMENTO', 'POTENZIAMENTO', 'SOST')
                  ORDER BY cdc.docente"
                ;;
            4)
                #
                ;;
            5)
                mkdir -p "$EXPORT_DIR_DATE"
                echo "Esporta lista delle sigole materie ..."

                $SQLITE_CMD -csv studenti.db "
                  SELECT DISTINCT cdc.materie 
                  FROM $TABELLA_CDC_ARGO cdc
                  INNER JOIN $TABELLA_PERSONALE d 
                  ON (d.cognome || ' ' || d.nome) = cdc.docente 
                  WHERE d.email_gsuite is NOT NULL 
                  AND d.email_gsuite != '' 
                  AND d.tipo_personale = 'docente'
                  AND cdc.materie NOT IN ('EDUCAZIONE CIVICA', 'ORIENTAMENTO', 'POTENZIAMENTO')
                  " > "$EXPORT_DIR_DATE/materie.csv"
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

