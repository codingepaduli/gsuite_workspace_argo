#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# Mappa (array associativo)
declare -A sectionQueryParam=(
  [FIELDS]=" * "
  [ORDERING]=" sezione_gsuite "
  [FILTER_YEARS_ON]=0
  [FILTER_YEARS_OFF]=1
  [FILTER_YEARS]=" $SQL_FILTRO_ANNI "
  [FILTER_ADDRESS_ARGO_ON]=0
  [FILTER_ADDRESS_ARGO_OFF]=1
  [FILTER_ADDRESS_ARGO]=" $SQL_FILTRO_SEZIONI "
  [FILTER_ADDRESS_GSUITE_ON]=0
  [FILTER_ADDRESS_GSUITE_OFF]=1
  [FILTER_ADDRESS_GSUITE]=" '' "
  [FILTER_CLASSES_ON]=0
  [FILTER_CLASSES_OFF]=1
  [FILTER_CLASSES]=" '' "
  [FILTER_SUPERVISORS_EXISTS_ON]=0
  [FILTER_SUPERVISORS_EXISTS_OFF]=1
  [FILTER_SUPERVISORS_NOT_EXISTS_ON]=0
  [FILTER_SUPERVISORS_NOT_EXISTS_OFF]=1
)

function query::getQuerySezioni {
    local FIELDS="${1:-${sectionQueryParam[FIELDS]}}"
    local ORDERING="${2:-${sectionQueryParam[ORDERING]}}"
    local FILTER_YEARS_FLAG="${3:-${sectionQueryParam[FILTER_YEARS_ON]}}"
    local FILTER_YEARS="${4:-${sectionQueryParam[FILTER_YEARS]}}"
    local FILTER_ADDRESS_ARGO_FLAG="${5:-${sectionQueryParam[FILTER_ADDRESS_ARGO_ON]}}"
    local FILTER_ADDRESS_ARGO="${6:-${sectionQueryParam[FILTER_ADDRESS_ARGO]}}"
    local FILTER_ADDRESS_GSUITE_FLAG="${7:-${sectionQueryParam[FILTER_ADDRESS_GSUITE_OFF]}}"
    local FILTER_ADDRESS_GSUITE="${8:-${sectionQueryParam[FILTER_ADDRESS_GSUITE]}}"
    local FILTER_CLASSES_FLAG="${9:-${sectionQueryParam[FILTER_CLASSES_OFF]}}"
    local FILTER_CLASSES="${10:-${sectionQueryParam[FILTER_CLASSES]}}"
    local FILTER_SUPERVISORS_EXISTS="${11:-${sectionQueryParam[FILTER_SUPERVISORS_EXISTS_OFF]}}"
    local FILTER_SUPERVISORS_NOT_EXISTS="${12:-${sectionQueryParam[FILTER_SUPERVISORS_NOT_EXISTS_OFF]}}"

    echo "
          SELECT $FIELDS 
          FROM $TABELLA_SEZIONI
          WHERE 1=1 
            AND (1=$FILTER_YEARS_FLAG OR cl IN ( $FILTER_YEARS ) )
            AND (1=$FILTER_ADDRESS_ARGO_FLAG OR addr_argo IN ( $FILTER_ADDRESS_ARGO ) )
            AND (1=$FILTER_ADDRESS_GSUITE_FLAG OR addr_gsuite IN ( $FILTER_ADDRESS_GSUITE ) )
            AND (1=$FILTER_CLASSES_FLAG OR sezione_gsuite IN ( $FILTER_CLASSES ) )
            AND (1=$FILTER_SUPERVISORS_EXISTS OR 
                  ( email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' )
                )
            AND (1=$FILTER_SUPERVISORS_NOT_EXISTS OR 
                  ( email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' )
                )
          ORDER BY $ORDERING ASC ;
    " 
}

function query::getQuerySezioniDefaultValues {
  local FIELDS="${1:-${sectionQueryParam[FIELDS]}}"
  local ORDERING="${2:-${sectionQueryParam[ORDERING]}}"

  query=$(query::getQuerySezioni "$FIELDS" "$ORDERING")
  echo "$query"
}

function query::getQuerySezioniSupervisorNotEmpty {
  declare cliParam=()
  cliParam[1]="${1:-${sectionQueryParam[FIELDS]}}"
  cliParam[2]="${2:-${sectionQueryParam[ORDERING]}}"
  cliParam[3]="${sectionQueryParam[FILTER_YEARS_OFF]}"
  cliParam[4]=" "
  cliParam[5]="${sectionQueryParam[FILTER_ADDRESS_ARGO_OFF]}"
  cliParam[6]=" "
  cliParam[7]="${sectionQueryParam[FILTER_ADDRESS_GSUITE_OFF]}"
  cliParam[8]=" "
  cliParam[9]="${sectionQueryParam[FILTER_CLASSES_OFF]}"
  cliParam[10]=" "
  cliParam[11]="${sectionQueryParam[FILTER_SUPERVISORS_EXISTS_ON]}"
  cliParam[12]="${sectionQueryParam[FILTER_SUPERVISORS_NOT_EXISTS_OFF]}"

  query=$(query::getQuerySezioni "${cliParam[@]}" )
  echo "$query"
}

declare -A employeesQueryParam=(
  [FIELDS]=" * "
  [ORDERING]=" cognome "
  [FILTER_TIPO_PERSONALE_ON]=0
  [FILTER_TIPO_PERSONALE_OFF]=1
  [FILTER_TIPO_PERSONALE]=" '' "

  [FILTER_CODICE_FISCALE_EXISTS_ON]=0
  [FILTER_CODICE_FISCALE_EXISTS_OFF]=1
  [FILTER_CODICE_FISCALE_NOT_EXISTS_ON]=0
  [FILTER_CODICE_FISCALE_NOT_EXISTS_OFF]=1

  [FILTER_EMAIL_PERSONALE_EXISTS_ON]=0
  [FILTER_EMAIL_PERSONALE_EXISTS_OFF]=1
  [FILTER_EMAIL_PERSONALE_NOT_EXISTS_ON]=0
  [FILTER_EMAIL_PERSONALE_NOT_EXISTS_OFF]=1

  [FILTER_EMAIL_GSUITE_EXISTS_ON]=0
  [FILTER_EMAIL_GSUITE_EXISTS_OFF]=1
  [FILTER_EMAIL_GSUITE_NOT_EXISTS_ON]=0
  [FILTER_EMAIL_GSUITE_NOT_EXISTS_OFF]=1

  [FILTER_EMAIL_GSUITE_PREFIX_ON]=0
  [FILTER_EMAIL_GSUITE_PREFIX_OFF]=1
  [FILTER_EMAIL_GSUITE_PREFIX]=" '' "

  [FILTER_AGGIUNTO_IL_ON]=0
  [FILTER_AGGIUNTO_IL_OFF]=1
  [FILTER_AGGIUNTO_IL_MIN]=" '2020-01-01' "
  [FILTER_AGGIUNTO_IL_MAX]=" '2030-01-01' "

  [FILTER_CANCELLATO_IL_ON]=0
  [FILTER_CANCELLATO_IL_OFF]=1
  [FILTER_CANCELLATO_IL_MIN]=" '2020-01-01' "
  [FILTER_CANCELLATO_IL_MAX]=" '2030-01-01' "

  [FILTER_CONTRATTO_EXISTS_ON]=0
  [FILTER_CONTRATTO_EXISTS_OFF]=1
  [FILTER_CONTRATTO_NOT_EXISTS_ON]=0
  [FILTER_CONTRATTO_NOT_EXISTS_OFF]=1

  [FILTER_DIPARTIMENTO_EXISTS_ON]=0
  [FILTER_DIPARTIMENTO_EXISTS_OFF]=1
  [FILTER_DIPARTIMENTO_NOT_EXISTS_ON]=0
  [FILTER_DIPARTIMENTO_NOT_EXISTS_OFF]=1

  [FILTER_NOTE_EXISTS_ON]=0
  [FILTER_NOTE_EXISTS_OFF]=1
  [FILTER_NOTE_NOT_EXISTS_ON]=0
  [FILTER_NOTE_NOT_EXISTS_OFF]=1
)

function query::getQueryEmployeesData {
    local FIELDS="${1:-${employeesQueryParam[FIELDS]}}"
    local ORDERING="${2:-${employeesQueryParam[ORDERING]}}"
    
    local FILTER_TIPO_PERSONALE_FLAG="${3:-${employeesQueryParam[FILTER_TIPO_PERSONALE_OFF]}}"
    local FILTER_TIPO_PERSONALE_IN="${4:-${employeesQueryParam[FILTER_TIPO_PERSONALE]}}"
    
    local FILTER_CODICE_FISCALE_EXISTS="${5:-${employeesQueryParam[FILTER_CODICE_FISCALE_EXISTS_OFF]}}"
    local FILTER_CODICE_FISCALE_NOT_EXISTS="${6:-${employeesQueryParam[FILTER_CODICE_FISCALE_NOT_EXISTS_OFF]}}"
    local FILTER_EMAIL_PERSONALE_EXISTS="${7:-${employeesQueryParam[FILTER_EMAIL_PERSONALE_EXISTS_OFF]}}"
    local FILTER_EMAIL_PERSONALE_NOT_EXISTS="${8:-${employeesQueryParam[FILTER_EMAIL_PERSONALE_NOT_EXISTS_OFF]}}"
    local FILTER_EMAIL_GSUITE_EXISTS="${9:-${employeesQueryParam[FILTER_EMAIL_GSUITE_EXISTS_OFF]}}"
    local FILTER_EMAIL_GSUITE_NOT_EXISTS="${10:-${employeesQueryParam[FILTER_EMAIL_GSUITE_NOT_EXISTS_OFF]}}"

    local FILTER_EMAIL_GSUITE_PREFIX_FLAG="${11:-${employeesQueryParam[FILTER_EMAIL_GSUITE_PREFIX_OFF]}}"
    local FILTER_EMAIL_GSUITE_PREFIX="${12:-${employeesQueryParam[FILTER_EMAIL_GSUITE_PREFIX]}}"
    

    local FILTER_AGGIUNTO_IL_FLAG="${13:-${employeesQueryParam[FILTER_AGGIUNTO_IL_OFF]}}"
    local FILTER_AGGIUNTO_IL_MIN="${14:-${employeesQueryParam[FILTER_AGGIUNTO_IL_MIN]}}"
    local FILTER_AGGIUNTO_IL_MAX="${15:-${employeesQueryParam[FILTER_AGGIUNTO_IL_MAX]}}"
    
    local FILTER_CANCELLATO_IL_FLAG="${16:-${employeesQueryParam[FILTER_CANCELLATO_IL_OFF]}}"
    local FILTER_CANCELLATO_IL_MIN="${17:-${employeesQueryParam[FILTER_CANCELLATO_IL_MIN]}}"
    local FILTER_CANCELLATO_IL_MAX="${18:-${employeesQueryParam[FILTER_CANCELLATO_IL_MAX]}}"
    
    local FILTER_CONTRATTO_EXISTS="${19:-${employeesQueryParam[FILTER_CONTRATTO_EXISTS_OFF]}}"
    local FILTER_CONTRATTO_NOT_EXISTS="${20:-${employeesQueryParam[FILTER_CONTRATTO_NOT_EXISTS_OFF]}}"
    
    local FILTER_DIPARTIMENTO_EXISTS="${21:-${employeesQueryParam[FILTER_DIPARTIMENTO_EXISTS_OFF]}}"
    local FILTER_DIPARTIMENTO_NOT_EXISTS="${22:-${employeesQueryParam[FILTER_DIPARTIMENTO_NOT_EXISTS_OFF]}}"
    
    local FILTER_NOTE_EXISTS="${23:-${employeesQueryParam[FILTER_NOTE_EXISTS_OFF]}}"
    local FILTER_NOTE_NOT_EXISTS="${24:-${employeesQueryParam[FILTER_NOTE_NOT_EXISTS_OFF]}}"
    # Costruzione della query basata sui parametri
    echo "
          SELECT $FIELDS 
          FROM $TABELLA_PERSONALE
          WHERE 1=1 
            AND (1=$FILTER_TIPO_PERSONALE_FLAG OR LOWER(tipo_personale) IN ( $FILTER_TIPO_PERSONALE_IN ))
            AND (1=$FILTER_CODICE_FISCALE_EXISTS OR 
                  (codice_fiscale IS NOT NULL AND LOWER(codice_fiscale) != ''))
            AND (1=$FILTER_CODICE_FISCALE_NOT_EXISTS OR 
                  (codice_fiscale IS NULL OR LOWER(codice_fiscale) = ''))
            AND (1=$FILTER_EMAIL_PERSONALE_EXISTS OR 
                  (email_personale IS NOT NULL AND LOWER(email_personale) != ''))
            AND (1=$FILTER_EMAIL_PERSONALE_NOT_EXISTS OR 
                  (email_personale IS NULL OR LOWER(email_personale) = ''))
            AND (1=$FILTER_EMAIL_GSUITE_EXISTS OR 
                  (email_gsuite IS NOT NULL AND LOWER(email_gsuite) != ''))
            AND (1=$FILTER_EMAIL_GSUITE_NOT_EXISTS OR 
                  (email_gsuite IS NULL OR LOWER(email_gsuite) = ''))
            AND (1=$FILTER_EMAIL_GSUITE_PREFIX_FLAG OR 
                  LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) IN ( $FILTER_EMAIL_GSUITE_PREFIX ))
            AND (1=$FILTER_AGGIUNTO_IL_FLAG OR 
                  (aggiunto_il BETWEEN $FILTER_AGGIUNTO_IL_MIN AND $FILTER_AGGIUNTO_IL_MAX ))
            AND (1=$FILTER_CANCELLATO_IL_FLAG OR 
                  (cancellato_il BETWEEN $FILTER_CANCELLATO_IL_MIN AND $FILTER_CANCELLATO_IL_MAX ))
            AND (1=$FILTER_CONTRATTO_EXISTS OR 
                  (contratto IS NOT NULL AND LOWER(contratto) != ''))
            AND (1=$FILTER_CONTRATTO_NOT_EXISTS OR 
                  (contratto IS NULL OR LOWER(contratto) = ''))
            AND (1=$FILTER_DIPARTIMENTO_EXISTS OR 
                  (dipartimento IS NOT NULL AND LOWER(dipartimento) != ''))
            AND (1=$FILTER_DIPARTIMENTO_NOT_EXISTS OR 
                  (dipartimento IS NULL OR LOWER(dipartimento) = ''))
            AND (1=$FILTER_NOTE_EXISTS OR 
                  (note IS NOT NULL AND LOWER(note) != ''))
            AND (1=$FILTER_NOTE_NOT_EXISTS OR 
                  (note IS NULL OR LOWER(note) = ''))
          ORDER BY $ORDERING ASC;
    "
}

function query::getQueryEmployeesDefaultValues {
  local FIELDS="${1:-${employeesQueryParam[FIELDS]}}"
  local ORDERING="${2:-${employeesQueryParam[ORDERING]}}"

  query=$(query::getQueryEmployeesData "$FIELDS" "$ORDERING")
  echo "$query"
}

function query::getQueryTeachersWithGSuiteEmail {
  declare cliParam=()
  cliParam[1]="${1:-${employeesQueryParam[FIELDS]}}"
  cliParam[2]="${2:-${employeesQueryParam[ORDERING]}}"
  cliParam[3]="${employeesQueryParam[FILTER_TIPO_PERSONALE_ON]}"
  cliParam[4]="'docente'"
  cliParam[5]="${employeesQueryParam[FILTER_CODICE_FISCALE_EXISTS_OFF]}"
  cliParam[6]="${employeesQueryParam[FILTER_CODICE_FISCALE_NOT_EXISTS_OFF]}"
  cliParam[7]="${employeesQueryParam[FILTER_EMAIL_PERSONALE_EXISTS_OFF]}"
  cliParam[8]="${employeesQueryParam[FILTER_EMAIL_PERSONALE_NOT_EXISTS_OFF]}"
  cliParam[9]="${employeesQueryParam[FILTER_EMAIL_GSUITE_EXISTS_ON]}"
  cliParam[10]="${employeesQueryParam[FILTER_EMAIL_GSUITE_NOT_EXISTS_OFF]}"
  cliParam[11]="${employeesQueryParam[FILTER_EMAIL_GSUITE_PREFIX_OFF]}"
  cliParam[12]="${employeesQueryParam[FILTER_EMAIL_GSUITE_PREFIX]}"
  cliParam[13]="${employeesQueryParam[FILTER_AGGIUNTO_IL_OFF]}"
  cliParam[14]="'min'"
  cliParam[15]="'max'"
  cliParam[16]="${employeesQueryParam[FILTER_CANCELLATO_IL_OFF]}"
  cliParam[17]="'min'"
  cliParam[18]="'max'"
  cliParam[19]="${employeesQueryParam[FILTER_CONTRATTO_EXISTS_OFF]}"
  cliParam[20]="${employeesQueryParam[FILTER_CONTRATTO_NOT_EXISTS_OFF]}"
  cliParam[21]="${employeesQueryParam[FILTER_DIPARTIMENTO_EXISTS_OFF]}"
  cliParam[22]="${employeesQueryParam[FILTER_DIPARTIMENTO_NOT_EXISTS_OFF]}"
  cliParam[23]="${employeesQueryParam[FILTER_NOTE_EXISTS_OFF]}"
  cliParam[24]="${employeesQueryParam[FILTER_NOTE_NOT_EXISTS_OFF]}"

  query=$(query::getQueryEmployeesData "${cliParam[@]}" )
  echo "$query"
}

# Esempio di come chiamare la funzione
if log::level_is_active "DEBUG"; then
  query="$(query::getQueryTeachersWithGSuiteEmail )"
  echo "$query"
fi
