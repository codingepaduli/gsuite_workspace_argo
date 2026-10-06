#!/bin/bash

source "./_environment.sh"
source "./_environment_working_tables.sh"
source "./_maps.sh"

FLAG_ON=0
FLAG_OFF=1

function query::dropTableIfExists() {
  local TABLE="${1:-${TABELLA_UTENTI_GSUITE}}"
  echo "
    DROP TABLE IF EXISTS '$TABLE';
  "
}

function query::createTableIfNotExists() {
  local TABLE="${1:-${TABELLA_UTENTI_GSUITE}}"
  echo "
    CREATE TABLE IF NOT EXISTS '$TABLE' ( 
      nome TEXT,
      cognome TEXT,
      email_gsuite TEXT,
      pwd TEXT,
      pwdHash TEXT,
      org_unit TEXT,
      priMail TEXT,
      stato_utente TEXT,
      ultimo_login TEXT,
      recoveryEmail TEXT,
      homeEmail TEXT,
      workEmail TEXT,
      recoveryPhone TEXT,
      workPhone TEXT,
      homePhone TEXT,
      mobilePhone TEXT,
      workAddr TEXT,
      homeAddr TEXT,
      id TEXT,
      type TEXT,
      title TEXT,
      manager TEXT,
      department TEXT,
      cost TEXT,
      enroll TEXT,
      enforce TEXT,
      buildingId TEXT,
      floorName TEXT,
      floorSection TEXT,
      spazio_email TEXT,
      spazio_gdrive TEXT,
      spazio_foto TEXT,
      spazio_limite TEXT,
      spazio_storage TEXT,
      changePwdNextLogin TEXT,
      newStatus TEXT,
      license TEXT,
      newLicense TEXT,
      protection TEXT,
      selezionato_il TEXT
    ) STRICT;
  "
}

function query::defaultUsersParam() {
  local -A usersParam=()
  usersParam[FIELDS]=" nome, cognome, email_gsuite, pwd, pwdHash, org_unit, priMail, stato_utente, ultimo_login, recoveryEmail, homeEmail, workEmail, recoveryPhone, workPhone, homePhone, mobilePhone, workAddr, homeAddr, id, type, title, manager, department, cost, enroll, enforce, buildingId, floorName, floorSection, spazio_email, spazio_gdrive, spazio_foto, spazio_limite, spazio_storage, changePwdNextLogin, newStatus, license, newLicense, protection, selezionato_il"
  usersParam[ORDERING]=" LOWER(email_gsuite) "
  usersParam[TABLE]=" $TABELLA_UTENTI_GSUITE "

  usersParam[FLAG_NOME_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_COGNOME_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_EMAIL_GSUITE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_EMAIL_GSUITE_IN]="$FLAG_OFF"
  usersParam[FILTER_EMAIL_GSUITE_IN]=" '' "

  usersParam[FLAG_EMAIL_GSUITE_PREFIX_IN]="$FLAG_OFF"
  usersParam[FILTER_EMAIL_GSUITE_PREFIX_IN]=" '' "
  
  usersParam[FLAG_PWD_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_PWDHASH_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_ORG_UNIT_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_ORG_UNIT_IN]="$FLAG_OFF"
  usersParam[FILTER_ORG_UNIT_IN]=" '' "

  usersParam[FLAG_PRIMAIL_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_STATO_UTENTE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_ULTIMO_LOGIN_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_RECOVERYEMAIL_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_HOMEEMAIL_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_WORKEMAIL_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_RECOVERYPHONE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_WORKPHONE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_HOMEPHONE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_MOBILEPHONE_EXISTS]="$FLAG_OFF"
  
  usersParam[FLAG_WORKADDR_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_HOMEADDR_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_ID_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_TYPE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_TITLE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_MANAGER_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_DEPARTMENT_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_COST_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_ENROLL_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_ENFORCE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_BUILDINGID_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_FLOORNAME_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_FLOORSECTION_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SPAZIO_EMAIL_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SPAZIO_GDRIVE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SPAZIO_FOTO_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SPAZIO_LIMITE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SPAZIO_STORAGE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_CHANGEPWDNEXTLOGIN_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_NEWSTATUS_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_LICENSE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_NEWLICENSE_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_PROTECTION_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_SELEZIONATO_IL]="$FLAG_OFF"

  declare -p "usersParam"
}

function query::defaultUtentiGSuiteTutti {
  local queryParam
  queryParam="${1}"

  # clona mappa
  local -A usersParam=()
  eval "${queryParam}"

  echo "
    SELECT ${usersParam[FIELDS]}
    FROM ${usersParam[TABLE]} sg
    WHERE 1=1
      AND (1=${usersParam[FLAG_NOME_EXISTS]} OR 
        ( nome IS NOT NULL AND LOWER(nome) != '' ) )
      AND (1=${usersParam[FLAG_COGNOME_EXISTS]} OR 
        ( cognome IS NOT NULL AND LOWER(cognome) != '' ) )

      AND (1=${usersParam[FLAG_EMAIL_GSUITE_EXISTS]} OR 
        ( email_gsuite IS NOT NULL AND LOWER(email_gsuite) != '' ) )
      AND (1=${usersParam[FLAG_EMAIL_GSUITE_NOT_EXISTS]} OR 
        ( email_gsuite IS NULL OR LOWER(email_gsuite) = '' ) )
      AND (1=${usersParam[FLAG_EMAIL_GSUITE_IN]} OR 
        LOWER(email_gsuite) IN ( ${usersParam[FILTER_EMAIL_GSUITE_IN]} ) )
      
      AND (1=${usersParam[FLAG_EMAIL_GSUITE_PREFIX_IN]} OR 
        LOWER(SUBSTR(email_gsuite, 1, MIN(2, LENGTH(email_gsuite)))) 
          IN ( ${usersParam[FILTER_EMAIL_GSUITE_PREFIX_IN]} ))
      
      AND (1=${usersParam[FLAG_PWD_EXISTS]} OR 
        ( pwd IS NOT NULL AND LOWER(pwd) != '' ) )
      AND (1=${usersParam[FLAG_PWDHASH_EXISTS]} OR 
        ( pwdHash IS NOT NULL AND LOWER(pwdHash) != '' ) )
      AND (1=${usersParam[FLAG_ORG_UNIT_EXISTS]} OR 
        ( org_unit IS NOT NULL AND LOWER(org_unit) != '' ) )
      AND (1=${usersParam[FLAG_ORG_UNIT_IN]} OR 
        LOWER(email_gsuite) IN ( ${usersParam[FILTER_ORG_UNIT_IN]} ) )
      
      AND (1=${usersParam[FLAG_PRIMAIL_EXISTS]} OR 
        ( priMail IS NOT NULL AND LOWER(priMail) != '' ) )
      
      AND (1=${usersParam[FLAG_STATO_UTENTE_EXISTS]} OR 
        ( stato_utente IS NOT NULL AND LOWER(stato_utente) != '' ) )
      AND (1=${usersParam[FLAG_ULTIMO_LOGIN_EXISTS]} OR 
        ( ultimo_login IS NOT NULL AND LOWER(ultimo_login) != '' ) )
      AND (1=${usersParam[FLAG_RECOVERYEMAIL_EXISTS]} OR 
        ( recoveryEmail IS NOT NULL AND LOWER(recoveryEmail) != '' ) )
      AND (1=${usersParam[FLAG_HOMEEMAIL_EXISTS]} OR 
        ( homeEmail IS NOT NULL AND LOWER(homeEmail) != '' ) )
      
      AND (1=${usersParam[FLAG_WORKEMAIL_EXISTS]} OR 
        ( workEmail IS NOT NULL AND LOWER(workEmail) != '' ) )
      AND (1=${usersParam[FLAG_RECOVERYPHONE_EXISTS]} OR 
        ( recoveryPhone IS NOT NULL AND LOWER(recoveryPhone) != '' ) )
      AND (1=${usersParam[FLAG_WORKPHONE_EXISTS]} OR 
        ( workPhone IS NOT NULL AND LOWER(workPhone) != '' ) )
      AND (1=${usersParam[FLAG_HOMEPHONE_EXISTS]} OR 
        ( homePhone IS NOT NULL AND LOWER(homePhone) != '' ) )
      AND (1=${usersParam[FLAG_MOBILEPHONE_EXISTS]} OR 
        ( mobilePhone IS NOT NULL AND LOWER(mobilePhone) != '' ) )
      AND (1=${usersParam[FLAG_WORKADDR_EXISTS]} OR 
        ( workAddr IS NOT NULL AND LOWER(workAddr) != '' ) )
      AND (1=${usersParam[FLAG_HOMEADDR_EXISTS]} OR 
        ( homeAddr IS NOT NULL AND LOWER(homeAddr) != '' ) )
      
      AND (1=${usersParam[FLAG_ID_EXISTS]} OR 
        ( id IS NOT NULL AND LOWER(id) != '' ) )
      AND (1=${usersParam[FLAG_TYPE_EXISTS]} OR 
        ( type IS NOT NULL AND LOWER(type) != '' ) )
      AND (1=${usersParam[FLAG_TITLE_EXISTS]} OR 
        ( title IS NOT NULL AND LOWER(title) != '' ) )
      AND (1=${usersParam[FLAG_MANAGER_EXISTS]} OR 
        ( manager IS NOT NULL AND LOWER(manager) != '' ) )
      AND (1=${usersParam[FLAG_DEPARTMENT_EXISTS]} OR 
        ( department IS NOT NULL AND LOWER(department) != '' ) )
      AND (1=${usersParam[FLAG_COST_EXISTS]} OR 
        ( cost IS NOT NULL AND LOWER(cost) != '' ) )
      AND (1=${usersParam[FLAG_ENROLL_EXISTS]} OR 
        ( enroll IS NOT NULL AND LOWER(enroll) != '' ) )
      AND (1=${usersParam[FLAG_ENFORCE_EXISTS]} OR 
        ( enforce IS NOT NULL AND LOWER(enforce) != '' ) )
      
      AND (1=${usersParam[FLAG_BUILDINGID_EXISTS]} OR 
        ( buildingId IS NOT NULL AND LOWER(buildingId) != '' ) )
      AND (1=${usersParam[FLAG_FLOORNAME_EXISTS]} OR 
        ( floorName IS NOT NULL AND LOWER(floorName) != '' ) )
      AND (1=${usersParam[FLAG_FLOORSECTION_EXISTS]} OR 
        ( floorSection IS NOT NULL AND LOWER(floorSection) != '' ) )
      
      AND (1=${usersParam[FLAG_SPAZIO_EMAIL_EXISTS]} OR 
        ( spazio_email IS NOT NULL AND LOWER(spazio_email) != '' ) )
      AND (1=${usersParam[FLAG_SPAZIO_GDRIVE_EXISTS]} OR 
        ( spazio_gdrive IS NOT NULL AND LOWER(spazio_gdrive) != '' ) )
      AND (1=${usersParam[FLAG_SPAZIO_FOTO_EXISTS]} OR 
        ( spazio_foto IS NOT NULL AND LOWER(spazio_foto) != '' ) )
      AND (1=${usersParam[FLAG_SPAZIO_LIMITE_EXISTS]} OR 
        ( spazio_limite IS NOT NULL AND LOWER(spazio_limite) != '' ) )
      AND (1=${usersParam[FLAG_SPAZIO_STORAGE_EXISTS]}    OR 
        ( spazio_storage IS NOT NULL AND LOWER(spazio_storage) != '' ) )
      
      AND (1=${usersParam[FLAG_CHANGEPWDNEXTLOGIN_EXISTS]} OR 
        ( changePwdNextLogin IS NOT NULL AND LOWER(changePwdNextLogin) != '' ) )
      AND (1=${usersParam[FLAG_NEWSTATUS_EXISTS]} OR 
        ( newStatus IS NOT NULL AND LOWER(newStatus) != '' ) )
      AND (1=${usersParam[FLAG_LICENSE_EXISTS]} OR 
        ( license IS NOT NULL AND LOWER(license) != '' ) )
      AND (1=${usersParam[FLAG_NEWLICENSE_EXISTS]} OR 
        ( newLicense IS NOT NULL AND LOWER(newLicense) != '' ) )
      AND (1=${usersParam[FLAG_PROTECTION_EXISTS]} OR 
        ( protection IS NOT NULL AND LOWER(protection) != '' ) )
      AND (1=${usersParam[FLAG_SELEZIONATO_IL]} OR 
        ( selezionato_il IS NOT NULL AND LOWER(selezionato_il) != '' ) )

    ORDER BY ${usersParam[ORDERING]} ASC
  "
}

function query::normalizeFields() {
  local TABLE="${1:-${TABELLA_UTENTI_GSUITE}}"
  
  echo "
    UPDATE $TABLE 
    SET nome = TRIM(UPPER(nome)),
      cognome = TRIM(UPPER(cognome)),
      email_gsuite = TRIM(LOWER(email_gsuite)),
      org_unit = TRIM(UPPER(org_unit)),
      stato_utente = TRIM(UPPER(stato_utente)),
      ultimo_login = TRIM(UPPER(ultimo_login)),
      spazio_email = CAST(spazio_email AS REAL) * 1000,
      spazio_gdrive = CAST(spazio_gdrive AS REAL) * 1000,
      spazio_storage = CAST(spazio_storage AS REAL) * 1000,
      selezionato_il = '';
  "
}

function query::normalizeLastLogin() {
  local TABLE="${1:-${TABELLA_UTENTI_GSUITE}}"
  
  echo "
    UPDATE $TABLE 
    SET ultimo_login = substr(ultimo_login, 1, 4) || '-' 
      || substr(ultimo_login, 6, 2) || '-' 
      || substr(ultimo_login, 9, 2)
    WHERE ultimo_login is NOT NULL 
      AND TRIM(UPPER(ultimo_login)) != UPPER('Never logged in');
  "
}


function query::normalizeLastLoginNeverLoggedIn() {
  local TABLE="${1:-${TABELLA_UTENTI_GSUITE}}"
  
  echo "
    UPDATE $TABLE 
    SET ultimo_login = '2000-01-01'
    WHERE ultimo_login is NOT NULL 
      AND TRIM(UPPER(ultimo_login)) = UPPER('Never logged in');
  "
}

function query::utentiGSuiteTutti {
  local queryParam
  queryParam="$(query::defaultUsersParam)"

  # clona mappa
  local -A usersParam=()
  eval "${queryParam}"

  usersParam[FIELDS]="${1:-${usersParam[FIELDS]}}"
  usersParam[ORDERING]="${2:-${usersParam[ORDERING]}}"

  # clona mappa modificata
  queryParam="$(declare -p "usersParam")"
  
  local query
  query="$(query::getQueryStudenti "$queryParam")"
  echo "$query"
}