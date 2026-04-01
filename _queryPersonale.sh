#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::dropTableIfExists() {
  local TABLE="${1:-${TABELLA_PERSONALE}}"
  echo "
    DROP TABLE IF EXISTS '$TABLE';
  "
}

function query::createTableIfNotExists() {
  local TABLE="${1:-${TABELLA_PERSONALE}}"
  echo "
    CREATE TABLE IF NOT EXISTS '$TABLE' ( 
      tipo_personale VARCHAR(200), 
      cognome VARCHAR(200), 
      nome VARCHAR(200), 
      data_nascita VARCHAR(200), 
      codice_fiscale VARCHAR(200), 
      telefono VARCHAR(200), 
      altro_telefono VARCHAR(200), 
      cellulare VARCHAR(200), 
      email_personale VARCHAR(200), 
      email_gsuite VARCHAR(200), 
      aggiunto_il TEXT, 
      cancellato_il TEXT, 
      contratto VARCHAR(200), 
      dipartimento VARCHAR(200), 
      note VARCHAR(200)
    );
  "
}

function query::normalizeFields() {
  local TABLE="${1:-${TABELLA_PERSONALE}}"
  echo "
    UPDATE $TABLE 
    SET codice_fiscale = TRIM(UPPER(codice_fiscale)),
      tipo_personale = TRIM(LOWER(tipo_personale)),
      email_personale = TRIM(LOWER(email_personale)),
      cognome = TRIM(UPPER(cognome)),
      nome = TRIM(UPPER(nome))
  "
}

function query::normalizeInsertDate() {
  local TABLE="${1:-${TABELLA_PERSONALE}}"
  local addedDateFormat
  addedDateFormat="$(getDateFormat 'aggiunto_il')"
  echo "
    UPDATE $TABLE 
      SET aggiunto_il = date($addedDateFormat)
      WHERE aggiunto_il is NOT NULL AND TRIM(aggiunto_il) != '';
  "
}

function query::normalizeRetiredDate() {
  local TABLE="${1:-${TABELLA_PERSONALE}}"
  local cancelledDateFormat
  cancelledDateFormat="$(getDateFormat 'cancellato_il')"
  echo "
    UPDATE $TABLE 
    SET cancellato_il = date($cancelledDateFormat)
    WHERE cancellato_il IS NOT NULL AND TRIM(cancellato_il) != ''
  "
}

function query::createEmailTeachers() {
  echo "
    UPDATE $TABELLA_PERSONALE
    SET email_gsuite = 'd.' || 
          REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
          REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
        aggiunto_il = '$CURRENT_DATE'
    WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
      AND (email_gsuite IS NULL OR TRIM(email_gsuite) = '')
      AND UPPER(tipo_personale) = UPPER('docente')
      AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '');
  "
}

function query::createEmailATA() {
  echo "
    UPDATE $TABELLA_PERSONALE
    SET email_gsuite = 'a.' || 
          REPLACE(REPLACE(LOWER(nome), '''', ''), ' ', '') || '.' || 
          REPLACE(REPLACE(LOWER(cognome), '''',''), ' ', '') || '@$DOMAIN', 
        aggiunto_il = '$CURRENT_DATE'
    WHERE email_personale IS NOT NULL AND TRIM(email_personale) != ''
      AND (email_gsuite IS NULL OR TRIM(email_gsuite) = '')
      AND UPPER(tipo_personale) = UPPER('ata')
      AND (cancellato_il IS NULL OR TRIM(cancellato_il) = '');
  "
}

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

  employeesParam[FLAG_NOTE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_NOTE_NOT_EXISTS]="$FLAG_OFF"

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
    FROM $TABELLA_PERSONALE
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
      AND (1=${employeesParam[FLAG_NOTE_EXISTS]} OR 
        (note IS NOT NULL AND LOWER(note) != '' ))
      AND (1=${employeesParam[FLAG_NOTE_NOT_EXISTS]} OR 
        (note IS NULL OR LOWER(note) = '' ))
    ORDER BY ${employeesParam[ORDERING]} ASC;
  "
}

function query::getQueryOldEmployeesCfNotIn {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"
  employeesParam[TABLE]=" $TABELLA_PERSONALE_PRECEDENTE "

  employeesParam[FLAG_CODICE_FISCALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_CODICE_FISCALE_NOT_IN]="$FLAG_ON"
  employeesParam[FILTER_CODICE_FISCALE_NOT_IN]="${3:-${employeesParam[FILTER_CODICE_FISCALE_NOT_IN]}}"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getQueryEmployeesDefaultValues {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getQueryOldEmployeesDefaultValues {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"
  employeesParam[TABLE]="$TABELLA_PERSONALE_PRECEDENTE"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getEmployeesNonDeletedWithoutEmailGSuite {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  local EMPLOYEES_FIELDS="LOWER(tipo_personale) as tipo, 
    UPPER(cognome) as cognome, UPPER(nome) as nome, 
    LOWER(email_personale) as email_personale, 
    LOWER(email_gsuite) as email_gsuite"
  employeesParam[FIELDS]="${1:-$EMPLOYEES_FIELDS}"
  employeesParam[ORDERING]="${2:-cognome}"
  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_NON_CANCELLATO]="$FLAG_ON"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getEmployeesNotDeletedAddedInPeriod {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  local EMPLOYEES_FIELDS="LOWER(tipo_personale) as tipo, 
    UPPER(cognome) as cognome, UPPER(nome) as nome, 
    LOWER(email_personale) as email_personale, 
    LOWER(email_gsuite) as email_gsuite, aggiunto_il"
  employeesParam[FIELDS]="${1:-$EMPLOYEES_FIELDS}"
  employeesParam[ORDERING]="${2:-cognome}"
  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"
  employeesParam[FLAG_NON_CANCELLATO]="$FLAG_ON"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getTeachersNotDeletedAddedInPeriod {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-cognome}"
  employeesParam[FLAG_TIPO_PERSONALE]="$FLAG_ON"
  employeesParam[FILTER_TIPO_PERSONALE_IN]=" 'docente' "
  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_PREFIX]="$FLAG_ON"
  employeesParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" 'd.' "
  employeesParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"
  employeesParam[FLAG_NON_CANCELLATO]="$FLAG_ON"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getAtaNotDeletedAddedInPeriod {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-cognome}"
  employeesParam[FLAG_TIPO_PERSONALE]="$FLAG_ON"
  employeesParam[FILTER_TIPO_PERSONALE_IN]=" 'ata' "
  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_PREFIX]="$FLAG_ON"
  employeesParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" 'a.' "
  employeesParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"
  employeesParam[FLAG_NON_CANCELLATO]="$FLAG_ON"

  # clona mappa modificata
  local queryParamString
  queryParamString="$(declare -p "employeesParam")"

  local query
  query="$(query::getQueryEmployees "$queryParamString" )"
  echo "$query"
}

function query::getQueryTeachersWithGSuiteEmail {
  local queryParam
  queryParam="$(query::defaultEmployeesParam)"

  # clona mappa
  local -A employeesParam=()
  eval "${queryParam}"

  # modifica mappa
  # modifica mappa
  local EMPLOYEES_FIELDS="LOWER(tipo_personale) as tipo, 
    UPPER(cognome) as cognome, UPPER(nome) as nome, 
    LOWER(email_personale) as email_personale, 
    LOWER(email_gsuite) as email_gsuite, aggiunto_il"
  employeesParam[FIELDS]="${1:-$EMPLOYEES_FIELDS}"
  employeesParam[ORDERING]="${2:-cognome}"
  employeesParam[FLAG_TIPO_PERSONALE]="$FLAG_ON"
  employeesParam[FILTER_TIPO_PERSONALE_IN]=" 'docente' "
  employeesParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_ON"
  employeesParam[FLAG_EMAIL_GSUITE_PREFIX]="$FLAG_ON"
  employeesParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" 'd.' "
  
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
