#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::defaultEmployeesParam() {
  local -A employeesParam=()

  employeesParam[FIELDS]=" * "
  employeesParam[ORDERING]=" email_gsuite "
  employeesParam[TABLE]=" $TABELLA_PERSONALE "
  employeesParam[FLAG_TIPO_PERSONALE]="$FLAG_OFF"
  employeesParam[FILTER_TIPO_PERSONALE_IN]=" '' "

  employeesParam[FLAG_CODICE_FISCALE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_CODICE_FISCALE_NOT_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_CODICE_FISCALE_NOT_IN]="$FLAG_OFF"
  employeesParam[FILTER_CODICE_FISCALE_NOT_IN]="$FLAG_OFF"

  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_EMAIL_PERSONALE_NOT_EXISTS]="$FLAG_OFF"

  employeesParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_OFF"

  employeesParam[FLAG_EMAIL_GSUITE_PREFIX]="$FLAG_OFF"
  employeesParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" '' "

  employeesParam[FLAG_AGGIUNTO_IL]="$FLAG_OFF"
  employeesParam[FILTER_AGGIUNTO_IL_MIN]=" '$PERIODO_PERSONALE_DA' "
  employeesParam[FILTER_AGGIUNTO_IL_MAX]=" '$PERIODO_PERSONALE_A' "

  employeesParam[FLAG_NON_CANCELLATO]="$FLAG_OFF"
  employeesParam[FLAG_CANCELLATO_IL]="$FLAG_OFF"
  employeesParam[FILTER_CANCELLATO_IL_MIN]=" '$PERIODO_PERSONALE_DA' "
  employeesParam[FILTER_CANCELLATO_IL_MAX]=" '$PERIODO_PERSONALE_A' "

  employeesParam[FLAG_CONTRATTO_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_CONTRATTO_NOT_EXISTS]="$FLAG_OFF"

  employeesParam[FLAG_DIPARTIMENTO_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_DIPARTIMENTO_NOT_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_DIPARTIMENTO_IN]="$FLAG_OFF"
  employeesParam[FILTER_DIPARTIMENTO_IN]=" '' "

  employeesParam[FLAG_NOTE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_NOTE_NOT_EXISTS]="$FLAG_OFF"

  # sezioni
  employeesParam[FLAG_YEARS]="$FLAG_ON"
  employeesParam[FILTER_YEARS]="$SQL_FILTRO_ANNI"
  employeesParam[FLAG_ADDRESS_ARGO]="$FLAG_ON"
  employeesParam[FILTER_ADDRESS_ARGO]="$SQL_FILTRO_SEZIONI"
  employeesParam[FLAG_ADDRESS_GSUITE]="$FLAG_OFF"
  employeesParam[FILTER_ADDRESS_GSUITE]=" '' "
  employeesParam[FLAG_CLASSES]="$FLAG_OFF"
  employeesParam[FILTER_CLASSES]=" '' "
  employeesParam[FLAG_SUPERVISORS_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_SUPERVISORS_NOT_EXISTS]="$FLAG_OFF"

  declare -p "employeesParam"
}

function query::getQueryEmployees {
  local queryParam
  queryParam="$1"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  echo "
    SELECT ${employeesParam[FIELDS]}
    FROM ${employeesParam[TABLE]}
      LEFT JOIN $TABELLA_SEZIONI sz
        ON LOWER(sz.email_coordinatore) = LOWER(email_gsuite) 
          AND sz.email_coordinatore IS NOT NULL 
          AND LOWER(sz.email_coordinatore) != '' 
    WHERE 1=1 
      AND (1=${employeesParam[FLAG_TIPO_PERSONALE]} OR 
        LOWER(tipo_personale) IN ( ${employeesParam[FILTER_TIPO_PERSONALE_IN]} ))
      AND (1=${employeesParam[FLAG_CODICE_FISCALE_EXISTS]} OR 
        (codice_fiscale IS NOT NULL AND LOWER(codice_fiscale) != '' ))
      AND (1=${employeesParam[FLAG_CODICE_FISCALE_NOT_EXISTS]} OR 
        (codice_fiscale IS NULL OR LOWER(codice_fiscale) = '' ))
      AND (1=${employeesParam[FLAG_CODICE_FISCALE_NOT_IN]} OR 
        (LOWER(codice_fiscale) NOT IN ( ${employeesParam[FILTER_CODICE_FISCALE_NOT_IN]} )))
      AND (1=${employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]} OR 
        (email_personale IS NOT NULL AND LOWER(email_personale) != '' ))
      AND (1=${employeesParam[FLAG_EMAIL_PERSONALE_NOT_EXISTS]} OR 
        (email_personale IS NULL OR LOWER(email_personale) = '' ))
      AND (1=${employeesParam[FLAG_EMAIL_GSUITE_EXISTS]} OR 
        (email_gsuite IS NOT NULL AND LOWER(email_gsuite) != '' ))
      AND (1=${employeesParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]} OR 
        (email_gsuite IS NULL OR LOWER(email_gsuite) = '' ))
      AND (1=${employeesParam[FLAG_EMAIL_GSUITE_PREFIX]} OR 
        LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) 
          IN ( ${employeesParam[FILTER_EMAIL_GSUITE_PREFIX_IN]} ))
      AND (1=${employeesParam[FLAG_AGGIUNTO_IL]} OR 
        (aggiunto_il BETWEEN ${employeesParam[FILTER_AGGIUNTO_IL_MIN]} AND 
          ${employeesParam[FILTER_AGGIUNTO_IL_MAX]} ))
      AND (1=${employeesParam[FLAG_NON_CANCELLATO]} OR 
        (cancellato_il IS NULL OR LOWER(cancellato_il) = '' ))
      AND (1=${employeesParam[FLAG_CANCELLATO_IL]} OR 
        (cancellato_il IS NOT NULL AND LOWER(cancellato_il) != '' AND
        cancellato_il BETWEEN ${employeesParam[FILTER_CANCELLATO_IL_MIN]} AND
          ${employeesParam[FILTER_CANCELLATO_IL_MAX]} ))
      AND (1=${employeesParam[FLAG_CONTRATTO_EXISTS]} OR 
        (contratto IS NOT NULL AND LOWER(contratto) != '' ))
      AND (1=${employeesParam[FLAG_CONTRATTO_NOT_EXISTS]} OR 
        (contratto IS NULL OR LOWER(contratto) = '' ))
      AND (1=${employeesParam[FLAG_DIPARTIMENTO_EXISTS]} OR 
        (dipartimento IS NOT NULL AND LOWER(dipartimento) != '' ))
      AND (1=${employeesParam[FLAG_DIPARTIMENTO_NOT_EXISTS]} OR 
        (dipartimento IS NULL OR LOWER(dipartimento) = '' ))
      AND (1=${employeesParam[FLAG_DIPARTIMENTO_IN]} OR 
        (LOWER(dipartimento) IN ( ${employeesParam[FILTER_DIPARTIMENTO_IN]} )))
      AND (1=${employeesParam[FLAG_NOTE_EXISTS]} OR 
        (note IS NOT NULL AND LOWER(note) != '' ))
      AND (1=${employeesParam[FLAG_NOTE_NOT_EXISTS]} OR 
        (note IS NULL OR LOWER(note) = '' ))
      -- sezioni
      AND (1=${employeesParam[FLAG_YEARS]} OR 
        cl IN ( ${employeesParam[FILTER_YEARS]} ) )
      AND (1=${employeesParam[FLAG_ADDRESS_ARGO]} OR 
        addr_argo IN ( ${employeesParam[FILTER_ADDRESS_ARGO]} ) )
      AND (1=${employeesParam[FLAG_ADDRESS_GSUITE]} OR 
        addr_gsuite IN ( ${employeesParam[FILTER_ADDRESS_GSUITE]} ) )
      AND (1=${employeesParam[FLAG_CLASSES]} OR 
        sezione_gsuite IN ( ${employeesParam[FILTER_CLASSES]} ) )
      AND (1=${employeesParam[FLAG_SUPERVISORS_EXISTS]} OR 
        ( email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' ) )
      AND (1=${employeesParam[FLAG_SUPERVISORS_NOT_EXISTS]} OR 
        ( email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' ) )
    ORDER BY ${employeesParam[ORDERING]} ASC
  "
}

function query::getSezioniConCoordinatori {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"
  employeesParam[TABLE]="${3:-${TABELLA_PERSONALE}}"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getSezioniConCoordinatoriByAnno {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"
  employeesParam[FLAG_YEARS]="$FLAG_ON"
  employeesParam[FILTER_YEARS]="${3:-${employeesParam[FILTER_YEARS]}}"
  employeesParam[TABLE]="${4:-${TABELLA_PERSONALE}}"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

# Esempio di come chiamare la funzione
function execDebug {
  if log::level_is_active "DEBUG"; then
    local param
    param="$(query::defaultEmployeesParam)"
    echo "$param"
    
    local query
    query="$(query::getEmployeesNotDeletedAddedInPeriod)"
    echo "$query"
  fi
}

execDebug
