#!/bin/bash

# To avoid changes to this file (already tracked in git)
#   git update-index --assume-unchanged _environment_working_tables.sh
#
# To commit changes to this file (already tracked in git)
#   git update-index --no-assume-unchanged _environment_working_tables.sh

# The name of the working tables are here to avoid
# to update each script every time

BASE_DIR="${MY_SVN_REPO_FOLDER}2/gsuite_workspace_argo"
GAM_CMD="$HOME/Sviluppo/GAM/gam7/gam"

# Data corrente (formato yyyy-mm-dd)
CURRENT_DATE="$(date --date='today' '+%Y-%m-%d')"

# Cartella di esportazione
EXPORT_DIR="$BASE_DIR/export"

# Sotto-cartella di esportazione con data
EXPORT_DIR_DATE="$EXPORT_DIR/export_$CURRENT_DATE"

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2025_06_22"
TABELLA_STUDENTI_SERALE="studenti_argo_2025_06_22_sirio" # temporanea

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# Tabella gruppi
TABELLA_GRUPPI="gruppi_2024_25"

SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt', 'm_sirio', 'et_sirio') "
# SQL_FILTRO_SEZIONI=" AND sz.sez_gsuite IN ('B_od') "

# Tabella personale versionata alla data indicata
TABELLA_PERSONALE="personale_argo_2025_01_22"

# Tabella CdC versionata alla data indicata
TABELLA_CDC_ARGO="Cdc_2025_01_13"

# Tabella in cui importo gli account GSuite relativi agli studenti
TABELLA_STUDENTI_GSUITE="studenti_gsuite_202412XX" # "utenti_gsuite_20241226"

# Tabella in cui importo gli account GSuite relativi ai docenti
TABELLA_DOCENTI_GSUITE="docenti_gsuite"

# Tabella in cui importo gli account Wordpress
TABELLA_UTENTI_WORDPRESS="wordpress_20250108"

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

# Tabella in cui importo le risposte di Google Moduli da CSV
TABELLA_GMODULI="GModuli"

TABELLA_DIPARTIMENTI="argo_dipartimenti"

# unità organizzative
GSUITE_OU_DOCENTI="DOCENTI"
GSUITE_OU_ATA="ATA"

WORDPRESS_ROLE_TEACHER="docente"
WORDPRESS_ROLE_ATA="personale_ata"
