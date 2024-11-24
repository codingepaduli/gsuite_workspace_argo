#!/bin/bash

# To avoid changes to this file (already tracked in git)
#   git update-index --assume-unchanged _environment.sh
#
# To commit changes to this file (already tracked in git)
#   git update-index --no-assume-unchanged _environment.sh

# The name of the working tables are here to avoid
# to update each script every time

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_11_18"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

SQL_FILTRO_ANNI=" AND sz.cl IN (1, 2, 3, 4, 5) " 
SQL_FILTRO_SEZIONI=" AND sz.addr_argo IN ('tr', 'en', 'in', 'm', 'od', 'idd', 'et', 'tlt', 'm_sirio', 'et_sirio') " 
