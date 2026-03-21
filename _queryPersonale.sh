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
  employeesParam[FLAG_TIPO_PERSONALE]="$FLAG_OFF"
  employeesParam[FILTER_TIPO_PERSONALE_IN]=" '' "

  employeesParam[FLAG_CODICE_FISCALE_EXISTS]="$FLAG_OFF"
  employeesParam[FLAG_CODICE_FISCALE_NOT_EXISTS]="$FLAG_OFF"

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

  declare -p employeesParam
}

function query::getQueryEmployees {
  local employeesParam

  # clona mappa modificata
  employeesParam="$1"
  eval "${employeesParam}"

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

function query::getQueryEmployeesDefaultValues {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

  # modifica mappa
  employeesParam[FIELDS]="${1:-${employeesParam[FIELDS]}}"
  employeesParam[ORDERING]="${2:-${employeesParam[ORDERING]}}"

  # clona mappa modificata
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}

function query::getEmployeesNonDeletedWithoutEmailGSuite {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

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
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}

function query::getEmployeesNotDeletedAddedInPeriod {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

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
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}

function query::getTeachersNotDeletedAddedInPeriod {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

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
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}


function query::getAtaNotDeletedAddedInPeriod {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

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
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}

function query::getQueryTeachersWithGSuiteEmail {
  local employeesParam

  # clona mappa
  employeesParam="$(query::defaultEmployeesParam)"
  eval "${employeesParam}"

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
  employeesParam="$(declare -p employeesParam)"

  query=$(query::getQueryEmployees "$employeesParam" )
  echo "$query"
}

# Esempio di come chiamare la funzione
if log::level_is_active "DEBUG"; then
  query="$(query::getEmployeesNotDeletedAddedInPeriod )"
  echo "$query"
fi
