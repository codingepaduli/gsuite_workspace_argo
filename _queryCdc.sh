#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::defaultCdCParam() {
  local -A cdcParam=()
  cdcParam[FIELDS]=" * "
  cdcParam[ORDERING]=" sezione_gsuite, d.cognome, d.nome "

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
  cdcParam[FLAG_YEARS]="$FLAG_ON"
  cdcParam[FILTER_YEARS]="$SQL_FILTRO_ANNI"
  cdcParam[FLAG_ADDRESS_ARGO]="$FLAG_ON"
  cdcParam[FILTER_ADDRESS_ARGO]="$SQL_FILTRO_SEZIONI"
  cdcParam[FLAG_ADDRESS_GSUITE]="$FLAG_OFF"
  cdcParam[FILTER_ADDRESS_GSUITE]=" '' "
  cdcParam[FLAG_CLASSES]="$FLAG_OFF"
  cdcParam[FILTER_CLASSES]=" '' "
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
    SELECT ${cdcParam[FIELDS]}
    FROM $TABELLA_CDC
      INNER JOIN $TABELLA_SEZIONI sz
        ON cdc.classi = (sz.cl || sz.sez_argo)
      INNER JOIN $TABELLA_PERSONALE d
        ON UPPER(d.cognome || ' ' || d.nome) = UPPER(cdc.docente) 
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
      AND (1=${cdcParam[FLAG_YEARS]} OR 
        (anno IN ( ${cdcParam[FILTER_YEARS]} ) ) )
      AND (1=${cdcParam[FLAG_ADDRESS_ARGO]} OR 
        (addr_argo IN ( ${cdcParam[FILTER_ADDRESS_ARGO]} ) ) )
      AND (1=${cdcParam[FLAG_ADDRESS_GSUITE]} OR 
        (addr_gsuite IN ( ${cdcParam[FILTER_ADDRESS_GSUITE]} ) ) )
      AND (1=${cdcParam[FLAG_CLASSES]} OR 
        (sezione_gsuite IN ( ${cdcParam[FILTER_CLASSES]} ) ) )
      AND (1=${cdcParam[FLAG_SUPERVISORS_EXISTS]} OR 
        (email_coordinatore IS NOT NULL AND LOWER( email_coordinatore) != '' ) )
      AND (1=${cdcParam[FLAG_SUPERVISORS_NOT_EXISTS]} OR 
        (email_coordinatore IS NULL OR LOWER(email_coordinatore) = '' ) )
    ORDER BY ${cdcParam[ORDERING]} ASC;
  "
}
