#!/usr/bin/env bash

source test_functions.sh

info "Running ssh-socks-proxy tests"

provision_test_environment && sleep 2 && ssh_socks_proxy_test
