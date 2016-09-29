[![Build Status](https://travis-ci.org/stuartervine/bishop.svg?branch=master)](https://travis-ci.org/stuartervine/bishop)

# bishop
Bash utility to help build tab auto completing trees of commands.

To use, just checkout, wire up the commands.json and source bishop.

~~~
cd <BISHOP_CHECKOUT_DIR>
export BISHOP_COMMANDS_FILE=`pwd`/example_commands.json
. bishop.sh
bishop <TAB>
~~~

Typing bishop, followed by TAB will show a list of available commands.
Double tabbing will replace the bishop command with the one selected.

# Examples of command json

The command json file is pretty simple, and just represents a tree of auto completing commands, with the bottom most element holding the actual command that will execute.

**A really simple example:**

~~~
echo '
{
  "bishop": {
    "ls":"ls -al"
  }
}
' > command.json
BISHOP_COMMANDS_FILE=./command.json
bishop <TAB>
~~~

gives 

~~~
bishop ls  <-- ls -al
~~~

**A multi-level example:**

~~~
echo '
{
  "bishop": {
    "ls": {
        "al": "ls -al",
        "lrt": "ls -lrt"
    }
  }
}
' > command.json
BISHOP_COMMANDS_FILE=./command.json
bishop <TAB>
~~~

gives 

~~~
bishop ls
al   lrt

bishop ls a<TAB>
~~~

then gives

~~~
bishop ls al  <-- ls -al
~~~

**Variables:**

You can specify variables to carry down the command hierarchy in the following way:

~~~
echo '
{
  "bishop": {
    "prod": {
        "_serverAddress": "prod.server.com",
        "login": "ssh user@${serverAddress}",
        "scp": "scp user@${serverAddress}"
    }
  }
}
' > command.json
BISHOP_COMMANDS_FILE=./command.json
bishop prod login<TAB>
~~~

gives

~~~
bishop prod login <-- ssh user@prod.server.com
~~~
