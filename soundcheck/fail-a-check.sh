#!/bin/bash

BACKSTAGE_BACKEND="localhost:7007"

update_data() {
    ENTITY="$1"
    CHECK="$2"

    curl \
      -H 'Content-Type: application/json' \
      "${BACKSTAGE_BACKEND}/api/soundcheck/results" \
      --data @- << EOF
{
  "results": [
    {
      "entityRef": "component:default/${ENTITY}",
      "checkId": "${CHECK}",
      "state": "failed"
    }
  ]
}
EOF
}

# BIG NOTE: If editing on Windows you may get messed up line endings. Use dos2unix to fix

update_data "rainbow-drums" "jungian-journey"

update_data "sky-crime" "automated-change-control"
