#!/bin/sh
# Script that helps to overwrite port/secret/ad tag from command line without changing config-files

CMD="/opt/mtp_proxy/bin/mtp_proxy foreground"
THIS=$0

usage() {
    echo "Usage:"
    echo "To run with settings from config/prod-sys.config:"
    echo "${THIS}"
    echo "To start in single-port mode configured from command-line:"
    echo "${THIS} -p <port> -s <secret> -t <ad tag>"
    echo "Parameters:"
    echo "-p <port>: port to listen on. 1-65535"
    echo "-s <secret>: proxy secret. 32 hex characters 0-9 a-f"
    echo "-t <ad tag>: promo tag, that you get from @MTProxybot. 32 hex characters"
    echo "port secret and tag can also be configured via environment variables:"
    echo "MTP_PORT, MTP_SECRET, MTP_TAG"
    echo "If both command line and environment are set, command line have higher priority"
}

error() {
    echo "ERROR: ${1}"
    usage
    exit 1
}

# check environment variables
PORT=${MTP_PORT:-""}
SECRET=${MTP_SECRET:-""}
TAG=${MTP_TAG:-""}

# check command line options
while getopts "p:s:t:h" o; do
    case "${o}" in
        p)
            PORT=${OPTARG}
            ;;
        s)
            SECRET=${OPTARG}
            ;;
        t)
            TAG=${OPTARG}
            ;;
        h)
            usage
            exit 0
    esac
done

# if at least one option is set...
if [ -n "${PORT}" -o -n "${SECRET}" -o -n "${TAG}" ]; then
    # If at least one of them not set...
    [ -z "${PORT}" -o -z "${SECRET}" -o -z "${TAG}" ] && \
        error "Not enough options: -p '${PORT}' -s '${SECRET}' -t '${TAG}'"

    # validate format
    [ ${PORT} -gt 0 -a ${PORT} -lt 65535 ] || \
        error "Invalid port value: ${PORT}"
    [ -n "`echo $SECRET | grep -x '[[:xdigit:]]\{32\}'`" ] || \
        error "Invalid secret. Should be 32 chars of 0-9 a-f"
    [ -n "`echo $TAG | grep -x '[[:xdigit:]]\{32\}'`" ] || \
        error "Invalid tag. Should be 32 chars of 0-9 a-f"

    exec $CMD -mtproto_proxy ports "[#{name => mtproto_proxy, port => $PORT, secret => <<\"$SECRET\">>, tag => <<\"$TAG\">>}]"
else
    exec $CMD
fi
