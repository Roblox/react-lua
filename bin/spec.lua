local Root = script.Parent.RoactAlignment

-- Load RoactNavigation source into Packages folder so it's next to Roact as expected
local TestEZ = require(Root.Packages.Dev.TestEZ)

-- Run all tests, collect results, and report to stdout.
TestEZ.TestBootstrap:run(
	{ Root.Modules },
	TestEZ.Reporters.TextReporter
)

