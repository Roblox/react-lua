#!/bin/bash

set -x

rojo build tests.project.json --output model.rbxmx
roblox-cli analyze tests.project.json
selene --version
selene --config selene.toml --pattern "**/*[a-bd-z].lua" modules/
echo "Run tests in DEV"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true --lua.globals=__DEV__=true
echo "Run tests in release"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true
