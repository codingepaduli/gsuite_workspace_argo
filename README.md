# gsuite_workspace_argo

A collection of script to help import argo data into gsuite.

See the [ARCHITECTURE.md](https://matklad.github.io//2021/02/06/ARCHITECTURE.md.html) file for more information about how the repository folders are structured.

These script create a sqlite database and manage import and export with GAM.

## Prerequisite

### Software to install

Install [sqlite3](https://www.sqlite.org/index.html) in repo folder ``sqlite``;
Install [sqlite-utils](https://pypi.org/project/sqlite-utils/) on your system;
Install [Google Admin Manager](https://sites.google.com/view/gam--commands/home) on your system.

Note: GAM OAuth Token has validity of 6 months from the last access. After 6 months of inactivity, you will get the error "gam ERROR: ('invalid_grant: Bad Request')" or ``{"error": "invalid_grant", "error_description": "Bad Request"}``. In this case, you need to re-authorize the Admin Access, running another time the command:

```bash
gam oauth create
```

### Check sqlite3 installation

```bash
./sqlite3 --version
```

```plaintext
3.43.2 2023-10-10
```

### Check sqlite-utils installation

```bash
sqlite-utils --version
```

```plaintext
sqlite-utils, version 3.35.1
```

### Check Google Admin Manager installation

```bash
gam version checkrc
```

```plaintext
GAM 6.58 - https://jaylee.us/gam - pyinstaller
Jay Lee <jay0lee@gmail.com>
Python 3.11.3 64-bit final
google-api-python-client 2.86.0
Linux Debian 11 Bullseye x86_64
Version Check:
 Current: 6.58
 Latest: 6.58
```

```bash
gam info user
```

```plaintext
User: my_mail@mail
First Name: First
Last Name: Last
Full Name: First Last
Languages: it+
Is a Super Admin: True
Is Delegated Admin: False
  ...
```

### Set the environment variables

Set the environment variables in file [_environment.sh](environment.sh):

```bash
BASE_DIR="repository_path"           # Working folder
SQLITE_CMD="$BASE_DIR/sqlite/sqlite3" # sqlite3 command
SQLITE_UTILS_CMD="sqlite-utils"       # sqlite-utils command
GAM_CMD="$HOME/bin/gam/gam"           # Google Admin Manager command
DOMAIN="isis.it"                      # Dominio isis.it
WORDPRESS_URL="https://www.$DOMAIN/"  # Dominio wordpress
```

### Create the database

```bash
sqlite3 studenti.db
```

## Import students script

Prepare Excel file:

- Check first row fields to match the CREATE TABLE command in the script;
- Add the column "email_argo";
- Save the Excel as CSV.

Prepare CSV file:

- Transform the first row in lowercase;
- Replace all `` ,`` occurrences with ``,``;
- Delete all empty rows matching ``,,,,,,,,,``.

Set the script variables:

```bash
TABELLA_STUDENTI="studenti_argo_2024_09_06"
FILE_CSV_STUDENTI="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI.csv"
```

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
