#!/usr/bin/env bash

if [ -f "./${1}.sh" ]; then
    "./${1}.sh" $@
elif [ -f "./${1}.py" ]; then
    python "./${1}.py" $@
elif [ -f "/upv/${1}.sh" ]; then
    "/upv/${1}.sh" $@
elif [ -f "/upv/${1}.py" ]; then
    python "/upv/${1}.py" $@
else
    bash
fi
