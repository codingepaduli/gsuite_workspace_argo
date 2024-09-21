#!/bin/bash

# shellcheck source=./_environment.sh
source "./_environment.sh"

command=""
nome_gruppo=""
query=""

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

: '
echo "Comando: $command"
echo "Gruppo: $nome_gruppo"
echo "Query: $query"
echo "Tutti i parametri: $*"
'

# mkdir -p "$EXPORT_DIR_DATE"
# $SQLITE_CMD studenti.db "CREATE TABLE IF NOT EXISTS '$nome_gruppo' ('group' VARCHAR(200), name  VARCHAR(200), id VARCHAR(200), email VARCHAR(200), role VARCHAR(200), type VARCHAR(200), status VARCHAR(200));"
# $SQLITE_CMD studenti.db "DROP TABLE IF EXISTS '$nome_gruppo';"

case $command in
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
    "deleteMembersFromGroup")
        while IFS="," read -r email; do
            $GAM_CMD update group "$nome_gruppo@$DOMAIN" remove member user "$email"
        done < <($SQLITE_CMD -csv studenti.db "$query" | sed 's/"//g' )
        ;;
    *)
        echo "Nothings"
        sleep 1
        ;;
esac
