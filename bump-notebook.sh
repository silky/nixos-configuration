#!/usr/bin/env bash

set -xe

nix flake lock --update-input haskell-hacking-notebook
./build
systemctl --user restart haskell-hacking-notebook.service
