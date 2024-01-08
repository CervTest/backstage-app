#!/bin/bash

#BACKSTAGE_BACKEND="localhost:7007"
BACKSTAGE_BACKEND="https://backstage.terasology.io"

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
      "state": "passed"
    }
  ]
}
EOF
}

# BIG NOTE: If editing on Windows you may get messed up line endings. Use dos2unix to fix

# Update data for pvc-tube-tuners
update_data "pvc-tube-tuners" "basic-head-bob"
sleep 0.1
update_data "pvc-tube-tuners" "closer-look-at-audience"
sleep 0.1
update_data "pvc-tube-tuners" "has-readme"
sleep 0.1

# Update data for rainbow-drums
update_data "rainbow-drums" "basic-head-bob"
sleep 0.1
update_data "rainbow-drums" "fist-pump"
sleep 0.1
update_data "rainbow-drums" "two-armed-yell"
sleep 0.1
update_data "rainbow-drums" "hands-in-the-air"
sleep 0.1

# Update data for cereal-munchers
update_data "cereal-munchers" "basic-head-bob"
sleep 0.1
update_data "cereal-munchers" "closer-look-at-audience"
sleep 0.1
update_data "cereal-munchers" "has-readme"
sleep 0.1
update_data "cereal-munchers" "fist-pump"
sleep 0.1
update_data "cereal-munchers" "two-armed-yell"
sleep 0.1
update_data "cereal-munchers" "hands-in-the-air"
sleep 0.1
update_data "cereal-munchers" "raise-the-roof"
sleep 0.1
update_data "cereal-munchers" "head-leg-stretch"
sleep 0.1
update_data "cereal-munchers" "jungian-journey"
sleep 0.1

# Update data for sky-studios
update_data "sky-studios" "has-readme"
sleep 0.1
update_data "sky-studios" "web-optimized"
sleep 0.1
update_data "sky-studios" "style-approved-logo"
sleep 0.1
update_data "sky-studios" "link-to-related-brands"
sleep 0.1

# Update data for sky-crime
update_data "sky-crime" "has-readme"
sleep 0.1
update_data "sky-crime" "web-optimized"
sleep 0.1
update_data "sky-crime" "style-approved-logo"
sleep 0.1
update_data "sky-crime" "cdn-enabled"
sleep 0.1
update_data "sky-crime" "vulnerability-scanned"
sleep 0.1

# Update data for sky-nature
update_data "sky-nature" "has-readme"
sleep 0.1
update_data "sky-nature" "style-approved-logo"
sleep 0.1
update_data "sky-nature" "link-to-related-brands"
sleep 0.1
update_data "sky-nature" "web-optimized"
sleep 0.1
update_data "sky-nature" "cdn-enabled"
sleep 0.1
update_data "sky-nature" "vulnerability-scanned"
sleep 0.1
update_data "sky-nature" "mobile-optimized"
sleep 0.1
update_data "sky-nature" "seo-optimized"
sleep 0.1
update_data "sky-nature" "automated-change-control"
