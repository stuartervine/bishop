[![Build Status](https://travis-ci.org/stuartervine/bishop.svg?branch=master)](https://travis-ci.org/stuartervine/bishop)

# bishop
Bash utility to help build tab auto completing trees of commands.

To use, just checkout, wire up the commands.json and source bishop.

~~~
cd <BISHOP_CHECKOUT_DIR>
git clone git@github.com:stuartervine/bishop.git
export BISHOP_CHECKOUT_DIR=`pwd`
export BISHOP_COMMANDS_FILE=$BISHOP_CHECKOUT_DIR/example_commands.json
. bishop.sh
~~~

Typing bishop, followed by TAB will show a list of available commands.
Double tabbing will replace the bishop command with the one selected.

~~~
bishop <TAB>
bishop l<TAB><TAB>
listDetails ls
bishop ls<TAB>
bishop ls    <- ls
~~~

# Examples of command json

The command json file is pretty simple, and just represents a tree of auto completing commands, with the bottom most element holding the actual command that will execute. The top most key represents the command that will kick off the auto-completion. You can have more than one top level key, and hence can configure lots of different auto-completions from a single json file.

**A really simple example:**

~~~
cat > ./command.json <<- EOM
{
  "bishop": {
    "ls":"ls -al"
  }
}
EOM
BISHOP_COMMANDS_FILE=./command.json
. $BISHOP_CHECKOUT_DIR/bishop.sh
~~~

then 

~~~
bishop <TAB>
bishop ls  <-- ls -al
~~~

**A multi key and sub-tree example:**

~~~
cat > ./command.json <<- EOM
{
  "bishop": {
    "ls": {
        "al": "ls -al",
        "lrt": "ls -lrt"
    }
  },
  "foo": {
    "bar": "echo 'foobar!'"
  }
}
EOM
BISHOP_COMMANDS_FILE=./command.json
. $BISHOP_CHECKOUT_DIR/bishop.sh
~~~

then 

~~~
bishop <TAB>
bishop ls <TAB><TAB>
al   lrt
~~~
~~~
bishop ls a<TAB>
bishop ls al <TAB>  
bishop ls al  <-- ls -al
~~~
~~~
foo <TAB>
foo bar <ENTER>
foobar!

~~~

**Variables:**

You can specify variables to carry down the command hierarchy in the following way:

~~~
cat > ./command.json <<- 'EOM'
{
  "bishop": {
    "prod": {
        "_serverAddress": "prod.server.com",
        "login": "ssh user@${serverAddress}",
        "scp": "scp user@${serverAddress}"
    }
  }
}
EOM
BISHOP_COMMANDS_FILE=./command.json
. $BISHOP_CHECKOUT_DIR/bishop.sh
~~~

then

~~~
bishop prod login <TAB>
bishop prod login <- ssh user@prod.server.com
~~~

**Command chaining:**

You can build a command up using the levels of the json tree by using chained commands:

~~~
cat > ./command.json <<- EOM
{
  "bishop": {
    "_chainedCommand":"ssh -i my.pem",
    "prod": {
        "login": "user@awesomestuff.com"
    },
    "test": {
        "login": "testuser@test.awesomestuff.com"
    }
  }
}
EOM
BISHOP_COMMANDS_FILE=./command.json
. $BISHOP_CHECKOUT_DIR/bishop.sh
~~~

gives

~~~
bishop prod login <TAB>
bishop prod login <-- ssh -i my.pem user@awesomestuff.com
<ESC>
bishop test login <TAB>
bishop test login <-- ssh -i my.pem testuser@test.awesomestuff.com
~~~