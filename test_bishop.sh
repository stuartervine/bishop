#!/usr/bin/env bats

BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh

function stubSuggestedWords() {
    actualSuggestedWords=$1
    actualCurrentCommand=$2
}

function stubCommandCompletion() {
    actualCurrentCommand=$1
}

function noOp() {
    return 0
}

COMP_WORDS=("bishop" "files" "")
COMP_CWORD=1
#  jsonSelector=$(_jsonSelector)

# end to end
@test "bishop executes command" {
    output=$(bishop files ls)
    echo $output | grep "bishop.sh" #returns a line
}

# high level
@test "suggests keys in json tree below current command" {
  COMP_WORDS=("bishop" "files" "")
  COMP_CWORD=1
  _processCompletion stubSuggestedWords noOp noOp
  [ "$actualSuggestedWords" == "listDetails ls " ]
  [ "$actualCurrentCommand" == "files" ]
}

@test "resolves to static command when on leaf of json tree" {
  COMP_WORDS=("bishop" "files" "listDetails" "")
  COMP_CWORD=1
  _processCompletion noOp stubCommandCompletion noOp
   echo $actualCurrentCommand
  [ "$actualCurrentCommand" == "ls -al" ]
}

# unit
@test "_jsonSelector builds jq json selector given current word list" {
  COMP_WORDS=("bishop" "files" "")
  COMP_CWORD=1
  selector=$(_jsonSelector)
  [ "$selector" == ".[].files" ]
}

@test "_resolveCommand retrieves json object at selector position in commands file" {
   command=$(_resolveCommand ".[].files")
   [ "$command" == "{ \"ls\": \"ls\", \"listDetails\": \"ls -al\" }" ]
}

@test "_resolveCommand retrieves string when selector represents a leaf in the commands json" {
   command=$(_resolveCommand ".[].files.listDetails")
   [ "$command" == "ls -al" ]
}

@test "_resolveCommand returns null when no match to given selector" {
   command=$(_resolveCommand ".[].files.bobbins")
   [ "$command" == null ]
}

#@test "_commandCompleted outputs command in yellow" {
#    output=$(_commandCompleted "ls -al")
#    expected=$(tput sc; echo -e "\033[0;33m   <- ls -al\033[0m"; tput rc)
#    echo $output
#    echo $expected
#    [ "$output" == "$expected" ]
#}