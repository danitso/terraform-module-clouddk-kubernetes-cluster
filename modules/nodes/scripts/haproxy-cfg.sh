#!/bin/bash
# Retrieve and parse the arguments.
if (( "$#" < 8 )); then
    echo "Usage: $0 <listener-addresses> <listener-ports> <listener-timeouts> <target-addresses> <target-ports> <target-timeouts> <username> <password>" 1>&2
    exit 1
fi

IFS=' ' read -ra LISTENER_ADDRESSES <<< "$1"
IFS=' ' read -ra LISTENER_PORTS <<< "$2"
IFS=' ' read -ra LISTENER_TIMEOUTS <<< "$3"
IFS=' ' read -ra TARGET_ADDRESSES <<< "$4"
IFS=' ' read -ra TARGET_PORTS <<< "$5"
IFS=' ' read -ra TARGET_TIMEOUTS <<< "$6"

USERNAME="$7"
PASSWORD="$8"

# Validate the arguments to reduce the risk of introducing configuration errors.
LISTENER_COUNT="${#LISTENER_ADDRESSES[@]}"
TARGET_COUNT="${#TARGET_ADDRESSES[@]}"

if [[ "$LISTENER_COUNT" != "$TARGET_COUNT" ]]; then
    echo "ERROR: The number of listeners does not match the number of targets" 1>&2
    exit 1
fi

# Retrieve some system information.
MEMORY_TOTAL="$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024 )}' /proc/meminfo)"

if (( MEMORY_TOTAL < 1 )); then
    MEMORY_TOTAL=1
fi

PROCESSOR_COUNT="$(nproc)"

# Generate some additional information.
CONNECTION_LIMIT="$((MEMORY_TOTAL * 1000 * PROCESSOR_COUNT / LISTENER_COUNT / PROCESSOR_COUNT))"

# Generate the configuration file and output it to STDOUT.
cat << EOF
global
    log                         /dev/log local0 info alert
    log                         /dev/log local1 notice alert

    chroot                      /var/lib/haproxy

    stats                       socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats                       timeout 30s

    user                        haproxy
    group                       haproxy

    ca-base                     /etc/ssl/certs
    crt-base                    /etc/ssl/private

    ssl-default-bind-ciphers    ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
    ssl-default-bind-options    no-sslv3

    nbproc                      $((PROCESSOR_COUNT))
    nbthread                    2

EOF

SEQUENCE="$(seq 1 1 "$PROCESSOR_COUNT")"

for i in $SEQUENCE; do
cat << EOF
    cpu-map                     $i $i
EOF
done

cat << EOF

defaults
    log                         global
    mode                        tcp

    maxconn                     ${CONNECTION_LIMIT}

listen stats
    mode                        http
    log                         global

    maxconn                     16

    timeout                     client 100s
    timeout                     connect 100s
    timeout                     server 100s

    timeout                     queue 100s

    stats                       enable
    stats                       hide-version
    stats                       refresh 30s
    stats                       show-node
    stats                       auth ${USERNAME}:${PASSWORD}
    stats                       uri /load-balancer-stats

    bind                        0.0.0.0:61200
EOF

SEQUENCE="$(seq 0 1 $((LISTENER_COUNT - 1)))"

for i in $SEQUENCE; do
cat << EOF

listen lb$((i + 1))-${LISTENER_PORTS[$i]}-${TARGET_PORTS[$i]}
    option                      tcplog
    option                      tcp-check

    timeout                     check 5s
    timeout                     client ${LISTENER_TIMEOUTS[$i]}s
    timeout                     connect 5s
    timeout                     server ${TARGET_TIMEOUTS[$i]}s

    balance                     roundrobin

    bind                        ${LISTENER_ADDRESSES[$k]}:${LISTENER_PORTS[$i]}

EOF

    IFS=',' read -ra addresses <<< "${TARGET_ADDRESSES[$i]}"

    for k in "${!addresses[@]}"; do
cat << EOF
    server                      ${addresses[$k]}:${TARGET_PORTS[$i]} ${addresses[$k]}:${TARGET_PORTS[$i]} maxconn ${CONNECTION_LIMIT} check inter 5 fall 3 rise 2
EOF
    done
done
