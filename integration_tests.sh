#!/usr/bin/env -S nix run -c sh

export SOLR_VERSION=${SOLR_VERSION:-8.8.2}

run_tests() {
  local stop="$1"
  local output="$2"

  echo -e "\n\rRunning integration tests..."
  dotnet test SolrNet.Tests.Integration --filter 'Category=Integration' 1>$output 2>$output
  ret=$?

  if [ -n "$stop" ]; then
    echo -e "\n\rStopping Solr..."
    docker stop solr_cloud
	docker stop solr_cloud_auth
  fi
  return $ret
}

create_solr() {
  local next="$1"

  echo -e "\n\rWaiting for Solr to start..."
  until docker container inspect solr_cloud 1>/dev/null 2>/dev/null; do
    sleep 0.5
  done
  until curl -s http://localhost:8983 1>/dev/null 2>/dev/null; do
    sleep 0.5
  done

  echo -e "\n\rSetting up Solr collection and documents..."
  docker exec solr_cloud solr create_collection -c techproducts -d sample_techproducts_configs 1>/dev/null 2>/dev/null
  docker exec solr_cloud post -c techproducts 'example/exampledocs/' 1>/dev/null 2>/dev/null

  curl -s -X POST -H 'Content-type:application/json' -d '{
    "update-requesthandler": {
      "name": "/select",
      "class": "solr.SearchHandler",
      "last-components": ["spellcheck"]
    }
  }' http://localhost:8983/solr/techproducts/config >/dev/null
  
  echo -e "\n\rSolr available at http://localhost:8983\n\r"

  set -x
  $next
}

create_solr_auth() {
  local next="$1"

  echo -e "\n\rWaiting for Solr (auth) to start..."
  until docker container inspect solr_cloud 1>/dev/null 2>/dev/null; do
    sleep 0.5
  done
  until curl -s http://localhost:8984 1>/dev/null 2>/dev/null; do
    sleep 0.5
  done

  echo -e "\n\rSetting up Solr (auth) collection and documents..."
  docker exec solr_cloud_auth solr create_collection -c techproducts -d sample_techproducts_configs 1>/dev/null 2>/dev/null
  docker exec solr_cloud_auth post -c techproducts 'example/exampledocs/' 1>/dev/null 2>/dev/null

  curl -s -X POST -H 'Content-type:application/json' -d '{
    "update-requesthandler": {
      "name": "/select",
      "class": "solr.SearchHandler",
      "last-components": ["spellcheck"]
    }
  }' http://localhost:8984/solr/techproducts/config >/dev/null
  
  echo -e "\n\rSolr (auth) available at http://localhost:8984\n\r"

  set -x
  $next
}

output=$(mktemp)
trap "rm $output" EXIT

create_solr & create_solr_auth "run_tests stop $output" &
# create_solr "true" &
tests=$!

docker run --rm -p 8983:8983 --name solr_cloud solr:$SOLR_VERSION solr start -cloud -f >solr_output.txt

# output default security.json to working directory
echo '{
"authentication":{ 
   "blockUnknown": true, 
   "class":"solr.BasicAuthPlugin",
   "credentials":{"solr":"IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c="} 
},
"authorization":{
   "class":"solr.RuleBasedAuthorizationPlugin",
   "permissions":[{"name":"security-edit",
      "role":"admin"}], 
   "user-role":{"solr":"admin"} 
}}' > security.json

docker run --rm -p 8984:8984 --name solr_cloud_auth solr:$SOLR_VERSION solr start -cloud -f >solr_output_auth.txt
$authcontainerId = docker inspect -f '{{.Id}}' solr_cloud_auth
docker cp security.json $authcontainerId:/security.json
cat $output
wait $tests
