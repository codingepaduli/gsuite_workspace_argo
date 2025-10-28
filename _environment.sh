#!/bin/bash

# Environment variables

# You can override the environment variables in file _environment_custom.sh
# so each environment has its variables

#########################################
# Path of command line executables      #
#########################################

MY_SVN_REPO_FOLDER="$HOME/Sviluppo/SVN2"

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

#########################################
#           Config data                 #
#########################################

# Dominio DOT isis.it
DOMAIN="isis.it"

# Wordpress URL
WORDPRESS_URL="https://www.$DOMAIN/"

# Wordpress TOKEN
WORDPRESS_ACCESS_TOKEN=""

# Password for teachers and employees
PASSWORD_CLASSROOM=""

# Dry-Run mode # leave DRY_RUN empty for applying changes
DRY_RUN="yes"

# Show Dry-Run mode YES/NO in menu
dryRunFlag=$( [ -n "$DRY_RUN" ] && echo "YES" || echo "NO" )

# Log config
LOG_OUTPUT=("file" "console")
LOG_LEVEL="CONFIG"
LOG_FILE="debug.log"

# Sovrascrive la data corrente (formato yyyy-mm-dd)
# e il path della cartella di esportazione
CURRENT_DATE="$(date --date='today' '+%Y-%m-%d')"

#########################################
#           Export folders              #
#########################################

# Cartella di esportazione
EXPORT_DIR="$BASE_DIR/export"

# Sotto-cartella di esportazione con data
EXPORT_DIR_DATE="$EXPORT_DIR/export_$CURRENT_DATE"

####################################
# Tables' name related to students #
####################################

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="" # studenti_argo_2025_06_22
TABELLA_STUDENTI_SERALE="" # studenti_argo_2025_06_22_sirio

# Usata nella gestione classi per rilevare le differenze
TABELLA_STUDENTI_PRECEDENTE="" # studenti_argo_2025_06_01

# Per operazioni in un determinato periodo
PERIODO_STUDENTI_DA='2025-10-20'
PERIODO_STUDENTI_A='2025-10-20'

####################################
# Tables' name related to sections #
####################################

# Tabella sezioni per anno
TABELLA_SEZIONI="" # sezioni_2024_25

# All classes and addresses enabled
SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI_DIURNO=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'mDD', 'od', 'idd', 'et', 'tlt') "
SQL_FILTRO_SEZIONI_SERALE=" AND sz.addr_argo IN ('m_sirio', 'et_sirio', 'me_sirio') "
SQL_FILTRO_SEZIONI=" $SQL_FILTRO_SEZIONI_DIURNO $SQL_FILTRO_SEZIONI_SERALE "

###########################################
# Tables' name related to students' group #
###########################################

# Tabella in cui importo gli account GSuite relativi agli studenti
TABELLA_STUDENTI_GSUITE="" # studenti_gsuite_2025_08_21

# Tabella gruppi
TABELLA_GRUPPI="" # gruppi_2024_25

# Gruppi GSuite addizionali (non in sezioni)
GSUITE_ADDITIONAL_GROUPS=("")

#####################################
# Tables' name related to employees #
#####################################

# Tabella personale versionata alla data indicata
TABELLA_PERSONALE="" # personale_argo_2025_10_20

# Per operazioni in un determinato periodo
PERIODO_PERSONALE_DA='2025-10-20'
PERIODO_PERSONALE_A='2025-10-20'

# Tabella personale precedente per confronto
TABELLA_PERSONALE_PRECEDENTE="" # personale_argo_2025_09_23

#####################################
# Tables' name for gSuite users     #
#####################################

TABELLA_UTENTI_GSUITE='' # tutti_2025_10_20

# unità organizzative gSuite
GSUITE_OU_DOCENTI="DOCENTI"
GSUITE_OU_ATA="ATA"

#####################################
# Tables' name for CdC              #
#####################################

# Tabella CdC versionata alla data indicata
TABELLA_CDC_ARGO="" # Cdc_2025_01_13

#####################################
# Tables' name for Moduli           #
#####################################

# Tabella in cui importo le risposte di Google Moduli da CSV
TABELLA_GMODULI="" # GModuli

#####################################
# Tables' name for wordpress users  #
#####################################

# Tabella in cui importo gli account Wordpress
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

