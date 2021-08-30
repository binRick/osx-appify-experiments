#!/usr/bin/env bash
set -e
def_cmd='go run -v .'
#|| { go mod tidy && go get && go run -v .; }'
cmd="${@:-$def_cmd}"
rebuild="go mod tidy && go get"
cmd="nodemon -w . --signal SIGKILL -e go,sh --delay .1 -x env bash -- -exc '$cmd||true'"

exec $cmd
