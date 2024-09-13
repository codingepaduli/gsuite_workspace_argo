#!/bin/bash

# shellcheck source=./_environment.sh
source "_environment.sh"

# Tabella docenti versionata alla data indicata
TABELLA_DOCENTI_ARGO="docenti_argo_2024_09_08"

# script CF -> mail nuovi docenti
DOCENTI_SCRIPT="$EXPORT_DIR_DATE/docenti_associa_CF_email.sh"

# CSV docenti
EXPORT_DOCENTI_CSV="$EXPORT_DIR_DATE/docenti_2024_25.csv"

# Aggiunge gli insegnanti a classroom
GRUPPO_CLASSROOM="insegnanti_classe@$DOMAIN"

mkdir -p "$EXPORT_DIR_DATE"

# Preparo lo script
echo "#!/bin/bash" > "$DOCENTI_SCRIPT"
echo 'source "_environment.sh"' >> "$DOCENTI_SCRIPT"
echo "TABELLA_DOCENTI_ARGO=\"$TABELLA_DOCENTI_ARGO\"" >> "$DOCENTI_SCRIPT"

while IFS="," read -r email_gsuite cognome nome cod_fisc email_personale tel; do
  echo "Creo docente $email_gsuite firstname \"$nome\" lastname \"$cognome\" recoveryemail $email_personale recoveryphone $tel"

  # Create user
  $GAM_CMD create user "$email_gsuite" firstname "$nome" lastname "$cognome" password Volta2425 changepassword on org Docenti recoveryemail $email_personale

  # Add the user to classroom
  $GAM_CMD update group "$GRUPPO_CLASSROOM" add member user "$email_gsuite"

  # Aggiungo il CF negli script
  echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_DOCENTI_ARGO SET email_gsuite = '$email_gsuite' WHERE \$TABELLA_DOCENTI_ARGO.cod_fisc = '$cod_fisc'\";" >> "$DOCENTI_SCRIPT" 
  
done < <($SQLITE_CMD -csv studenti.db "select 'd.' || replace(replace(LOWER(nome), '''', ''), ' ', '_') || '.' || replace(replace(LOWER(cognome), '''',''), ' ', '_') || '@$DOMAIN' as email_gsuite, cognome, nome, cod_fisc, email_personale, tel FROM $TABELLA_DOCENTI_ARGO WHERE $TABELLA_DOCENTI_ARGO.email_gsuite is NULL ORDER BY cognome" | sed "s/\"//g")

# Export new users in CSV file
$SQLITE_CMD -header -csv studenti.db "select 'd.' || replace(replace(LOWER(nome), '''', ''), ' ', '_') || '.' || replace(replace(LOWER(cognome), '''',''), ' ', '_') || '@$DOMAIN' as email_gsuite, cognome, nome, cod_fisc, email_personale, tel FROM $TABELLA_DOCENTI_ARGO WHERE $TABELLA_DOCENTI_ARGO.email_gsuite is NULL ORDER BY cognome" > "$EXPORT_DOCENTI_CSV"