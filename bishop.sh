#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
no_colour='\033[0m'

function yellow() {
    echo -ne "${yellow}"
}

function green() {
    echo -ne "${green}"
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

function _jsonSelector() {
    local selector=".[]"
    completedWords=("${COMP_WORDS[@]:1}")
    unset completedWords[${#completedWords[@]}-1]
    for word in ${completedWords[@]}; do selector="$selector.$word"; done
    echo $selector
}

function _matchingCommandJson() {
    local selector=$1
    echo $(cat $BISHOP_COMMANDS_FILE | jq $selector)
}

function _wordsSuggested() {
    COMPREPLY=($1)
}

function _commandCompleted() {
    selector=$1
    currentCommand=$(resolveCommand $selector)
    tput sc
    yellow
    echo -ne "   <- $currentCommand"
    clear
    tput rc
}

function _tabPressedTwiceOnCompletedCommand() {
    currentCommand=$1
    ps1=$(PS1="$PS1" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')
    echo; read -e -p "$ps1$currentCommand" opt; eval "$cmd$opt"
}

function _processCompletion() {
    echo "Here"
    suggestWordsFn=$1
    commandCompletedFn=$2
    tabPressedTwiceOnCompletionFn=$3
    COMPREPLY=()
    currentWord="${COMP_WORDS[COMP_CWORD]}"
    selector=$(_jsonSelector)
    commandJson=$(_matchingCommandJson $selector)
    jsonObjectType=$(echo $commandJson | jq "type")
    echo $commandJson
    if [ $jsonObjectType != "\"string\"" ]; then
        CURRENT_TAB_COUNT=0
        commands=$(echo $commandJson | jq "keys | .[]" | tr -d "\"" | tr "\n" " ")
        $suggestWordsFn $(compgen -W "${commands}" -- ${currentWord})
    else
        $commandCompletedFn $selector
        if [ $CURRENT_TAB_COUNT -eq 3 ]; then
            $tabPressedTwiceOnCompletionFn "$currentCommand"
            return 0
        fi
        ((CURRENT_TAB_COUNT+=1))
    fi
}

function _complete() {
    _processCompletion _wordsSuggested _commandCompleted _tabPressedTwiceOnCompletedCommand
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