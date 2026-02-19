#!/bin/bash
set -e

# # clean all services
# cleanup() {
#     echo "Stop services..."
#     service tor stop
#     service ssh stop
#     nginx -s quit
#     exit 0
# }
#
# # capture sigint 
# trap cleanup SIGTERM SIGINT

# start ssh
service ssh start
sleep 2 
if ! pgrep -x sshd > /dev/null; then
    echo "ERREUR: SSH not started"
    exit 1
fi
#
# # start tor
service tor start
sleep 2 
if ! pgrep -x tor > /dev/null; then
    echo "ERREUR: Tor not started"
    exit 1
fi

echo "SSH et Tor start with success"

# Nginx pid 1
nginx -g 'daemon off;'
