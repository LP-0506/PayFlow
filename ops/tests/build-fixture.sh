#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p ops/tests/fixture-out
javac --release 21 --add-modules jdk.httpserver -d ops/tests/fixture-out ops/tests/RuntimeFixture.java
jar --create --file ops/tests/fixture-out/runtime.jar --main-class RuntimeFixture -C ops/tests/fixture-out RuntimeFixture.class
