#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

# ./_query.sh "cl, addr_argo" "addr_argo" "$DISABLE_QUERY_FILTER" "1, 2, 3"  
#       "$DISABLE_QUERY_FILTER" "'tr', 'en'"  "$DISABLE_QUERY_FILTER"  " "  
#       "$DISABLE_QUERY_FILTER" " '1A_MEC' "  
#        "$ENABLE_QUERY_FILTER"  "$ENABLE_QUERY_FILTER"

function query::getQuerySezioni {
    local FIELDS="${1:-" * "}"
    local ORDERING="${2:-" sezione_gsuite "}"
    local FILTER_YEARS_ON="${3:-" 1 "}"
    local FILTER_YEARS="${4:-" $SQL_FILTRO_ANNI "}"
    local FILTER_ADDRESS_ARGO_ON="${5:-" 1 "}"
    local FILTER_ADDRESS_ARGO="${6:-" $SQL_FILTRO_SEZIONI "}"
    local FILTER_ADDRESS_GSUITE_ON="${7:-" 1 "}"
    local FILTER_ADDRESS_GSUITE="${8:-" '' "}"
    local FILTER_CLASSES_ON="${9:-" 1 "}"
    local FILTER_CLASSES="${10:-" '' "}"
    local FILTER_SUPERVISORS_EXISTS_ON="${11:-" 1 "}"
    local FILTER_SUPERVISORS_NOT_EXISTS_ON="${12:-" 0 "}"

    echo "
          SELECT $FIELDS 
          FROM $TABELLA_SEZIONI
          WHERE 1=1 
            AND (1=$FILTER_YEARS_ON OR cl IN ( $FILTER_YEARS ) )
            AND (1=$FILTER_ADDRESS_ARGO_ON OR addr_argo IN ( $FILTER_ADDRESS_ARGO ) )
            AND (1=$FILTER_ADDRESS_GSUITE_ON OR addr_gsuite IN ( $FILTER_ADDRESS_GSUITE ) )
            AND (1=$FILTER_CLASSES_ON OR sezione_gsuite IN ( $FILTER_CLASSES ) )
            AND (1=$FILTER_SUPERVISORS_EXISTS_ON OR 
                  ( email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' )
                )
            AND (1=$FILTER_SUPERVISORS_NOT_EXISTS_ON OR 
                  ( email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' )
                )
          ORDER BY $ORDERING ASC ;
    " 
}

if log::level_is_active "DEBUG"; then
  query="$(query::getQuerySezioni "$@")"
  echo "$query"
fi
