#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# ./_query.sh "cl, addr_argo" "addr_argo" "$DISABLE_QUERY_FILTER" "1, 2, 3"  
#       "$DISABLE_QUERY_FILTER" "'tr', 'en'"  "$DISABLE_QUERY_FILTER"  " "  
#       "$DISABLE_QUERY_FILTER" " '1A_MEC' "  
#        "$ENABLE_QUERY_FILTER"  "$ENABLE_QUERY_FILTER"

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
  [OFF]=100
)

function query::getQuerySezioni {
    local FIELDS="${1:-${sectionQueryParam[FIELDS]}}"
    local ORDERING="${2:-${sectionQueryParam[ORDERING]}}"
    local FILTER_YEARS_ON="${3:-${sectionQueryParam[FILTER_YEARS_ON]}}"
    local FILTER_YEARS="${4:-${sectionQueryParam[FILTER_YEARS]}}"
    local FILTER_ADDRESS_ARGO_ON="${5:-${sectionQueryParam[FILTER_ADDRESS_ARGO_ON]}}"
    local FILTER_ADDRESS_ARGO="${6:-${sectionQueryParam[FILTER_ADDRESS_ARGO]}}"
    local FILTER_ADDRESS_GSUITE_ON="${7:-${sectionQueryParam[FILTER_ADDRESS_GSUITE_OFF]}}"
    local FILTER_ADDRESS_GSUITE="${8:-${sectionQueryParam[FILTER_ADDRESS_GSUITE]}}"
    local FILTER_CLASSES_ON="${9:-${sectionQueryParam[FILTER_CLASSES_OFF]}}"
    local FILTER_CLASSES="${10:-${sectionQueryParam[FILTER_CLASSES]}}"
    local FILTER_SUPERVISORS_EXISTS="${11:-${sectionQueryParam[FILTER_SUPERVISORS_EXISTS_OFF]}}"
    local FILTER_SUPERVISORS_NOT_EXISTS="${12:-${sectionQueryParam[FILTER_SUPERVISORS_NOT_EXISTS_OFF]}}"

    echo "
          SELECT $FIELDS 
          FROM $TABELLA_SEZIONI
          WHERE 1=1 
            AND (1=$FILTER_YEARS_ON OR cl IN ( $FILTER_YEARS ) )
            AND (1=$FILTER_ADDRESS_ARGO_ON OR addr_argo IN ( $FILTER_ADDRESS_ARGO ) )
            AND (1=$FILTER_ADDRESS_GSUITE_ON OR addr_gsuite IN ( $FILTER_ADDRESS_GSUITE ) )
            AND (1=$FILTER_CLASSES_ON OR sezione_gsuite IN ( $FILTER_CLASSES ) )
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
  local FIELDS="${1:-${sectionQueryParam[FIELDS]}}"
  local ORDERING="${2:-${sectionQueryParam[ORDERING]}}"

  query=$(query::getQuerySezioni "$FIELDS" "$ORDERING" "${sectionQueryParam[FILTER_YEARS_OFF]}" " "  "${sectionQueryParam[FILTER_ADDRESS_ARGO_OFF]}" " " "${sectionQueryParam[FILTER_ADDRESS_GSUITE_OFF]}" " " "${sectionQueryParam[FILTER_CLASSES_OFF]}" " " "${sectionQueryParam[FILTER_SUPERVISORS_EXISTS_ON]}" "${sectionQueryParam[FILTER_SUPERVISORS_NOT_EXISTS_OFF]}" )
  echo "$query"
}

if log::level_is_active "DEBUG"; then
  query="$(query::getQuerySezioniSupervisorNotEmpty )"
  echo "$query"
fi
