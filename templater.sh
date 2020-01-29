#!/usr/bin/env bash

#
# Simple templating system that replaces {{VAR}} by the value of $VAR.
# Supports default values by writting {{VAR=value}} in the template.
# Read values from a file using the same format; one {{VAR=value}} entry on each
# line.
#
# Any variable that has been set in the current environment will not be
# overwritten. This means that if you supply the value of a variable on the
# command line, this will ignore defaults in the template file, and also ignore
# any values provided by a config file.
#


readonly progname=$(basename $0)

# Display help message
getHelp() {
    cat << USAGE >&2

Usage: ${progname} [-h] [-d] [-f] [-s] --

    -f | --file         Specify a file to read variables from
    -h | --help         Print this help
    -p | --print        Don't do anything, just print the result of the variable expansion(s)
    -s | --silent       Output file or folder

Alternatively, you can specify the user and the repo in the right order.

Examples:

    VAR1=Something VAR2=1.2.3 ${progname} test.txt
    ${progname} test.txt -f my-variables.txt
    ${progname} test.txt -f my-variables.txt > new-test.txt

USAGE
}

# At least one parameter is needed
if [ $# -eq 0 ]; then
    getHelp
    exit 1
fi

# The first parameter must be the template file
if [ ! -f "${1}" ]; then
    echo "You need to specify a template file" 1>&2
    getHelp
    exit 1
else
    # The template file (with escaped slashes in path)
    template=$(echo $1 | sed 's/ /\\ /g')
    #
    shift 1
fi

# Default values
configFile=""
printOnly=0
silent=0

# Get input parameters
while [ $# -gt 0 ]; do
    case "$1" in
    
        -f|--file)
            configFile="$2"
            shift 2
        ;;
        
        -f=*|--file=*)
            configFile=$(printf "%s" "$1" | cut -d = -f 2)
            if [ ! -f "$configFile" ]; then
                echoerr "Config file '$configFile' not found."
                exit 1
            fi
            shift 1
        ;;

        -h|--help)
            getHelp
            exit 0
        ;;

        -p|--print)
            printOnly=1
            shift 1
        ;;

        -p=*|--print=*)
            case ${1#*=} in
                ''|[!0-1]) break ;;
                *) printOnly="${1#*=}" ;;
            esac
            shift 1
        ;;

        -s|--silent)
            silent=1
            shift 1
        ;;

        -s=*|--silent=*)
            case ${1#*=} in
                ''|[!0-1]) break ;;
                *) silent="${1#*=}" ;;
            esac
            shift 1
        ;;
        
        --)
            shift
            break
        ;;

        -*)
            echoerr "Invalid argument '$1'. Use --help to see the valid options"
            exit 1
        ;;

        # an option argument, continue
        *)
            shift
        ;;
    esac
done

# echo the message if not in quiet mode
echoerr() {
    [ "$silent" -ne 1 ] && printf "%s\n" "$*" 1>&2
}

# Evaluate variable from string
# Example: MY_VAR=1 eval_var "MY_VAR"   ===>  1
eval_var() {
    local var="${1}"
    eval echo \$"${var}"
}

# Escape custom characters in a string
# Example: escape "ab'\c" '\' "'"   ===>  ab\'\\c
escape() {
    local content="${1}"
    shift
    for char in "$@"; do content="${content//${char}/\\${char}}"; done
    echo "${content}"
}

# Evaluate expression
eval_expr() {
    local var="${1}"
    local value="${2}"
    local escaped="$(escape "${value}" "\\" '"')"

    echo "${var}=\"${escaped}\""
}

# List of variable in the template file
vars=$(grep -oE '\{\{\s*[A-Za-z0-9_]+\s*\}\}' "${template}" | sort | uniq | sed -e 's/^{{//' -e 's/}}$//')

# Load variables from config file
if [ -f "${configFile}" ]; then
    # create temp file
    tmpfile=$(mktemp)
    # escape & and "space" from config file
    sed -e "s;\&;\\\&;g" -e "s;\ ;\\\ ;g" "${configFile}" > $tmpfile
    # source the temp file
    source $tmpfile
fi

# array of strings to replace
declare -a replaces
replaces=()

# Reads default values defined as {{VAR=value}}
# They are evaluated, so you can do {{PATH=$HOME}} or {{PATH=$(pwd)}}
# You can even reference variables defined in the template before
defaults=$(grep -oE '\{\{[A-Za-z0-9_]+=.+\}\}' "${template}" | sed -e 's/^{{//' -e 's/}}$//')
IFS=$'\n'

# Evaluate default values
for default in $defaults; do
    # extract var name
    var=$(echo "$default" | grep -oE "^[A-Za-z0-9_]+")
    # evaluate var from global variables or config variables first
    value="$(eval_var "${var}")"

    # replace only if var is not set
    if [ -n "$value" ]; then
        eval "$(eval_expr "${var}" "${value}")"
    else
        eval "${default}"
    fi

    # remove define line
    replaces+=("-e")
    replaces+=("/^{{${var}=/d")

    #
    vars="${vars} ${var}"
done

vars="$(echo "${vars}" | tr " " "\n" | sort | uniq)"

# Print and exit
if [ $printOnly -eq 1 ]; then
    for var in $vars; do
        value="$(eval_var "${var}")"
        echo_var "${var}" "${value}"
    done
    exit 0
fi

# Replace all {{VAR}} by $VAR value
for var in $vars; do
    # evaluate var from global variables or config variables
    value="$(eval_var "${var}")"

    # check for empty value
    [ -z "$value" ] && echoerr "Warning: $var is not defined and no default is set, replacing by empty"

    # escape slashes
    value="$(escape "${value}" "\\" '/' ' ')";

    # replace {{VAR}}
    replaces+=("-e")
    replaces+=("s/{{\s*${var}\s*}}/${value}/g")
    # replace {{VAR=VALUE}}
    replaces+=("-e")
    replaces+=("s/{{\s*${var}\s*=\s*.*\s*}}/${value}/g")
    # replace {{VAR=$VARIABLE}}
    replaces+=("-e")
    replaces+=("s/{{\s*${var}\s*=\s*\\$\w*\s*}}/${value}/g")
done

# Replace all var and remove define line
sed "${replaces[@]}" "${template}"
