# bishop
Bash utility to help build auto completing trees of commands.

To use, just checkout, wire up the commands.json and source bishop.

~~~
cd <BISHOP_CHECKOUT_DIR>
export BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh
bishop <TAB>
~~~

Test build
