#!/usr/local/bin/bats

BISHOP_COMMANDS_FILE=`pwd`/test/test_commands.json
. bishop.sh

function stubSuggestedWords() {
    actualSuggestedWords=$1
    actualCurrentCommand=$2
}

function stubCommandCompletion() {
    actualCurrentCommand=$1
}

function stubTabPressedTwice() {
    tabbedPressedTwiceWithCurrentCommand=$1
}

function noOp() {
    return 0
}

COMP_WORDS=("bishop" "files" "")
COMP_CWORD=1

# end to end
@test "bishop executes command" {
    BISHOP_ALIAS="bishop"
    output=$(_bishop files ls)
    echo $output
    echo $output | grep "bishop.sh" #returns a line
}

@test "executes command passing through any additional parameters" {
    BISHOP_ALIAS="bishop"
    output=$(_bishop files ls *.sh)
    echo $output | grep "bishop.sh"
}

# high level
@test "suggests keys in json tree below current command" {
  COMP_WORDS=("bishop" "files" "")
  COMP_CWORD=1
  _processCompletion stubSuggestedWords noOp noOp
  echo $actualSuggestedWords
  [ "$actualSuggestedWords" == "listDetails ls" ]
  [ "$actualCurrentCommand" == "files" ]
}

@test "creates a command from the chain tags under each json node, or ignores if there is none" {
  COMP_WORDS=("bishop" "chained" "command" "test" "")
  COMP_CWORD=1
  _processCompletion noOp stubCommandCompletion noOp
  echo "'$actualCurrentCommand'"
  [ "$actualCurrentCommand" == "echo chained > command.txt" ]
}

@test "resolves to static command when on leaf of json tree" {
  COMP_WORDS=("bishop" "files" "listDetails" "")
  COMP_CWORD=1
  _processCompletion noOp stubCommandCompletion noOp
  [ "$actualCurrentCommand" == "ls -al" ]
}

@test "increments tab count when processing completion" {
  COMP_WORDS=("bishop" "files" "listDetails" "")
  COMP_CWORD=1
  CURRENT_TAB_COUNT=0
  _processCompletion noOp stubCommandCompletion noOp
  [ $CURRENT_TAB_COUNT -eq 1 ]
  _processCompletion noOp stubCommandCompletion noOp
  [ $CURRENT_TAB_COUNT -eq 2 ]
}

@test "invokes tab pressed twice function when tab has been pressed twice" {
  COMP_WORDS=("bishop" "files" "listDetails" "")
  COMP_CWORD=1
  CURRENT_TAB_COUNT=2
  _processCompletion noOp stubCommandCompletion stubTabPressedTwice
  [ "$tabbedPressedTwiceWithCurrentCommand" == "ls -al" ]
}

@test "inserts variables into commands" {
  COMP_WORDS=("bishop" "prod" "secure" "shell" "")
  COMP_CWORD=1
  _processCompletion noOp stubCommandCompletion noOp
  echo $actualCurrentCommand
  [ "$actualCurrentCommand" == "ssh -i file.id_rsa theUser@theServer" ]
}

@test "_walkJsonAndCreateVariables creates variables for all levels of the json tree" {
  COMP_WORDS=("bishop" "prod" "secure" "copy" "")
  COMP_CWORD=1
  CURRENT_TAB_COUNT=0
  _walkJsonAndCreateVariables
}

# unit
@test "_jsonSelectorAsArray builds jq json selectors given current word list" {
  COMP_WORDS=("bishop" "files" "")
  COMP_CWORD=1
  selector=($(_jsonSelectorAsArray))
  expectedArray=(".[]" ".\"files\"")
  [ $("${selector[@]}") == $("${expectedArray[@]}") ]
}

@test "_jsonSelectorAsArray copes with dashes" {
  COMP_WORDS=("bishop" "minus-test" "")
  COMP_CWORD=1
  selector=($(_jsonSelectorAsArray))
  expectedArray=(".[]" ".\"minus-test\"")
  [ $("${selector[@]}") == $("${expectedArray[@]}") ]
}

@test "_resolveCommand retrieves json object at selector position in commands file" {
   command=$(_resolveCommand ".bishop.files")
   echo $command
   [ "$command" == "{ \"ls\": \"ls\", \"listDetails\": \"ls -al\" }" ]
}

@test "_resolveCommand retrieves string when selector represents a leaf in the commands json" {
   command=$(_resolveCommand ".bishop.files.listDetails")
   [ "$command" == "ls -al" ]
}

@test "_resolveCommand returns null when no match to given selector" {
   command=$(_resolveCommand ".bishop.files.bobbins")
   [ "$command" == null ]
}

@test "_resolveCommand deals with dashes in command label" {
   command=$(_resolveCommand ".bishop.\"minus-test\"")
   [ "$command" == "ls -al" ]
}

@test "_parseJsonCommands returns non variable commands" {
   commands=$(_parseJsonCommands "{\"ls\": \"ls\", \"_variable\":\"value\"}")
   echo $commands
   [ "${commands[@]}" == "ls" ]
}

@test "_parseJsonCommands deals with underscores in command label" {
   commands=$(_parseJsonCommands "{\"ls_all\": \"ls -al\"}")
   echo $commands
   [ "${commands[@]}" == "ls_all" ]
}

@test "_parseJsonVariables returns variable commands" {
   variables=$(_parseJsonVariables "{\"ls\": \"ls\", \"_variable\":\"value\"}")
   echo $variables
   [ "$variables" == "_variable" ]
}

@test "_parseJsonVariables ignores commands with embedded underscores" {
   variables=$(_parseJsonVariables "{\"ls_all\": \"ls\", \"_variable\":\"value\"}")
   echo $variables
   [ "$variables" == "_variable" ]
}

#@test "_commandCompleted outputs command in yellow" {
#    output=$(_commandCompleted "ls -al")
#    expected=$(echo -e "\033[0;33m   <- ls -al\033[0m")
#    echo $output
#    echo $expected
#    [ "$output" == "$expected" ]
#}
