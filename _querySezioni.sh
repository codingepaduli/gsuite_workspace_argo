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

function query::queryCreaSezioniDaStudenti {
  local query
  query="
    SELECT cl, sez_argo, letter, addr_argo, 
      UPPER(addr_gsuite), 
      UPPER(letter || '_' || addr_gsuite) AS sez_gsuite,
      UPPER(cl || letter || '_' || addr_gsuite) AS sezione_gsuite
    FROM (
      SELECT DISTINCT 
        TRIM(sa.cl) AS cl,
        TRIM(sa.sez) AS sez_argo,
        TRIM(SUBSTR(sa.sez,1,1)) AS letter,
        TRIM(SUBSTR(sa.sez,2)) AS addr_argo,
        CASE
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'in' THEN 'INF' 
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'm' THEN 'MEC' 
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'mDD' THEN 'MDD' 
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'me_sirio' THEN 'MEC_SIRIO'
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'm_sirio' THEN 'MEC_SIRIO' 
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'tlt' THEN 'TLC' 
              WHEN TRIM(SUBSTR(sa.sez,2)) = 'tr' THEN 'AER' 
              ELSE TRIM(SUBSTR(sa.sez,2))
        END AS addr_gsuite
      FROM $TABELLA_STUDENTI sa 
      ORDER BY sa.cl, sa.sez
    )
  "
  echo "$query"
}

# Esempio di come chiamare la funzione
function execDebug {
  if log::level_is_active "DEBUG"; then
    local param
    param="$(query::defaultStudentsParam)"
    echo "$param"
    
    local query
    query="$(query::querySezioniSupervisorNotEmpty)"
    echo "$query"
  fi
}

execDebug
