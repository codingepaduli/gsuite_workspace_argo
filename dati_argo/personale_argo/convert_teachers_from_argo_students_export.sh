#!/bin/bash

## Manage the importing of the file from Argo student - Menu Altro - Esporta dati - Docenti per GSuite - CSV (G-Suite)

source "./../../_environment.sh"
source "./../../_environment_working_tables.sh"

nomeFile="${1-docenti-G-Suite-2026}"

sqliteImportCsvAndExecuteQuery "SELECT 'docente', \"Last Name [Required]\" AS cognome, \"First Name [Required]\" AS nome, '' AS data_nascita, \"Password [Required]\" AS cod_fisc, '' AS telefono, '' AS altro_telefono, \"Recovery Phone [MUST BE IN THE E.164 FORMAT]\" AS cellulare, \"Recovery Email\" AS email_personale, '' AS email_gsuite, '' AS aggiunto_il, '' AS cancellato_il, '' AS contratto, '' AS dipartimento, '' AS note  FROM 'docenti-G-Suite-2026';" $nomeFile.csv > personale_argo_$nomeFile.csv

$LIBREOFFICE_CMD --convert-to xls --outdir "$PERSONALE_ARGO_IMPORT_DIR" "$PERSONALE_ARGO_IMPORT_DIR/personale_argo_$nomeFile.csv"

