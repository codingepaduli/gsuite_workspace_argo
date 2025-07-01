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