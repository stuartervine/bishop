#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
no_colour='\033[0m'

function yellow() {
    echo -e "${yellow}"
}

function green() {
    echo -e "${green}"
}

function blue() {
    echo -ne "${blue}"
}

function red() {
    echo -ne "${red}"
}

function clear() {
    echo -ne "${no_colour}"
}

function bishop() {
    currentDir=$(pwd)
    selector=".[]"
    for word in $@; do selector="$selector.$word"; done
    command=$(cat $BISHOP_COMMANDS_FILE | jq $selector)
    command="${command%\"}"
    command="${command#\"}"
    eval $command
}

function resolveCommand() {
    command=$(cat $BISHOP_COMMANDS_FILE | jq $1)
    command="${command%\"}"
    command="${command#\"}"
    echo $command
}

function _complete() {
    local cur prev opts
    COMPREPLY=()
    currentWord="${COMP_WORDS[COMP_CWORD]}"
    previousWord="${COMP_WORDS[COMP_CWORD-1]}"
    selector=".[]"
    completedWords=("${COMP_WORDS[@]:1}")
    unset completedWords[${#completedWords[@]}-1]
    for word in ${completedWords[@]}; do selector="$selector.$word"; done
    commandJson=$(cat $BISHOP_COMMANDS_FILE | jq $selector)
    jsonObjectType=$(echo $commandJson | jq "type")
    if [ $jsonObjectType != "\"string\"" ]; then
        commands=$(echo $commandJson | jq "keys | .[]" | tr -d "\"" | tr "\n" " ")
        COMPREPLY=( $(compgen -W "${commands}" -- ${currentWord}) )
    else
        tput sc
        yellow
        echo -ne "   <- $(resolveCommand $selector)"
        clear
        tput rc
        COMREPLY=""
    fi
}

if [ -z $BISHOP_COMMANDS_FILE ]; then
    red
    echo "Need to set up BISHOP_COMMANDS_FILE variable in your profile."
    yellow
    echo "e.g. export BISHOP_COMMANDS_FILE=$(pwd)/example_commands.json"
    clear
    return
fi
if ! [ $(command -v jq) ]; then
    echo "Bishop requires JQ: sudo apt-get install jq | brew install jq"
    return
fi

complete -F _complete "bishop"

installedDirectory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

