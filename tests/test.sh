#!/bin/sh

# Args:
# - compose project
# - test description
runTest() {
  composeArgs="-f docker-compose.$1.test.yml -p $1"
  failed=false
  docker-compose ${composeArgs} run sut || failed=true
  $failed && docker-compose ${composeArgs} logs
  docker-compose ${composeArgs} down -v
  if $failed; then
    echo "Test failed using compose project $1: $2"
    exit 1
  fi
}

cd $(dirname $0)

runTest defaults "using defaults"

docker volume create mc-shared
trap "docker volume rm mc-shared" EXIT

export BDS_VERSION=1.14
runTest versioned "with VERSION=1.14"
export BDS_VERSION=1.16
runTest versioned "upgrading to VERSION=1.16"
