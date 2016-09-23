#!/usr/bin/env bats

BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh

function verifyOutput() {
    echo "Also here"
    echo $@
}

COMP_WORDS=("bishop" "files" "")
COMP_CWORD=1
#  jsonSelector=$(_jsonSelector)
_processCompletion verifyOutput verifyOutput verifyOutput

#@test "parses command json file" {
#  COMP_WORDS=("bishop" "files" "")
#  COMP_CWORD=1
##  jsonSelector=$(_jsonSelector)
#  output=$(_complete)
#  echo $output
##  [ "$output" == "{ \"ls\": \"ls\", \"listDetails\": \"ls -al\" }" ]
#}