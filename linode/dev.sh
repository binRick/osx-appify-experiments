#!/usr/bin/env bash
set -e
def_cmd='go mod tidy && go get && go run -v .'
cmd="${@:-$def_cmd}"
nodemon -w . --signal SIGKILL -e go --delay .1 -x env bash -- -exc "$cmd||true"
