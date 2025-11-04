#!/usr/bin/env bash
# Wrapper script to launch kitty with ftz

kitty -e fish -c 'ftz; exec fish'
