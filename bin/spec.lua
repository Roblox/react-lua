local Root = script.Parent.RoactAlignment
local ProcessService = game:GetService("ProcessService")

-- Load RoactNavigation source into Packages folder so it's next to Roact as expected
local JestRoblox = require(Root.Packages.Dev.JestRoblox)
local RobloxJest = require(Root.Packages.Modules.RobloxJest)

-- Run all tests, collect results, and report to stdout.
local result = JestRoblox.TestBootstrap:run(
	{ Root.Packages.Modules },
	JestRoblox.Reporters.TextReporterQuiet,
	{ extraEnvironment = RobloxJest.testEnv }
)

if result.failureCount == 0 and #result.errors == 0 then
	ProcessService:ExitAsync(0)
end

ProcessService:ExitAsync(1)
return