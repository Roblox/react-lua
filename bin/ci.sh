#!/bin/bash

rojo build --output model.rbxmx
roblox-cli analyze default.project.json
echo "Run tests in DEV"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true --lua.globals=__DEV__=true
echo "Run tests in release"
roblox-cli run --load.model model.rbxmx --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true
