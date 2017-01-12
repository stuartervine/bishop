#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
no_colour='\033[0m'

function _currentRunningDirectory() {
    echo "$( dirname "${BASH_SOURCE[0]}" )"
}

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
    if [ $1 == "upgrade" ]; then
        blue
        echo "Upgrading bishop..."
        clear
        currentDir=$(pwd)
        cd `_currentRunningDirectory`
        curl -H 'Cache-Control: no-cache' -# https://raw.githubusercontent.com/stuartervine/bishop/master/bishop.sh > bishop.sh
        source bishop.sh
        red
        echo "Bishop up to date."
        clear
        cd $currentDir
    else
        local currentDir=$(pwd)
        local selector=".[]"
        local parameters=""
        for word in $@;
        do
            local commandJson=$(cat $BISHOP_COMMANDS_FILE | jq $selector);
            local jsonObjectType=$(echo $commandJson | jq "type")
            if [ $jsonObjectType != "\"string\"" ]; then
                selector="$selector.$word";
            else
                parameters="$parameters $word"
            fi
        done
        local command=$(cat $BISHOP_COMMANDS_FILE | jq $selector)
        local command="${command%\"}"
        local command="${command#\"} $parameters"
        eval $command
    fi
}

function ignoreNull() {
    if [ "$1" == "null" ]; then
        echo ""
    else
        echo $1
    fi
}

function _filterArray() {
    local filterValue=$1
    local arr=${@:2}
    local index=0
    for item in ${arr[@]};
    do
        if [[ $item == $filterValue ]]; then
            output[$index]=$item
            index=$((index+1))
        fi
    done
    echo "${output[@]}"
}

function _filterNotArray() {
    local filterValue=$1
    local arr=${@:2}
    local index=0
    for item in ${arr[@]};
    do
        if [[ $item != $filterValue ]]; then
            output[$index]=$item
            index=$((index+1))
        fi
    done
    echo "${output[@]}"
}

function _resolveCommand() {
    local command=$(cat $BISHOP_COMMANDS_FILE | jq $1)
    local command="${command%\"}"
    local command="${command#\"}"
    echo $command
}

function _cleanUpCommand() {
    local command="${1%\"}"
    local command="${command#\"}"
    echo $command
}

function _resolveCommandUsingArray() {
    local jqFilters=${@:1}
    local chainedCommand=""
    local json=$(cat $BISHOP_COMMANDS_FILE)
    for jqFilter in ${jqFilters[@]};
    do
        json=$(echo $json | jq $jqFilter)
        local jsonObjectType=$(echo $json | jq "type")
        if [ $jsonObjectType == "\"string\"" ]; then
            local commandToAppend=$(_cleanUpCommand "$(ignoreNull "$json")")
            chainedCommand="$chainedCommand $commandToAppend"
        else
            local commandToChain=$(_cleanUpCommand $(ignoreNull $(echo $json | jq "._chainedCommand")))
            chainedCommand="$chainedCommand $commandToChain"
        fi
    done
    echo $chainedCommand
}

function _parseJsonCommands() {
    commandJson=$1
    commandsAndVariables=($(echo $commandJson | jq "keys | .[]" | tr -d "\"" | tr "\n" " "))
    echo $(_filterNotArray "_*" ${commandsAndVariables[@]})
}

function _parseJsonVariables() {
    local commandJson=$1
    local commandsAndVariables=($(echo $commandJson | jq "keys | .[]" | tr -d "\"" | tr "\n" " "))
    echo $(_filterArray "_*" ${commandsAndVariables[@]})
}

function _walkJsonAndCreateVariables() {
    local selector=".[]"
    local completedWords=("${COMP_WORDS[@]:1}")
    unset completedWords[${#completedWords[@]}-1]
    for word in ${completedWords[@]};
    do
        commandJson=$(_matchingCommandJson "$selector")
        variables=$(_parseJsonVariables "$commandJson")
        for variable in ${variables[@]};
        do
            variableKey="${variable#"_"}"
            variableValue=$(_resolveCommand "$selector.$variable")
            eval "export $variableKey=$variableValue"
        done
        selector="$selector.$word"
    done
}

function _jsonSelector() {
    local selector=".[]"
    local completedWords=("${COMP_WORDS[@]:1}")
    unset completedWords[${#completedWords[@]}-1]
    for word in ${completedWords[@]}; do selector="$selector.\"$word\""; done
    echo $selector
}

function _jsonSelectorAsArray() {
    local selector=(".[]")
    local completedWords=("${COMP_WORDS[@]:1}")
    unset completedWords[${#completedWords[@]}-1]
    echo ".[]"
    for word in ${completedWords[@]}; do echo ".\"$word\""; done
}

function _matchingCommandJson() {
    local selector=$1
    echo $(cat $BISHOP_COMMANDS_FILE | jq $selector)
}

function _wordsSuggested() {
    local commands=$1
    local currentWord=$2
    COMPREPLY=($(compgen -W "${commands}" -- ${currentWord}))
}

function _commandCompleted() {
    local currentCommand=$(echo $1 | tr "\n" " ")
    export lastCommand=$currentCommand
    tput sc
    yellow
    echo -ne "   <- $currentCommand"
    clear
    tput rc
}

function _tabPressedTwiceOnCompletedCommand() {
    local currentCommand=$1
    local ps1=$(PS1="$PS1" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')
    echo; read -e -p "$ps1$currentCommand" opt; eval "$currentCommand$opt"
}

function _processCompletion() {
    COMPREPLY=()
    _walkJsonAndCreateVariables

    local suggestWordsFn=$1
    local commandCompletedFn=$2
    local tabPressedTwiceOnCompletionFn=$3

    local currentWord="${COMP_WORDS[COMP_CWORD]}"
    local selector=$(_jsonSelector)
    local selectorArray=$(_jsonSelectorAsArray)
    local commandJson=$(_matchingCommandJson $selector)
    local jsonObjectType=$(echo $commandJson | jq "type")
    if [ $jsonObjectType != "\"string\"" ]; then
        CURRENT_TAB_COUNT=0
        local commands=$(_parseJsonCommands "$commandJson")
        $suggestWordsFn "${commands[@]}" $currentWord
    else
        local currentCommand=$(_resolveCommandUsingArray $selectorArray)
        local commandWithVariables=$(eval "echo \"$currentCommand\"")
        $commandCompletedFn "$commandWithVariables"
        if [[ $CURRENT_TAB_COUNT -eq 2 ]]; then
            $tabPressedTwiceOnCompletionFn "$commandWithVariables"
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

BISHOP_INSTALLED_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"