#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"
source "./_environment_working_tables.sh"

command=""
nome_gruppo=""
query=""
dry_run="$DRY_RUN"

# Funzione per mostrare il menu
show_menu() {
    echo "-----------------------------"
    echo "| Gestisce azioni su GSuite |"
    echo "-----------------------------"
    echo "./usaComandoConQuery.sh -c|--command comando -g|--group gruppo -q|--query query"
    echo "-c | --command indica l'azione da eseguire"
    echo "-g | --group indica il gruppo GSuite sul quale lavorare"
    echo "-q | --query indica la query dalla quale prendere i dati"
    echo " "
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--command)
      if [[ "$2" != "" ]]; then
        command="$2"
        shift 2
      else
        show_menu
        echo "Errore [$1 $2]: Il parametro -n o --name richiede un valore"
        exit 1
      fi
      ;;
    -g|--group)
      if [[ "$2" != "" ]]; then
        nome_gruppo="$2"
        shift 2
      else
        show_menu
        echo "Errore [$1 $2]: Il parametro -g o --group richiede un valore"
        exit 1
      fi
      ;;
    -q|--query)
      if [[ "$2" != "" ]]; then
        query="$2"
        shift 2
      else
        show_menu
        echo "Errore [$1 $2]: Il parametro -q o --query richiede un valore"
        exit 1
      fi
      ;;
    *)
      show_menu
      echo "Errore: Opzione non riconosciuta: $1"
      exit 1
      ;;
  esac
done

# echo "  Tutti i parametri: -dry-run: $dry_run command $command group $nome_gruppo query $query"

if [ -n "$dry_run" ]; then
  echo "Debug info:"
  echo "  Comando: $command"
  echo "  Gruppo: $nome_gruppo"
  echo "  Query: $query"
  echo "  running with --dry-run: $dry_run"
  echo "running query: $query"
  $SQLITE_CMD -csv studenti.db "BEGIN TRANSACTION; $query ROLLBACK; " | sed 's/"//g'
  exit 0
fi

# mkdir -p "$EXPORT_DIR_DATE"
# $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$nome_gruppo' ('group' VARCHAR(200), name  VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200), type VARCHAR(200), status VARCHAR(200));"
# $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$nome_gruppo';"

case $command in
    "createUsers")
        while IFS="," read -r email_gsuite cognome nome cod_fisc email_personale tel; do
            $GAM_CMD create user "$email_gsuite" firstname "$nome" lastname "$cognome" password "$PASSWORD_CLASSROOM" changepassword on org "$nome_gruppo" recoveryemail "$email_personale"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "createStudents")
        while IFS="," read -r email_gsuite cognome nome cod_fisc email_personale tel; do
            $GAM_CMD create user "$email_gsuite" firstname "$nome" lastname "$cognome" password "Volta2425" changepassword on org "$nome_gruppo" recoveryemail "$email_personale"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "resetPasswordUser")
        while IFS="," read -r email_gsuite; do
            $GAM_CMD update user "$email_gsuite" password "Reset202526" changepassword off
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "suspendUsers")
        while IFS="," read -r email_gsuite; do
            $GAM_CMD update user "$email_gsuite" suspended on
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "deleteUsers")
        while IFS="," read -r email_gsuite; do
            $GAM_CMD delete user "$email_gsuite"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "createUsersOnWordPress")
        while IFS="," read -r email_gsuite cognome nome cod_fisc email_personale tel; do
            echo "aggiungo su Classroom $email_gsuite $cognome $nome"
            # Add the user to WordPress as teacher
            ## -w "%{http_code}"  Show the HTTP status code
            ## -o /dev/null       Redirect output to /dev/null
            ## -f                 show only see the error message
            curl -X POST "$WORDPRESS_URL"wp-json/wp/v2/users --no-progress-meter -u "$WORDPRESS_ACCESS_TOKEN" -d username="$email_gsuite" -d first_name="$nome" -d last_name="$cognome" -d email="$email_personale" -d password="$PASSWORD_CLASSROOM" -d roles="$nome_gruppo" | python3 jsonReaderUtil.py
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "showUsersOnWordPress")
        while IFS="," read -r email_gsuite; do
            # Add the user to WordPress as teacher
            ## -w "%{http_code}"  Show the HTTP status code
            ## -o /dev/null       Redirect output to /dev/null
            ## -f                 show only see the error message
            ## Add params to the url for pagination &per_page=100&page=1
            curl -X GET --no-progress-meter "${WORDPRESS_URL}wp-json/wp/v2/users?search=${email_gsuite}&_fields=id,email,nickname,registered_date,roles,slug,status&per_page=100&page=1" -u "$WORDPRESS_ACCESS_TOKEN" | python3 jsonReaderUtil.py
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "deleteUsersOnWordPress")
        while IFS="," read -r id slug name; do
            
          echo "cancello $id $slug $name"

          # Delete the user from id
          ## -w "%{http_code}"  Show the HTTP status code
          ## -o /dev/null       Redirect output to /dev/null
          ## -f                 show only see the error message
          ## ?reassign=ID     ID dell'utente sul quale spostare i contenuti
          #curl -X DELETE --no-progress-meter "${WORDPRESS_URL}wp-json/wp/v2/users/$id?reassign=${WORDPRESS_USER_ID_FOR_DELETING}&force=true" -u "$WORDPRESS_ACCESS_TOKEN"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "createGroup")
        $GAM_CMD create group "$nome_gruppo@$DOMAIN" name "$nome_gruppo" description "$GROUP_DESCRIPTION"
        ;;
    "printGroup")
        $GAM_CMD print group-members group "$nome_gruppo" membernames fields 'id,email,role,type,status'
        ;;
    "deleteGroup")
        $GAM_CMD delete group "$nome_gruppo"
        ;;
    "addMembersToGroup")
        while IFS="," read -r email; do
            $GAM_CMD update group "$nome_gruppo@$DOMAIN" add member user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "addMembersToGroupByMap")
        while IFS="," read -r gruppo email; do
            $GAM_CMD update group "$gruppo@$DOMAIN" add member user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "deleteMembersFromGroup")
        while IFS="," read -r email; do
            $GAM_CMD update group "$nome_gruppo@$DOMAIN" remove member user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "deleteMembersFromGroupByMap")
        while IFS="," read -r gruppo email; do
            $GAM_CMD update group "$gruppo@$DOMAIN" remove member user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "moveUsersToOU")
        while IFS="," read -r email; do
            $GAM_CMD update org "$nome_gruppo" add user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    "executeQuery")
        $SQLITE_CMD studenti.db --csv --header "$query" | sed 's/"//g'
        ;;
    *)
        echo "Nothings"
        sleep 1
        ;;
esac
