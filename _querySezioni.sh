#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::defaultSectionParam() {
  local -A sectionParam=()
  sectionParam[FIELDS]=" * "
  sectionParam[ORDERING]=" sezione_gsuite "
  sectionParam[FLAG_YEARS]="$FLAG_ON"
  sectionParam[FILTER_YEARS]="$SQL_FILTRO_ANNI"
  sectionParam[FLAG_ADDRESS_ARGO]="$FLAG_ON"
  sectionParam[FILTER_ADDRESS_ARGO]="$SQL_FILTRO_SEZIONI"
  sectionParam[FLAG_ADDRESS_GSUITE]="$FLAG_OFF"
  sectionParam[FILTER_ADDRESS_GSUITE]=" '' "
  sectionParam[FLAG_CLASSES]="$FLAG_OFF"
  sectionParam[FILTER_CLASSES]=" '' "
  sectionParam[FLAG_SUPERVISORS_EXISTS]="$FLAG_OFF"
  sectionParam[FLAG_SUPERVISORS_NOT_EXISTS]="$FLAG_OFF"

  declare -p sectionParam
}

function query::getQuerySezioni {
  local queryParam
  queryParam="${1}"

  # clona mappa
  local -A sectionParam=()
  eval "${queryParam}"
  
  echo "
    SELECT ${sectionParam[FIELDS]}
    FROM $TABELLA_SEZIONI
    WHERE 1=1 
      AND (1=${sectionParam[FLAG_YEARS]} OR 
        cl IN ( ${sectionParam[FILTER_YEARS]} ) )
      AND (1=${sectionParam[FLAG_ADDRESS_ARGO]} OR 
        addr_argo IN ( ${sectionParam[FILTER_ADDRESS_ARGO]} ) )
      AND (1=${sectionParam[FLAG_ADDRESS_GSUITE]} OR 
        addr_gsuite IN ( ${sectionParam[FILTER_ADDRESS_GSUITE]} ) )
      AND (1=${sectionParam[FLAG_CLASSES]} OR 
        sezione_gsuite IN ( ${sectionParam[FILTER_CLASSES]} ) )
      AND (1=${sectionParam[FLAG_SUPERVISORS_EXISTS]} OR 
        ( email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' ) )
      AND (1=${sectionParam[FLAG_SUPERVISORS_NOT_EXISTS]} OR 
        ( email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' ) )
    ORDER BY ${sectionParam[ORDERING]} ASC;
  " 
}

function query::querySezioniTutte {
  local queryParam
  queryParam="$(query::defaultSectionParam)"

  # clona mappa
  local -A sectionParam=()
  eval "$queryParam"

  # modifica mappa
  sectionParam[FIELDS]="${1:-${sectionParam[FIELDS]}}"
  sectionParam[ORDERING]="${2:-${sectionParam[ORDERING]}}"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p sectionParam)"

  local query
  query=$(query::getQuerySezioni "$queryParamString")
  echo "$query"
}

function query::querySezioniSupervisorNotEmpty {
  local queryParam
  queryParam="$(query::defaultSectionParam)"

  # clona mappa
  local -A sectionParam=()
  eval "$queryParam"

  # modifica mappa
  sectionParam[FIELDS]="${1:-${sectionParam[FIELDS]}}"
  sectionParam[ORDERING]="${2:-${sectionParam[ORDERING]}}"
  sectionParam[FLAG_SUPERVISORS_EXISTS]="$FLAG_ON"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p sectionParam)"

  local query
  query=$(query::getQuerySezioni "$queryParamString" )
  echo "$query"
}

# Esempio di come chiamare la funzione
function execDebug {
  if log::level_is_active "DEBUG"; then
    local query
    query="$(query::querySezioniSupervisorNotEmpty)"
    echo "$query"
  fi
}

execDebug
