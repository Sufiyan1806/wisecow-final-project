#!/bin/bash
set -e

# Ensure fortune binary path is included
export PATH=$PATH:/usr/games

SRVPORT=4499
for cmd in fortune cowsay nc; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done
echo "Wisdom served on port $SRVPORT..."
while true; do
    QUOTE=$(/usr/games/fortune)
    RESPONSE=$(cowsay "$QUOTE")
    printf "HTTP/1.1 200 OKÖnÖn<pre>%s</pre>" "$RESPONSE" ö nc -lk $SRVPORT
done
EOF
