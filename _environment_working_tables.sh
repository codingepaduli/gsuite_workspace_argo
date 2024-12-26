#!/bin/bash

# To avoid changes to this file (already tracked in git)
#   git update-index --assume-unchanged _environment_working_tables.sh
#
# To commit changes to this file (already tracked in git)
#   git update-index --no-assume-unchanged _environment_working_tables.sh

# The name of the working tables are here to avoid
# to update each script every time

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_12_19"
TABELLA_STUDENTI_SERALE="studenti_argo_2024_10_22_sirio"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# Tabella gruppi
TABELLA_GRUPPI="gruppi_2024_25"

SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt', 'm_sirio', 'et_sirio') " 

# Tabella personale versionata alla data indicata
TABELLA_PERSONALE="personale_argo_2024_12_17"

# Tabella in cui importo gli account GSuite relativi agli studenti
TABELLA_STUDENTI_GSUITE="studenti_gsuite"

# Tabella in cui importo gli account GSuite relativi ai docenti
TABELLA_DOCENTI_GSUITE="docenti_gsuite"
