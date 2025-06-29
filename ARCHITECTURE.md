# Architecture

See [ARCHITECTURE](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html) for the purpose of this file.

## Tools

The tools used to manage the data are:

- [sqlite3](https://www.sqlite.org/index.html), store all data about Argo, gSuite and WordPress;
- [sqlite-utils](https://pypi.org/project/sqlite-utils/), import CSV files (will be removed, work in progress...);
- [Google Admin Manager](https://github.com/GAM-team/GAM/wiki), used to sync data between the sqlite database (Argo data) and GSuite;

These tools can be installed in a repo sub-folder (remember to add them to .gitignore) or everywhere in your system, just set the path of each tool:

```bash
# this repo folder
BASE_DIR="$HOME/gsuite_workspace_argo"

# in a sub-folder
SQLITE_CMD="$BASE_DIR/sqlite/sqlite3"

# in your system
GAM_CMD="$HOME/Sviluppo/GAM/gam7/gam"

# available in the $PATH
SQLITE_UTILS_CMD="sqlite-utils"
```

Remember to configure the tool's variable in order to execute it properly:

```bash
DOMAIN="isis.it"
WORDPRESS_ACCESS_TOKEN=""
 ...
```

## Config and Utils files

These configuration files are imported in almost all script (see bash ``source`` command):

- [_environment.sh](_environment.sh) file: Sets the default value of the environment variables used in the scripts;
- [_environment_working_tables.sh](_environment_working_tables.sh) file: Sets the environment variables for the tables used in the scripts. **This file should not be tracked in git**, remember to add them to ``.gitignore`` file;
- [_maps.sh](_maps.sh) file: Adds the Map data type used in Bash script;

## Script (user interface)

The script [eseguiComandoConQuery.sh](eseguiComandoConQuery.sh) is the main part of the app. It execute a tool (sqlite, gam, ...), performing a single operation on data, like a query or a gSuite account creation; This script is executed by almost all other script in order to run the operation on a bigger collection of data.

Each script ``gestisciXXX.sh`` manage a specific aspect of the data, as **students' data**, as **section and classes data**, as **employees' data**. The script's name **./gestisci``XXX``.sh** identifies the aspect ``XXX`` to manage, so for students' data you have the script [gestisciStudenti.sh](gestisciStudenti.sh), for section and classes data you have the script [gestisciSezioni.sh](gestisciSezioni.sh), for employees' data you have the script [gestisciPersonale.sh](gestisciPersonale.sh), and so on ...

## Import folders and files 

The import folder for Argo is ``dati_argo``, with three subfolders:

- ``dati_argo/studenti_argo`` folder contains students' data CSV file to import;
- ``dati_argo/personale_argo`` folder contains employees' data CSV file to import;
- ``dati_argo/cdc`` folder contains CdC data CSV file to import;

The CSV filename will be the same of the sqlite database table name, so you will have:

- the table name ``studenti_argo_YYYY_MM_DD`` when importing the CSV file ``dati_argo/studenti_argo/studenti_argo_YYYY_MM_DD.csv`` file;
- the table name ``sezioni_YYYY_YY`` when importing the CSV file ``dati_argo/studenti_argo/sezioni_YYYY_YY.csv`` file.

The CSV filename has to be set as environment variable.

## Export folders and files 

Each export operation will save the CSV files exported in the export folder, set as environment variable:

```bash
# Data corrente (formato yyyy-mm-dd)
CURRENT_DATE="$(date --date='today' '+%Y-%m-%d')"

# Cartella di esportazione
EXPORT_DIR="$BASE_DIR/export"

# Sotto-cartella di esportazione con data
EXPORT_DIR_DATE="$EXPORT_DIR/export_$CURRENT_DATE"
```

Customize them as your needs.
