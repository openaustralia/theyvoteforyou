#!/bin/sh

at NOW >/dev/null 2>/dev/null <<EOF
/home/publicwhip/publicwhip/build/dailyupdate
EOF

cat <<EOF
Content-Type: text/plain

Job scheduled.
EOF

