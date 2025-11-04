#!/usr/bin/env bash
# Wrapper script to launch kitty with ftz on macOS

kitty --single-instance -e fish -c 'ftz; exec fish'
