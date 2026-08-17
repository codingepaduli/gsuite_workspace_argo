#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::dropTableIfExists() {
  local TABLE="${1:-${TABELLA_CDC_ARGO}}"
  echo "
    DROP TABLE IF EXISTS '$TABLE';
  "
}

function query::createTableIfNotExists() {
  local TABLE="${1:-${TABELLA_CDC_ARGO}}"
  echo "
    CREATE TABLE IF NOT EXISTS '$TABLE' (
      \"Pr.\" INTEGER NOT NULL,
      Docente TEXT NOT NULL,
      Materie TEXT NOT NULL,
      Classi TEXT NOT NULL
    ) STRICT;
  "
}

function query::normalizeFields() {
  local TABLE="${1:-${TABELLA_CDC_ARGO}}"
  
  echo "
    UPDATE $TABLE 
    SET Docente = TRIM(UPPER(Docente)),
        Materie = TRIM(UPPER(Materie)),
        Classi = SUBSTR(Classi, 1, INSTR(Classi,' ')-1);
  "
}


function query::defaultCdCParam() {
  local -A cdcParam=()
  cdcParam[FIELDS]=" UPPER(docente) AS docente, materie AS materia "
  cdcParam[ORDERING]=" sezione_gsuite, cognome, nome "

  # filtro da tabella CdC
  cdcParam[FLAG_DOCENTE_NOT_IN]="$FLAG_OFF"
  cdcParam[FILTER_DOCENTE_NOT_IN]=" '' "
  cdcParam[FLAG_MATERIE_NOT_IN]="$FLAG_OFF"
  cdcParam[FILTER_MATERIE_NOT_IN]=" '' "

  # filtri da tabella personale
  cdcParam[FLAG_TIPO_PERSONALE]="$FLAG_OFF"
  cdcParam[FILTER_TIPO_PERSONALE_IN]=" '' "

  cdcParam[FLAG_CODICE_FISCALE_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_CODICE_FISCALE_NOT_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_CODICE_FISCALE_NOT_IN]="$FLAG_OFF"
  cdcParam[FILTER_CODICE_FISCALE_NOT_IN]=" '' "

  cdcParam[FLAG_EMAIL_PERSONALE_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_EMAIL_PERSONALE_NOT_EXISTS]="$FLAG_OFF"

  cdcParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_OFF"
  
  cdcParam[FLAG_EMAIL_GSUITE_PREFIX]="$FLAG_OFF"
  cdcParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" '' "

  cdcParam[FLAG_AGGIUNTO_IL]="$FLAG_OFF"
  cdcParam[FILTER_AGGIUNTO_IL_MIN]=" '$PERIODO_PERSONALE_DA' "
  cdcParam[FILTER_AGGIUNTO_IL_MAX]=" '$PERIODO_PERSONALE_A' "

  cdcParam[FLAG_NON_CANCELLATO]="$FLAG_OFF"
  cdcParam[FLAG_CANCELLATO_IL]="$FLAG_OFF"
  cdcParam[FILTER_CANCELLATO_IL_MIN]=" '$PERIODO_PERSONALE_DA' "
  cdcParam[FILTER_CANCELLATO_IL_MAX]=" '$PERIODO_PERSONALE_A' "

  cdcParam[FLAG_CONTRATTO_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_CONTRATTO_NOT_EXISTS]="$FLAG_OFF"

  cdcParam[FLAG_DIPARTIMENTO_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_DIPARTIMENTO_NOT_EXISTS]="$FLAG_OFF"

  ## filtro da tabella sezioni
  cdcParam[FLAG_YEARS_IN]="$FLAG_ON"
  cdcParam[FILTER_YEARS_IN]="$SQL_FILTRO_ANNI"
  cdcParam[FLAG_ADDRESS_ARGO_IN]="$FLAG_ON"
  cdcParam[FILTER_ADDRESS_ARGO_IN]="$SQL_FILTRO_SEZIONI"
  cdcParam[FLAG_ADDRESS_GSUITE_IN]="$FLAG_OFF"
  cdcParam[FILTER_ADDRESS_GSUITE_IN]=" '' "
  cdcParam[FLAG_CLASSES_IN]="$FLAG_OFF"
  cdcParam[FILTER_CLASSES_IN]=" '' "
  cdcParam[FLAG_SUPERVISORS_EXISTS]="$FLAG_OFF"
  cdcParam[FLAG_SUPERVISORS_NOT_EXISTS]="$FLAG_OFF"

  declare -p "cdcParam"
}

function query::getQueryCdc {
  local queryParam
  queryParam="${1}"
  
  local -A cdcParam=()
  eval "${queryParam}"

  echo "
    WITH consigli AS (
      SELECT cdc.* , sz.* , d.*,
        CASE 
          WHEN sz.cl IN (1, 2) AND sz.addr_argo IN ('en', 'et')         THEN 'primo_biennio_elettronica'
          WHEN sz.cl IN (1, 2) AND sz.addr_argo IN ('in', 'idd', 'tlt') THEN 'primo_biennio_informatica'
          WHEN sz.cl IN (1, 2) AND sz.addr_argo IN ('m', 'mDD')         THEN 'primo_biennio_meccanica'
          WHEN sz.cl IN (1, 2) AND sz.addr_argo IN ('od')               THEN 'primo_biennio_odontotecnica'
          WHEN sz.cl IN (1, 2) AND sz.addr_argo IN ('tr')               THEN 'primo_biennio_aeronautica'
          
          WHEN sz.cl IN (3, 4) AND sz.addr_argo IN ('en', 'et')         THEN 'secondo_biennio_elettronica'
          WHEN sz.cl IN (3, 4) AND sz.addr_argo IN ('in', 'idd', 'tlt') THEN 'secondo_biennio_informatica'
          WHEN sz.cl IN (3, 4) AND sz.addr_argo IN ('m', 'mDD')         THEN 'secondo_biennio_meccanica'
          WHEN sz.cl IN (3, 4) AND sz.addr_argo IN ('od')               THEN 'secondo_biennio_odontotecnica'
          WHEN sz.cl IN (3, 4) AND sz.addr_argo IN ('tr')               THEN 'secondo_biennio_aeronautica'
          
          WHEN sz.cl IN (6)                                             THEN 'diplomati'

          ELSE ''
        END AS biennio
      FROM $TABELLA_CDC_ARGO cdc
        INNER JOIN $TABELLA_SEZIONI sz
          ON cdc.classi = (sz.cl || sz.sez_argo)
        INNER JOIN $TABELLA_PERSONALE d
        ON UPPER(d.cognome || ' ' || d.nome) = UPPER(cdc.docente) 
    )
    SELECT ${cdcParam[FIELDS]}
    FROM consigli
    WHERE 1=1 
      -- tabella CdC
      AND (1=${cdcParam[FLAG_DOCENTE_NOT_IN]} OR 
        (docente IN ( ${cdcParam[FILTER_DOCENTE_NOT_IN]} ) ) )
      AND (1=${cdcParam[FLAG_MATERIE_NOT_IN]} OR 
        (materie IN ( ${cdcParam[FILTER_MATERIE_NOT_IN]} ) ) )

      -- tabella personale
      AND (1=${cdcParam[FLAG_TIPO_PERSONALE]} OR 
        (tipo_personale IN ( ${cdcParam[FILTER_TIPO_PERSONALE_IN]} ) ) )
      AND (1=${cdcParam[FLAG_CODICE_FISCALE_EXISTS]} OR 
        (codice_fiscale IS NOT NULL AND LOWER(codice_fiscale) != '' ) )
      AND (1=${cdcParam[FLAG_CODICE_FISCALE_NOT_EXISTS]} OR 
        (codice_fiscale IS NULL OR LOWER(codice_fiscale) = '' ) )
      AND (1=${cdcParam[FLAG_CODICE_FISCALE_NOT_IN]} OR 
        (codice_fiscale NOT IN ( ${cdcParam[FILTER_CODICE_FISCALE_NOT_IN]} ) ) )
      AND (1=${cdcParam[FLAG_EMAIL_PERSONALE_EXISTS]} OR 
        (email_personale IS NOT NULL AND LOWER(email_personale) != '' ) )
      AND (1=${cdcParam[FLAG_EMAIL_PERSONALE_NOT_EXISTS]} OR 
        (email_personale IS NULL OR LOWER(email_personale) = '' ) )
      AND (1=${cdcParam[FLAG_EMAIL_GSUITE_EXISTS]} OR 
        (email_gsuite IS NOT NULL AND LOWER(email_gsuite) != '' ) )
      AND (1=${cdcParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]} OR 
        (email_gsuite IS NULL OR LOWER(email_gsuite) = '' ) )
      AND (1=${cdcParam[FLAG_EMAIL_GSUITE_PREFIX]} OR 
        (LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) 
          IN ( ${cdcParam[FILTER_EMAIL_GSUITE_PREFIX_IN]} ) ) )
      AND (1=${cdcParam[FLAG_AGGIUNTO_IL]} OR 
        (aggiunto_il BETWEEN ${cdcParam[FILTER_AGGIUNTO_IL_MIN]} AND
          ${cdcParam[FILTER_AGGIUNTO_IL_MAX]} ) )
      AND (1=${cdcParam[FLAG_NON_CANCELLATO]} OR 
        (cancellato_il IS NULL OR LOWER(cancellato_il) = '' ) )
      AND (1=${cdcParam[FLAG_CANCELLATO_IL]} OR 
        (cancellato_il IS NOT NULL AND LOWER(cancellato_il) != '' AND
          cancellato_il BETWEEN ${cdcParam[FILTER_CANCELLATO_IL_MIN]} AND
          ${cdcParam[FILTER_CANCELLATO_IL_MAX]} ) )
      AND (1=${cdcParam[FLAG_CONTRATTO_EXISTS]} OR 
        (contratto IS NOT NULL AND LOWER(contratto) != '' ) )
      AND (1=${cdcParam[FLAG_CONTRATTO_NOT_EXISTS]} OR 
        (contratto IS NULL OR LOWER(contratto) = '' ) )
      AND (1=${cdcParam[FLAG_DIPARTIMENTO_EXISTS]} OR 
        (dipartimento IS NOT NULL AND LOWER(dipartimento) != '' ) )
      AND (1=${cdcParam[FLAG_DIPARTIMENTO_NOT_EXISTS]} OR 
        (dipartimento IS NULL OR LOWER(dipartimento) = '' ) )

      -- tabella sezioni
      AND (1=${cdcParam[FLAG_YEARS_IN]} OR 
        (cl IN ( ${cdcParam[FILTER_YEARS_IN]} ) ) )
      AND (1=${cdcParam[FLAG_ADDRESS_ARGO_IN]} OR 
        (addr_argo IN ( ${cdcParam[FILTER_ADDRESS_ARGO_IN]} ) ) )
      AND (1=${cdcParam[FLAG_ADDRESS_GSUITE_IN]} OR 
        (addr_gsuite IN ( ${cdcParam[FILTER_ADDRESS_GSUITE_IN]} ) ) )
      AND (1=${cdcParam[FLAG_CLASSES_IN]} OR 
        (sezione_gsuite IN ( ${cdcParam[FILTER_CLASSES_IN]} ) ) )
      AND (1=${cdcParam[FLAG_SUPERVISORS_EXISTS]} OR 
        (email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' ) )
      AND (1=${cdcParam[FLAG_SUPERVISORS_NOT_EXISTS]} OR 
        (email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' ) )
    ORDER BY ${cdcParam[ORDERING]} ASC;
  "
}

function query::queryAllCdc {
  local queryParam
  queryParam="$(query::defaultCdCParam)"
  
  # clona mappa
  local -A cdcParam=()
  eval "$queryParam"

  # modifica mappa
  cdcParam[FIELDS]="${1:-${cdcParam[FIELDS]}}"
  cdcParam[ORDERING]="${2:-${cdcParam[ORDERING]}}"

  # clona mappa modificata
  queryParam="$(declare -p "cdcParam")"

  local query
  query="$(query::getQueryCdc "$queryParam")"
  echo "$query"
}

function query::queryCdcByClass {
  local queryParam
  queryParam="$(query::defaultCdCParam)"

  # clona mappa
  local -A cdcParam=()
  eval "$queryParam"

  # modifica mappa
  cdcParam[FIELDS]="${1:-${cdcParam[FIELDS]}}"
  cdcParam[ORDERING]="${2:-${cdcParam[ORDERING]}}"

  cdcParam[FLAG_CLASSES_IN]="$FLAG_ON"
  cdcParam[FILTER_CLASSES_IN]=" '${3}' "

  # clona mappa modificata
  queryParam="$(declare -p "cdcParam")"

  local query
  query="$(query::getQueryCdc "$queryParam")"
  echo "$query"
}

function query::queryNewTeachers {
  local queryParam
  queryParam="$(query::defaultCdCParam)"

  # clona mappa
  local -A cdcParam=()
  eval "$queryParam"

  # modifica mappa
  cdcParam[FIELDS]="${1:-${cdcParam[FIELDS]}}"
  cdcParam[ORDERING]="${2:-${cdcParam[ORDERING]}}"

  cdcParam[FLAG_AGGIUNTO_IL]="$FLAG_ON"

  # clona mappa modificata
  queryParam="$(declare -p "cdcParam")"

  local query
  query="$(query::getQueryCdc "$queryParam")"
  echo "$query"
}


function query::queryCdcByBienni {
  local queryParam
  queryParam="$(query::defaultCdCParam)"

  # clona mappa
  local -A cdcParam=()
  eval "$queryParam"

  # modifica mappa
  cdcParam[FIELDS]="${1:-${cdcParam[FIELDS]}}"
  cdcParam[ORDERING]="${2:-${cdcParam[ORDERING]}}"

  cdcParam[FLAG_CLASSES_IN]="$FLAG_ON"
  cdcParam[FILTER_CLASSES_IN]=" '1, 2, 3, 4' "

  # clona mappa modificata
  queryParam="$(declare -p "cdcParam")"

  local query
  query="$(query::getQueryCdc "$queryParam")"
  echo "$query"
}


# Esempio di come chiamare la funzione
function execDebug {
  if log::level_is_active "DEBUG"; then
    local param
    param="$(query::defaultCdCParam)"
    echo "$param"
    
    local query
    query="$(query::queryAllCdc)"
    echo "$query"
  fi
}

execDebug