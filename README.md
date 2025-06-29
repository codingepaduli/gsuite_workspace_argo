# gsuite_workspace_argo

A collection of script to help import, export and manage Argo and GSuite data.

See the [ARCHITECTURE.md](ARCHITECTURE.md) file for more information about how the repository folders are structured.

See the [UserGuide.md](UserGuide.md) file for more information about how to configure and run this app.

## Prerequisite

Install [sqlite3](https://www.sqlite.org/index.html), [sqlite-utils](https://pypi.org/project/sqlite-utils/) and [Google Admin Manager](https://github.com/GAM-team/GAM/wiki) on your system.

Note: GAM OAuth Token has validity of 6 months from the last access. After 6 months of inactivity, you will get the error "gam ERROR: ('invalid_grant: Bad Request')" or ``{"error": "invalid_grant", "error_description": "Bad Request"}``. In this case, you need to re-authorize the Admin Access, running another time the command:

Check you proper install the tools.

Customize the values of your environment variables in the file [_environment_working_tables.sh](_environment_working_tables.sh), it's not tracked by git, pay attention to NOT commit it with your secrets.

Import the data from the CSV file and prepare them. See the guide form more information on each import.

## Import section and classes script

Get the section from the students import:

```bash
./sqlite/sqlite3 -header -csv studenti.db "
SELECT cl, letter, addr_argo, sez as sez_argo,
CASE 
  WHEN INSTR(sez, 'in') > 0 THEN REPLACE(sez_gs, 'in', 'inf')
  WHEN INSTR(sez, 'm') > 0 THEN REPLACE(sez_gs, 'm', 'mec')
  WHEN INSTR(sez, 'tr') > 0 THEN REPLACE(sez_gs, 'tr', 'aer')
  WHEN INSTR(sez, 'tlt') > 0 THEN REPLACE(sez_gs, 'tlt', 'tlc')
  ELSE sez_gs
END 
as sez_gsuite, cl || (
CASE 
  WHEN INSTR(sez, 'in') > 0 THEN REPLACE(sez_gs, 'in', 'inf')
  WHEN INSTR(sez, 'm') > 0 THEN REPLACE(sez_gs, 'm', 'mec')
  WHEN INSTR(sez, 'tr') > 0 THEN REPLACE(sez_gs, 'tr', 'aer')
  WHEN INSTR(sez, 'tlt') > 0 THEN REPLACE(sez_gs, 'tlt', 'tlc')
  ELSE sez_gs
END
) as sezione_gsuite
FROM (
  SELECT DISTINCT cl, sez, SUBSTR(sez, 1, 1) as letter, SUBSTR(sez, 2) as addr_argo, SUBSTR(sez, 1, 1) || '_' || SUBSTR(sez, 2) as sez_gs 
  FROM studenti_argo_2024_09_06 
  ORDER BY cl,sez
)
ORDER BY addr_argo, cl, letter" > sezioni_2024_25.csv;
```

In case of problems, try a minimal script:

```bash
./sqlite/sqlite3 -header -csv studenti.db "SELECT DISTINCT cl, sez, '' as sezioni_gsuite from studenti_argo_2024_09_06 ORDER BY cl,sez; " > sezioni_2024_25.csv
```

Move the section file to the dati_argo folder and set the script variables:

```bash
# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_09_06"
TABELLA_SEZIONI="sezioni_2024_25" 
FILE_CSV_SEZIONI="$BASE_DIR/dati_argo/$TABELLA_SEZIONI.csv"
```
