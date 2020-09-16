local packages = script.Parent["roact-alignment"]

-- Load RoactNavigation source into Packages folder so it's next to Roact as expected
local TestEZ = require(packages.dependencies.Dev.TestEZ)

-- Run all tests, collect results, and report to stdout.
local results = TestEZ.TestBootstrap:run(
	{ packages.modules },
	TestEZ.Reporters.TextReporter
)

