#!/bin/bash

source "_environment.sh"

# Tabella studenti versionata alla data indicata
TABELLA_STUDENTI="studenti_argo_2024_09_06"

# Tabella sezioni per anno
TABELLA_SEZIONI="sezioni_2024_25"

# script nuovi studenti di prima
PRIME_SCRIPT="$EXPORT_DIR_DATE/studenti_associa_CF_email_prime.sh"

# CSV studenti di prima
EXPORT_PRIME_CSV="$EXPORT_DIR_DATE/studenti_prime_2024_25.csv"

# Dominio
DOMAIN="" # @isis.it

mkdir -p "$EXPORT_DIR_DATE"

# Comunico i nuovi gruppi (le classi) a gsuite
while IFS="," read -r sezione_gsuite; do
  group="$sezione_gsuite"
  group_mail="$sezione_gsuite@$DOMAIN"
  group_description="2024-25"
  echo "$group_mail";

  break
  $GAM_CMD create group "$group_mail" name "$group" description "$group_description"
done < <($SQLITE_CMD -csv studenti.db "select sezione_gsuite FROM $TABELLA_SEZIONI WHERE cl=1  ORDER BY sezione_gsuite;") # AND $TABELLA_SEZIONI.sezione_gsuite = '1A_en'

# Preparo lo script
echo "#!/bin/bash" > "$PRIME_SCRIPT"
echo 'source "_environment.sh"' >> "$PRIME_SCRIPT"
echo "TABELLA_STUDENTI_DOPO=\"$TABELLA_STUDENTI\"" >> "$PRIME_SCRIPT"

# seleziono gli studenti senza mail delle prime classi
while IFS="," read -r email_argo cognome nome cod_fisc cl sez sezione_gsuite; do
  # Creo gli utenti delle prime classi
  echo "Creo l'utente $email_argo firstname \"$nome\" lastname \"$cognome\" della classe $cl $sez"
  break
  # $GAM_CMD create user "$email_argo" firstname "$nome" lastname "$cognome" password Volta2425 changepassword on org Studenti/Diurno

  # Aggiungo l'utente nel gruppo classe
  group_mail="$sezione_gsuite@$DOMAIN"
  echo "aggiungo nel gruppo $group_mail l'utente $email_argo della classe $cl $sez"
  # $GAM_CMD update group "$sezione_gsuite" add member user "$email_argo"

  # Aggiungo il CF negli script
  echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI_DOPO SET email_argo = '$email_argo' WHERE \$TABELLA_STUDENTI_DOPO.cod_fisc = '$cod_fisc'\"; # $sezione_gsuite" >> "$PRIME_SCRIPT" 
done < <($SQLITE_CMD -csv studenti.db "select 's.' || replace(replace(cognome, '''',''), ' ', '_') || '.' || replace(replace(nome, '''', ''), ' ', '_') || '.' || matricola || '@$DOMAIN' as email, cognome, nome, cod_fisc, $TABELLA_STUDENTI.cl, $TABELLA_STUDENTI.sez, sezione_gsuite FROM $TABELLA_STUDENTI INNER JOIN $TABELLA_SEZIONI ON $TABELLA_SEZIONI.cl = $TABELLA_STUDENTI.cl AND $TABELLA_SEZIONI.sez_argo = $TABELLA_STUDENTI.sez WHERE $TABELLA_SEZIONI.cl=1 AND email_argo is NULL ORDER BY $TABELLA_SEZIONI.sezione_gsuite, $TABELLA_STUDENTI.cod_fisc" | sed "s/\"//g") # AND $TABELLA_SEZIONI.sezione_gsuite != '1A_en' 

# Reset password utenti delle prime classi con gia la mail
while IFS="," read -r email_argo cognome nome cod_fisc cl sez sezione_gsuite; do
  # Reset password utente
  echo "Reset password utente $email_argo firstname \"$nome\" lastname \"$cognome\" della classe $cl $sez"
  break
  # $GAM_CMD update user $email_argo password Volta2425 changepassword on 

  group_mail="$sezione_gsuite@$DOMAIN"
  echo "aggiungo nel gruppo $group_mail l'utente $email_argo della classe $cl $sez"
  # $GAM_CMD update group "$sezione_gsuite" add member user "$email_argo"

  echo "\$SQLITE_CMD -header -csv studenti.db \"UPDATE \$TABELLA_STUDENTI_DOPO SET email_argo = '$email_argo' WHERE \$TABELLA_STUDENTI_DOPO.cod_fisc = '$cod_fisc'\"; # $sezione_gsuite" >> "$PRIME_SCRIPT" 
done < <($SQLITE_CMD -csv studenti.db "select email_argo, cognome, nome, cod_fisc, $TABELLA_STUDENTI.cl, $TABELLA_STUDENTI.sez, sezione_gsuite FROM $TABELLA_STUDENTI INNER JOIN $TABELLA_SEZIONI ON $TABELLA_SEZIONI.cl = $TABELLA_STUDENTI.cl AND $TABELLA_SEZIONI.sez_argo = $TABELLA_STUDENTI.sez WHERE $TABELLA_SEZIONI.cl=1 AND email_argo is NOT NULL ORDER BY $TABELLA_SEZIONI.sezione_gsuite, $TABELLA_STUDENTI.cod_fisc" | sed "s/\"//g") # AND $TABELLA_SEZIONI.sezione_gsuite != '1A_en'

# Export tutti gli studenti delle prime classi con email (nuova o vecchia) e password nuova
$SQLITE_CMD -csv -header studenti.db "select $TABELLA_STUDENTI.cl as anno, letter as sezione, addr_argo as indirizzo, sezione_gsuite as gruppo,
  CASE
    WHEN email_argo is NULL THEN 's.' || replace(replace(cognome, '''',''), ' ', '_') || '.' || replace(replace(nome, '''', ''), ' ', '_') || '.' || matricola || '@$DOMAIN'
    ELSE email_argo
  END 
as email, 'Volta2425' AS password, cognome, nome, cod_fisc, matricola 
FROM $TABELLA_STUDENTI INNER JOIN $TABELLA_SEZIONI ON $TABELLA_SEZIONI.cl = $TABELLA_STUDENTI.cl AND $TABELLA_SEZIONI.sez_argo = $TABELLA_STUDENTI.sez 
WHERE $TABELLA_SEZIONI.cl=1 
ORDER BY $TABELLA_SEZIONI.sezione_gsuite, $TABELLA_STUDENTI.cognome" > "$EXPORT_PRIME_CSV"
