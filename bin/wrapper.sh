#!/usr/bin/env bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ARGS="$@"
CFG="$(pwd)/alacritty.yml"
DEFAULT_EXEC="$(pwd)/RedTerminal.app"
EXEC="${EXEC:-$DEFAULT_EXEC}"
ARGS="${ARGS} --config-file $CFG"
cmd="$EXEC $ARGS"
2>&1 echo -e "$cmd"
exec $cmd
