#!/bin/bash

# Environment variables

# Cartella di lavoro
BASE_DIR="$MY_SVN_REPO_FOLDER/gsuite_workspace_argo/"

# Comando sqlite3
SQLITE_CMD="$BASE_DIR/sqlite/sqlite3"

# Comando sqlite-utils
SQLITE_UTILS_CMD="sqlite-utils"

# Comando Google Admin Manager
GAM_CMD="$HOME/bin/gam/gam"

# Dominio DOT isis.it
DOMAIN="isis.it"

# Wordpress URL
WORDPRESS_URL="https://www.$DOMAIN/"

# Wordpress TOKEN
WORDPRESS_ACCESS_TOKEN=""

# Password teachers for gsuite and domain
PASSWORD_CLASSROOM=""

# Data corrente (formato yyyy-mm-dd)
CURRENT_DATE="$(date --date='today' '+%Y-%m-%d')"

# Cartella di esportazione
EXPORT_DIR="$BASE_DIR/export"

# Sotto-cartella di esportazione con data
EXPORT_DIR_DATE="$EXPORT_DIR/export_$CURRENT_DATE"

