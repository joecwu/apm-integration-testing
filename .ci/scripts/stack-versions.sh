#!/bin/bash
#
# This script get the current build versions from the artifactory,
# and process the JSON response to get one SNAPSHOT version, the two new releases (8.x), and the latest 7.x release
#

OUTPUT=${1:-"versions.json"}
SNAPSHOT=$(curl -sSL https://artifacts-api.elastic.co/v1/versions/|jq '[.versions[]|select(.|contains("SNAPSHOT")|not)][-2:] + [[.versions[]|select(.|startswith("7")|not)][-1]] + [[.versions[]|select(.|startswith("7"))][-1]]')
echo "${SNAPSHOT}"|jq .
echo "${SNAPSHOT}"|jq . > "${OUTPUT}"
