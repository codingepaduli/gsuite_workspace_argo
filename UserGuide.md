# User Guide for MyApp

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Installation](#installation)
4. [Troubleshooting](#troubleshooting)
5. [Students management](#students-management)
6. [GSuite user management](#gsuite-user-management)
7. [CdC Management](#cdc-management)

## Introduction

Welcome to **gSuite Workspace Argo**! This collection of script is designed to help you manage your tasks of importing, exporting and manage data between Argo and GSuite data. This user guide will walk you through the installation process, key features, and troubleshooting tips.

## Features

- **Export data from Argo**: Export data from Argo;
- **Import/Export data from gSuite**: Import/Export data from gsuite;
- **Import/Export data from wordpress**: Import/Export data from Wordpress;
- **Sync data on local sqlite database**: the sqlite database will be the source;
- **Students Management**: Create, edit, and delete student's data with the script ``gestisciStudenti.sh``;
- **Section Management**: Create, edit, and delete section's data with the script ``gestisciStudenti.sh``;
- **Employees Management**: Create, edit, and delete employees's data with the script ``gestisciPersonale.sh``;

## Installation

You don't need to install **gSuite Workspace Argo**, just clone this repo, install the needed applications and set the environment variables.

### System Requirements

- Linux and Bash shell;
- [sqlite3](https://www.sqlite.org/index.html);
- [sqlite-utils](https://pypi.org/project/sqlite-utils/);
- [Google Admin Manager](https://github.com/GAM-team/GAM/wiki).

#### Check sqlite3 installation

```bash
./sqlite3 --version
```

```plaintext
3.43.2 2023-10-10
```

#### Check sqlite-utils installation

```bash
sqlite-utils --version
```

```plaintext
sqlite-utils, version 3.35.1
```

#### Check Google Admin Manager installation

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

The file [_environment.sh](environment.sh) contains the default value of the environment variables. You need custom values. Create the file [_environment_working_tables.sh](_environment_working_tables.sh) and customize only the needed values, for example

```bash
BASE_DIR="/home/my/gsuite-workspace"                        # Working folder
SQLITE_CMD="$BASE_DIR/sqlite/sqlite3"                       # sqlite3 executable
DOMAIN="isis.it"                                            # My google domain name
TABELLA_STUDENTI="studenti_argo_2025_06_22"                 # student's table
TABELLA_STUDENTI_SERALE="studenti_argo_2025_06_22_sirio"    # student's table for evening courses
```

### Create the database

You just need to create the database with:

```bash
sqlite3 studenti.db
```

Check the file ``studenti.db`` will be created, or execute a ``CREATE TABLE`` command in order the file will be created.

## Students management

### Export student's data

Student's data are exported from Argo:

![portaleArgo.png](/dati_argo/studenti_argo/portaleArgo.png)

Run a custom export:

![argoStudenti-EsportaPersonalizzata.png](/dati_argo/studenti_argo/argoStudenti-EsportaPersonalizzata.png)

![argoStudenti-EsportaPersonalizzata-apri.png](/dati_argo/studenti_argo/argoStudenti-EsportaPersonalizzata-apri.png)

![argoStudenti-EsportazioneDati-apriElenco.png](/dati_argo/studenti_argo/argoStudenti-EsportazioneDati-apriElenco.png)

![argoStudenti-EsportazioneDati-avvia.png](/dati_argo/studenti_argo/argoStudenti-EsportazioneDati-avvia.png)

Fields to export and required in the CSV are:

- COGNOME
- NOME
- COD_FISC
- CLASSE
- SEZIONE
- E_MAIL
- EMAIL_PA
- EMAIL_MA
- EMAIL_GEN
- MATRICOLA
- CODICE_SIDI
- DATA_NASCITA
- RITIRATO
- DATA_RITIRO

Copy the student's data CSV file (exported from Argo) in the folder ``$BASE_DIR/dati_argo/studenti_argo/``.

Set the name of the CSV file in the script variable in file [_environment_working_tables.sh](_environment_working_tables.sh):

```bash
TABELLA_STUDENTI="studenti_argo_2024_09_06"
```

The path from where the data are imported (check it in the script) is:

```bash
FILE_CSV_STUDENTI="$BASE_DIR/dati_argo/studenti_argo/$TABELLA_STUDENTI.csv"
```

Prepare Excel and CSV file:

- Check the columns matches the fields to export (you can check the CREATE TABLE command in the script in case of trouble);
- Delete all empty rows;
- Save the Excel as CSV.

### Operations on students and classes

After exporting student's data from Argo, you can run the script:

- ``./gestisciStudenti.sh`` to manage students;
- ``./gestisciSezioni`` to manage students'class and class supervisors;
- ``./gestisciGruppiGSuiteStudenti.sh`` to manage groups on GSuite;
- ``./gestisciGruppiClasse.sh`` to manage students'class on GSuite.

Some operations needs you set the variables required for the operation. Check you set them in case of error.

## GSuite user management

### Export all users from GSuite

Users data are exported from GSuite, from the User section:

![gSuiteUsers.png](/dati_gsuite/gsuite_export_all_users.png).

Click on "download" and select all columns:

![gSuiteUserDownload.png](/dati_gsuite/gsuite_export_all_users_choose_all_fields.png).

Delete unwanted columns and replace the header as:
``nome cognome email_gsuite org_unit stato_utente ultimo_login spazio_email spazio_storage spazio_gdrive selezionato_il``;

Save the CSV file in the folder ``$BASE_DIR/dati_gsuite/``.

Set the name of the CSV file in the script variable in file [_environment_working_tables.sh](_environment_working_tables.sh):

```bash
TABELLA_UTENTI_GSUITE="utenti_gsuite_2024_09_06"
```

The path from where the data are imported (check it in the script) is:

```bash
FILE_CSV_STUDENTI="$BASE_DIR/dati_gsuite/$TABELLA_STUDENTI.csv"
```

### Operations on GSuite users

After exporting student's data from Argo, you can run the script:

- ``./gestisciTuttiUtentiGsuite.sh`` to manage all users.

Some operations needs you set the variables required for the operation. Check you set them in case of error.

## CdC Management

CdC data are exported from Argo:

![portaleArgo.png](/dati_argo/studenti_argo/portaleArgo.png)

Start a Print clicking the menu "Stampa", "Elenchi", "Particolari" and select the menu item "Docenti con materie e classi":

![portaleArgo.png](/dati_argo/cdc/argoCdC.png)

Copy the CdC data PDF file (exported from Argo) in the folder ``$BASE_DIR/dati_argo/cdc/``.

Set the name of the CSV file in the script variable in file [_environment_working_tables.sh](_environment_working_tables.sh):

```bash
TABELLA_CDC_ARGO="CdC_2025_10_24"
```

The path from where the data are imported (check it in the script) is:

```bash
FILE_CDC_ARGO_PDF="$BASE_DIR/dati_argo/cdc/$TABELLA_CDC_ARGO.pdf"
```

### Operations on CdC

After exporting student's data from Argo, you can run the script:

- ``./gestisciCdC.sh`` to manage all CdC;
- ``./gestisciGruppiGSuiteDocenti.sh`` to manage employees groups.

Some operations needs you set the variables required for the operation. Check you set them in case of error.

### Troubleshooting

Note: GAM OAuth Token has validity of 6 months from the last access. After 6 months of inactivity, you will get the error "gam ERROR: ('invalid_grant: Bad Request')" or ``{"error": "invalid_grant", "error_description": "Bad Request"}``. In this case, you need to re-authorize the Admin Access, running another time the command:

```bash
gam oauth create
```
