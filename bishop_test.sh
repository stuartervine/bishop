#!/bin/bash

BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh

COMP_WORDS=("bishop" "files" "")
COMP_CWORD=1
output=$(_matchingCommands)
echo ${output}
