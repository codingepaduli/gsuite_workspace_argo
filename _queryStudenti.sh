#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::defaultStudentsParam() {
  declare -A studentsParam=()
  studentsParam[FIELDS]=" * "
  studentsParam[ORDERING]=" UPPER(cod_fisc) "
  studentsParam[FLAG_COD_FISC_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_COD_FISC_NOT_EXISTS]="$FLAG_OFF"

  studentsParam[FLAG_MATRICOLA_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_MATRICOLA_NOT_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_CODICE_SIDI_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_CODICE_SIDI_NOT_EXISTS]="$FLAG_OFF"
  
  studentsParam[FLAG_DATA_RITIRO_IL]="$FLAG_OFF"
  studentsParam[FILTER_DATA_RITIRO_IL_MIN]=" '$PERIODO_STUDENTI_DA' "
  studentsParam[FILTER_DATA_RITIRO_IL_MAX]=" '$PERIODO_STUDENTI_A' "

  studentsParam[FLAG_AGGIUNTO_IL]="$FLAG_OFF"
  studentsParam[FILTER_AGGIUNTO_IL_MIN]=" '$PERIODO_STUDENTI_DA' "
  studentsParam[FILTER_AGGIUNTO_IL_MAX]=" '$PERIODO_STUDENTI_A' "

  studentsParam[FLAG_NON_CANCELLATO]="$FLAG_OFF"
  studentsParam[FLAG_CANCELLATO_IL]="$FLAG_OFF"
  studentsParam[FILTER_CANCELLATO_IL_MIN]=" '$PERIODO_STUDENTI_DA' "
  studentsParam[FILTER_CANCELLATO_IL_MAX]=" '$PERIODO_STUDENTI_A' "

  studentsParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_OFF"

  studentsParam[FLAG_EMAIL_GSUITE_PREFIX_IN]="$FLAG_OFF"
  studentsParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" '' "

  # Param sections
  studentsParam[FLAG_YEARS_IN]="$FLAG_ON"
  studentsParam[FILTER_YEARS_IN]="$SQL_FILTRO_ANNI"
  studentsParam[FLAG_ADDRESS_ARGO_IN]="$FLAG_ON"
  studentsParam[FILTER_ADDRESS_ARGO_IN]="$SQL_FILTRO_SEZIONI"
  studentsParam[FLAG_ADDRESS_GSUITE_IN]="$FLAG_OFF"
  studentsParam[FILTER_ADDRESS_GSUITE_IN]=" '' "
  studentsParam[FLAG_CLASSES_IN]="$FLAG_OFF"
  studentsParam[FILTER_CLASSES_IN]=" '' "
  studentsParam[FLAG_SUPERVISORS_EXISTS]="$FLAG_OFF"
  studentsParam[FLAG_SUPERVISORS_NOT_EXISTS]="$FLAG_OFF"

  declare -p "studentsParam"
}

function query::getQueryStudenti {
  local queryParam
  queryParam="${1}"
  eval "${queryParam}"
  
  echo "
    SELECT ${studentsParam[FIELDS]}
    FROM $TABELLA_STUDENTI st 
      INNER JOIN $TABELLA_SEZIONI sz  
      ON st.sez = sz.sez_argo AND st.cl =sz.cl 
    WHERE 1=1 
      AND (1=${studentsParam[FLAG_COD_FISC_EXISTS]} OR 
        ( cod_fisc IS NOT NULL AND LOWER(cod_fisc) != '' ) )
      AND (1=${studentsParam[FLAG_COD_FISC_NOT_EXISTS]} OR 
        ( cod_fisc IS NULL OR LOWER(cod_fisc) = '' ) )
      AND (1=${studentsParam[FLAG_MATRICOLA_EXISTS]} OR 
        ( matricola IS NOT NULL AND LOWER(matricola) != '' ) )
      AND (1=${studentsParam[FLAG_MATRICOLA_NOT_EXISTS]} OR 
        ( matricola IS NULL OR LOWER(matricola) = '' ) )
      AND (1=${studentsParam[FLAG_CODICE_SIDI_EXISTS]} OR 
        ( codicesidi IS NOT NULL AND LOWER(codicesidi) != '' ) )
      AND (1=${studentsParam[FLAG_CODICE_SIDI_NOT_EXISTS]} OR 
        ( codicesidi IS NULL OR LOWER(codicesidi) = '' ) )
      AND (1=${studentsParam[FLAG_EMAIL_GSUITE_EXISTS]} OR 
        ( email_gsuite IS NOT NULL AND LOWER(email_gsuite) != '' ) )
      AND (1=${studentsParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]} OR 
        ( email_gsuite IS NULL OR LOWER(email_gsuite) = '' ) )
      AND (1=${studentsParam[FLAG_EMAIL_GSUITE_PREFIX_IN]} OR 
        LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) 
          IN ( ${studentsParam[FILTER_EMAIL_GSUITE_PREFIX_IN]} ))
      AND (1=${studentsParam[FLAG_AGGIUNTO_IL]} OR 
        (aggiunto_il BETWEEN ${studentsParam[FILTER_AGGIUNTO_IL_MIN]} AND 
          ${studentsParam[FILTER_AGGIUNTO_IL_MAX]} ))
      AND (1=${studentsParam[FLAG_NON_CANCELLATO]} OR 
        (datar IS NULL OR LOWER(datar) = '' ))
      AND (1=${studentsParam[FLAG_CANCELLATO_IL]} OR 
        (datar IS NOT NULL AND LOWER(datar) != '' AND
        datar BETWEEN ${studentsParam[FILTER_CANCELLATO_IL_MIN]} AND
          ${studentsParam[FILTER_CANCELLATO_IL_MAX]} ))
      -- filtro sezioni
      AND (1=${studentsParam[FLAG_YEARS_IN]} OR 
        sz.cl IN ( ${studentsParam[FILTER_YEARS_IN]} ) )
      AND (1=${studentsParam[FLAG_ADDRESS_ARGO_IN]} OR 
        sz.addr_argo IN ( ${studentsParam[FILTER_ADDRESS_ARGO_IN]} ) )
      AND (1=${studentsParam[FLAG_ADDRESS_GSUITE_IN]} OR 
        addr_gsuite IN ( ${studentsParam[FILTER_ADDRESS_GSUITE_IN]} ) )
      AND (1=${studentsParam[FLAG_CLASSES_IN]} OR 
        sz.sezione_gsuite IN ( ${studentsParam[FILTER_CLASSES_IN]} ) )
      AND (1=${studentsParam[FLAG_SUPERVISORS_EXISTS]} OR 
        ( sz.email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' ) )
      AND (1=${studentsParam[FLAG_SUPERVISORS_NOT_EXISTS]} OR 
        ( sz.email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' ) )
    ORDER BY ${studentsParam[ORDERING]} ASC;
  " 
}

function query::queryStudentiTutti {
  local queryParam
  
  # clona mappa
  queryParam="$(query::defaultStudentsParam)"
  eval "$queryParam"

  # modifica mappa
  studentsParam[FIELDS]="${1:-${studentsParam[FIELDS]}}"
  studentsParam[ORDERING]="${2:-${studentsParam[ORDERING]}}"

  # clona mappa modificata
  queryParam="$(declare -p studentsParam)"

  query=$(query::getQueryStudenti "$queryParam")
  echo "$query"
}

function query::queryStudentiSenzaEmail {
  local queryParam
  
  # clona mappa
  queryParam="$(query::defaultStudentsParam)"
  eval "$queryParam"

  # modifica mappa
  studentsParam[FIELDS]="${1:-${studentsParam[FIELDS]}}"
  studentsParam[ORDERING]="${2:-${studentsParam[ORDERING]}}"
  studentsParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_ON"

  # clona mappa modificata
  queryParam="$(declare -p studentsParam)"

  query=$(query::getQueryStudenti "$queryParam")
  echo "$query"
}


function query::queryStudentiNonCancellatiIscrittiInPeriodo {
  local queryParam
  
  # clona mappa
  queryParam="$(query::defaultStudentsParam)"
  eval "$queryParam"

  # modifica mappa
  studentsParam[FIELDS]="${1:-${studentsParam[FIELDS]}}"
  studentsParam[ORDERING]="${2:-${studentsParam[ORDERING]}}"
  studentsParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"
  studentsParam[FLAG_NON_CANCELLATO]="$FLAG_ON"

  # clona mappa modificata
  queryParam="$(declare -p studentsParam)"

  query=$(query::getQueryStudenti "$queryParam")
  echo "$query"
}

function query::queryStudentiDellAnnoNonCancellatiIscrittiInPeriodo {
  local queryParam
  
  # clona mappa
  queryParam="$(query::defaultStudentsParam)"
  eval "$queryParam"

  # modifica mappa
  studentsParam[FIELDS]="${1:-${studentsParam[FIELDS]}}"
  studentsParam[ORDERING]="${2:-${studentsParam[ORDERING]}}"
  studentsParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"
  studentsParam[FLAG_NON_CANCELLATO]="$FLAG_ON"
  studentsParam[FLAG_YEARS_IN]="$FLAG_ON"
  studentsParam[FILTER_YEARS_IN]=" '$3' "

  # clona mappa modificata
  queryParam="$(declare -p "studentsParam")"

  query=$(query::getQueryStudenti "$queryParam")
  echo "$query"
}

# Esempio di come chiamare la funzione
function execDebug {
  if log::level_is_active "DEBUG"; then
    local param
    param="$(query::defaultStudentsParam)"
    echo "$param"

    local query
    query="$(query::queryStudentiTutti )"
    echo "$query"

    $SQLITE_CMD -header -table studenti.db " $query"
  fi
}

execDebug
