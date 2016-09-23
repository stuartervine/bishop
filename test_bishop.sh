#!/usr/bin/env bats

BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh

@test "parses command json file" {
  COMP_WORDS=("bishop" "files" "")
  COMP_CWORD=1
  jsonSelector=$(_jsonSelector)
  output=$(_matchingCommandJson $jsonSelector)
  [ "$output" == "{ \"ls\": \"ls\", \"listDetails\": \"ls -al\" }" ]
}


echo ${output}
