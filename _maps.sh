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
        local stack_offset=1

        for stack_id in "${!FUNCNAME[@]}"; do
          if [[ "$stack_offset" -le "$stack_id" ]]; then
            local source_file="${BASH_SOURCE[$stack_id]}"
            local function="${FUNCNAME[$stack_id]}"
            local line="${BASH_LINENO[$(( stack_id - 1 ))]}"
            >&2 printf '\t%s:%s:%s\n' "$source_file" "$function" "$line"
          fi
        done
    } >&2

    exit $exit_code
}
export -f handle_error


# e: Termina lo script se un comando restituisce un valore di uscita diverso da zero
# E: per gestire gli errori all'interno delle funzioni con trap.
# u: Termina lo script se si tenta di utilizzare una variabile non definita
# o pipefail: Imposta il valore di uscita di una pipeline (una serie di comandi collegati) per essere diverso da zero se uno qualsiasi dei comandi nella pipeline fallisce. Senza questa opzione, il valore di uscita della pipeline è quello dell'ultimo comando.

set -eEuo pipefail

trap 'handle_error "$BASH_COMMAND"' ERR

# trap -p show the trap enabled
