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
  usersParam[FLAG_EMAIL_GSUITE_IN]="$FLAG_OFF"
  usersParam[FILTER_EMAIL_GSUITE_IN]=" '' "
  
  usersParam[FLAG_PWD_EXISTS]="$FLAG_OFF"
  usersParam[FLAG_PWDHASH_EXISTS]="$FLAG_OFF"

  usersParam[FLAG_ORG_UNIT_EXISTS]="$FLAG_OFF"
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

function query::utentiGSuiteTutti {
  local queryParam
  queryParam="$(query::defaultUsersParam)"

  # clona mappa
  local -A usersParam=()
  eval "${queryParam}"

  usersParam[FIELDS]="${1:-${usersParam[FIELDS]}}"

  # clona mappa modificata
  queryParam="$(declare -p "usersParam")"
  
  echo "
    SELECT ${usersParam[FIELDS]}
    FROM ${usersParam[TABLE]} sg
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
