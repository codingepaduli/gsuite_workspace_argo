#!/bin/bash

# Utility per gestire le mappe in bash

# Mappa (array associativo)
declare -A gruppi

# Funzione per aggiungere elementi alla mappa
add_to_map() {
    local key=$1
    local value=$2
    gruppi[$key]=$value
}

# Funzione per ottenere un valore dalla mappa
get_from_map() {
    local key=$1
    echo "${gruppi[$key]}"
}

# Funzione per rimuovere un elemento dalla mappa
remove_from_map() {
    local key=$1
    unset "gruppi[$key]"
}

######################
#       Utils        #
######################


# Check all variables are defined
## Run: checkAllVarsDefined JAVA_HOME PROVA_MIA
checkAllVarsDefined() {
    # Controlla se sono stati passati parametri
    if [ $# -eq 0 ]; then
        return 1  # Errore: nessun parametro fornito
    fi

    for var in "$@"; do
        if [[ ! -v $var ]]; then
            echo "Errore: variabile '$var' non definita." >&2
            return 2  # Errore: variabile non definita
        fi
    done
}
export -f checkAllVarsDefined

# Check all variables are not empty
## Run: checkAllVarsNotEmpty JAVA_HOME ID MY_TEST
checkAllVarsNotEmpty() {
    # Controlla se sono stati passati parametri
    if [ $# -eq 0 ]; then
        return 1  # Errore: nessun parametro fornito
    fi

    for var in "$@"; do
        # Controlla se la variabile è non definita o vuota
        if [[ ! -v $var || -z "${!var}" ]]; then
            echo "Errore: variabile '$var' non definita o vuota." >&2
            return 2  # Errore: variabile non definita o vuota
        fi
    done

    return 0  # Tutte le variabili sono definite e non vuote
}
export -f checkAllVarsNotEmpty

function log::level_is_active {
  local check_level current_level
  check_level=$1

  declare -A log_levels=(
    [TRACE]=1
    [DEBUG]=2
    [CONFIG]=3
    [INFO]=4
    [WARN]=5
    [ERROR]=6
    [OFF]=100
  )

  check_level="${log_levels["$check_level"]}"
  current_level="${log_levels["$LOG_LEVEL"]}"

  (( check_level >= current_level ))
}

function log::_write_log {
  local timestamp file function_name log_level
  log_level=$1
  shift

  timestamp=$(date +'%y.%m.%d %H:%M:%S')
  file="${BASH_SOURCE[2]##*/}"
  function_name="${FUNCNAME[2]}"

  if log::level_is_active "$log_level" && [[ " ${LOG_OUTPUT[*]} " =~ " console " ]]; then
    printf '%s [%s] [%s - %s]: %s\n'  "$log_level" "$timestamp" "$file" "$function_name" "${*}" >&2
    if [ "$log_level" == "ERROR" ]; then
      log::printStackTrace >&2
    fi
  fi

  if log::level_is_active "$log_level" && [[ " ${LOG_OUTPUT[*]} " =~ " file " ]]; then
    printf '%s [%s] [%s - %s]: %s\n'  "$log_level" "$timestamp" "$file" "$function_name" "${*}" >> "$LOG_FILE"
    if [ "$log_level" == "ERROR" ]; then
      log::printStackTrace >> "$LOG_FILE"
    fi
  fi

}

log::printStackTrace() {
    local stack_offset=2

    for stack_id in "${!FUNCNAME[@]}"; do
      if [[ "$stack_offset" -le "$stack_id" ]]; then
        local source_file="${BASH_SOURCE[$stack_id]}"
        local function="${FUNCNAME[$stack_id]}"
        local line="${BASH_LINENO[$(( stack_id - 1 ))]}"
        printf '\t%s:%s:%s\n' "$source_file" "$function" "$line"
      fi
    done
}

handle_error() {
    local environment="${DEPLOY_ENV:-}"
    local currentTime="$(date +'%Y-%m-%d %H:%M:%S')"
    local currentUser="$(whoami)"
    local exit_code=$?
    local file="$0"
    local cmd="$1"

    local lastIndex=$((${#BASH_SOURCE[@]} - 1))

    {
        echo ""
        echo ""
        echo "[$currentUser][$environment] $currentTime ERROR in Script: $file"
        echo "  The command: '$cmd' returned exit status '$exit_code'"
        printf '%s:\n' '  Stacktrace:'
        log::printStackTrace
    } >&2

    exit $exit_code
}
export -f handle_error

# e: Termina lo script se un comando restituisce un valore di uscita diverso da zero
# E: per gestire gli errori all'interno delle funzioni con trap.
# u: Termina lo script se si tenta di utilizzare una variabile non definita
# o pipefail: Imposta il valore di uscita di una pipeline (una serie di comandi collegati) per essere diverso da zero se uno qualsiasi dei comandi nella pipeline fallisce. Senza questa opzione, il valore di uscita della pipeline è quello dell'ultimo comando.

# log::_write_log "DEBUG" "TEST debug"
# log::_write_log "WARN" "TEST warn"
# log::_write_log "ERROR" "ERRORE NON PREVISTO"

set -eEuo pipefail

trap 'log::_write_log "ERROR" "$BASH_COMMAND"' ERR

# trap -p show the trap enabled
