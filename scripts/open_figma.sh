#!/usr/bin/env bash

set -euo pipefail
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.3"
thorium-browser --user-agent="${USER_AGENT}" https://www.figma.com/files/recent
