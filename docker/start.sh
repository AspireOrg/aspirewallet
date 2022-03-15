#!/bin/bash

# If working from a bare source checkout, rebuild some things so that the site loads properly
if [ ! -d /aspirewallet/build ]; then
    cd /aspirewallet/src; bower --allow-root --config.interactive=false update
    cd /aspirewallet; npm update
    grunt build --dontcheckdeps
    npm run dev
    npm run build
fi
if [ ! -f /aspirewallet/aspirewallet.conf.json ]; then
    cp -a /aspirewallet/aspirewallet.conf.json.example /aspirewallet/aspirewallet.conf.json
fi
if [ ! -f /ssl_config/aspirewallet.pem ]; then
    cp -a /etc/ssl/certs/ssl-cert-snakeoil.pem /ssl_config/aspirewallet.pem
fi
if [ ! -f /ssl_config/aspirewallet.key ]; then
    cp -a /etc/ssl/private/ssl-cert-snakeoil.key /ssl_config/aspirewallet.key
fi

# Specify defaults (defaults are overridden if defined in the environment)
export REDIS_HOST=${REDIS_HOST:="redis"}
export REDIS_PORT=${REDIS_PORT:=6379}
export REDIS_DB=${REDIS_DB:=0}
export ASPIREBLOCK_HOST_MAINNET=${ASPIREBLOCK_HOST_MAINNET:="aspireblock"}
export ASPIREBLOCK_HOST_TESTNET=${ASPIREBLOCK_HOST_TESTNET:="aspireblock-testnet"}
export ASPIREBLOCK_PORT_MAINNET=${ASPIREBLOCK_PORT_MAINNET:=4100}
export ASPIREBLOCK_PORT_TESTNET=${ASPIREBLOCK_PORT_TESTNET:=14100}
export ASPIREBLOCK_PORT_MAINNET_FEED=${ASPIREBLOCK_PORT_MAINNET_FEED:=4101}
export ASPIREBLOCK_PORT_TESTNET_FEED=${ASPIREBLOCK_PORT_TESTNET_FEED:=14101}
export ASPIREBLOCK_PORT_MAINNET_CHAT=${ASPIREBLOCK_PORT_MAINNET_CHAT:=4102}
export ASPIREBLOCK_PORT_TESTNET_CHAT=${ASPIREBLOCK_PORT_TESTNET_CHAT:=14102}

VARS='$REDIS_HOST:$REDIS_PORT:$REDIS_DB:$ASPIREBLOCK_HOST_MAINNET:$ASPIREBLOCK_HOST_TESTNET:$ASPIREBLOCK_PORT_MAINNET:$ASPIREBLOCK_PORT_TESTNET:$ASPIREBLOCK_PORT_MAINNET_FEED:$ASPIREBLOCK_PORT_TESTNET_FEED:$ASPIREBLOCK_PORT_MAINNET_CHAT:$ASPIREBLOCK_PORT_TESTNET_CHAT'
envsubst "$VARS" < /aspirewallet/docker/nginx/aspirewallet.conf.template > /etc/nginx/sites-enabled/aspirewallet.conf

# Launch utilizing the SIGTERM/SIGINT propagation pattern from
# http://veithen.github.io/2014/11/16/sigterm-propagation.html
trap 'kill -TERM $PID' TERM INT
nginx -g 'daemon off;' &
# ^ maybe simplify to just be "nginx" in the future 
PID=$!
wait $PID
trap - TERM INT
wait $PID
EXIT_STATUS=$?
