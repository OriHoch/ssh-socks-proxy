#!/usr/bin/env bash

if [ -f "./${1}.sh" ]; then
    "./${1}.sh"
else
    bash
fi
