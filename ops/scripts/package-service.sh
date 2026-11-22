#!/usr/bin/env bash
# Build real application sources only; runtime fixture is never selected here.
set -euo pipefail
: "${1:?Usage: package-service.sh service-directory image-tag}"
: "${2:?Pass an explicit local image tag}"
root=$(cd "$(dirname "$0")/../.." && pwd)
source_dir=$(realpath "$1")
case "$source_dir/" in "$root/ops/"*|"$root/.git/"*) echo 'Not an application directory'; exit 2;; "$root/"*) ;; *) echo 'Directory must be inside this checkout'; exit 2;; esac
cd "$source_dir"
if [ -f pom.xml ]; then
  if [ -x ./mvnw ]; then ./mvnw -B verify; else mvn -B verify; fi
  jar_dir=target
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  if [ -x ./gradlew ]; then ./gradlew clean build --no-daemon; else gradle clean build --no-daemon; fi
  jar_dir=build/libs
else
  echo 'No Maven/Gradle application build exists here'; exit 2
fi
mapfile -t jars < <(find "$jar_dir" -maxdepth 1 -type f -name '*.jar' ! -name '*-plain.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar')
test "${#jars[@]}" -eq 1 || { echo 'Expected exactly one executable jar, configure the service build'; exit 2; }
jar_path=$(realpath --relative-to="$root" "${jars[0]}")
cd "$root"
docker build --pull --file ops/java/Dockerfile --build-arg "JAR_FILE=$jar_path" --tag "$2" .
