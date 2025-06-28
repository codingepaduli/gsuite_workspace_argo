#!/bin/bash

# Environment variables

# You can override the environment variables in file _environment_custom.sh
# so each environment has its variables

# Cartella di lavoro
BASE_DIR="$MY_SVN_REPO_FOLDER/gsuite_workspace_argo"

# Comando sqlite3
SQLITE_CMD="$BASE_DIR/sqlite/sqlite3"

# Comando sqlite-utils
SQLITE_UTILS_CMD="sqlite-utils"

# Comando Google Admin Manager
GAM_CMD="$HOME/bin/gam/gam"

# Script to run
RUN_CMD_WITH_QUERY="./eseguiComandoConQuery.sh "

# Dominio DOT isis.it
DOMAIN="isis.it"

# Wordpress URL
WORDPRESS_URL="https://www.$DOMAIN/"

# Wordpress TOKEN
WORDPRESS_ACCESS_TOKEN=""

# Password teachers for gsuite and domain
PASSWORD_CLASSROOM=""

# Dry-Run mode
DRY_RUN="yes"

#########################################
# Tables' name (for version management) #
#########################################

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2025_06_22"
TABELLA_STUDENTI_SERALE="studenti_argo_2025_06_22_sirio" # temporanea

# Tabella sezioni per anno
TABELLA_SEZIONI="" # sezioni_2024_25

# Tabella gruppi
TABELLA_GRUPPI="" # gruppi_2024_25

# All classes and addresses enabled
SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt', 'm_sirio', 'et_sirio') "

# Tabella personale
TABELLA_PERSONALE="" # personale_argo_2025_01_22

# Tabella CdC
TABELLA_CDC_ARGO="" # Cdc_2025_01_13

# Tabella account GSuite studenti
TABELLA_STUDENTI_GSUITE="" # studenti_gsuite_20241201

# Tabella account GSuite docenti
TABELLA_DOCENTI_GSUITE="" # docenti_gsuite

# Tabella in cui importo le risposte di Google Moduli da CSV
TABELLA_GMODULI="" # GModuli

# Tabella dipartimenti
TABELLA_DIPARTIMENTI="" # gsuite_dipartimenti

# unità organizzative gSuite
GSUITE_OU_DOCENTI="DOCENTI"
GSUITE_OU_ATA="ATA"

# Tabella account Wordpress
TABELLA_UTENTI_WORDPRESS="" # wordpress_20250108

# La ricerca di utenti su wordpress è paginata, 
# ogni pagina contiene 100 account, quindi è 
# necessario specificare il numero di pagine da 
# sfogliare per ottenere più di 100 account
WORDPRESS_NUM_PAGES_TO_SEARCH="20"

# Wordpress permette di spostare la proprietà dei 
# contenuti (post, media, commenti) pubblicati 
# dall'account in corso di cancellazione su un
# account esistente, in modo da non perderli
# Questo è l'ID dell'utente sul quale spostare
# i contenuti degli account cancellati
WORDPRESS_USER_ID_FOR_DELETING="20"

# Ruoli Wordpress
WORDPRESS_ROLE_TEACHER="docente"
WORDPRESS_ROLE_ATA="personale_ata"
