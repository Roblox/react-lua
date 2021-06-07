#!/bin/bash

set -x

rotrieve install
rojo build tests.project.json --output model.rbxmx

echo "Remove .robloxrc from dependencies"
find Packages/_Index -name "*.robloxrc" | xargs rm -f

roblox-cli analyze tests.project.json
selene --version
selene --config selene.toml modules/ --pattern "**/*[a-bf-jl-oq-sx-z].lua"
stylua --version
stylua -c modules -g "*[a-bdh-km-oquvyz].lua"
echo "Run tests in DEV"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true --lua.globals=__DEV__=true
echo "Run tests in release"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true
