# Architecture

See [ARCHITECTURE](https://matklad.github.io//2021/02/06/ARCHITECTURE.md.html) for the purpose of this file.

## Files and folders

- [sqlite](sqlite) folder: The sqlite folder contains the sql3 executable, needed to manage the database that contains the data;
- [_environment.sh](_environment.sh) file: Sets the environment variables used in the scripts;
- [dati_argo/studenti_argo/sezioni_YYYY_YY.csv](dati_argo/studenti_argo/sezioni_YYYY_YY.csv) file: contains the section and classes extracted by students;
- [dati_argo/studenti_argo/studenti_argo_YYYY_MM_DD.csv](dati_argo/studenti_argo/studenti_argo_YYYY_MM_DD.csv) file: contains the CSV data exported by "custom export" steps (as Excel file saved in CSV format). Fields to export are:

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
