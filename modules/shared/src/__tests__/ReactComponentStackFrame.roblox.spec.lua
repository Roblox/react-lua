return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Object = LuauPolyfill.Object
	local String = LuauPolyfill.String

	local RobloxJest = require(Packages.Dev.RobloxJest)
	local ReactComponentStackFrame = nil

	local function assertStringContains(testString, subString)
		assert(
			testString:find(subString, 1, true),
			("could not find %q in %q"):format(subString, testString)
		)
	end

	describe("describeNativeComponentFrame", function()
		local describeNativeComponentFrame

		beforeEach(function()
			RobloxJest.resetModules()

			ReactComponentStackFrame = require(
				script.Parent.Parent.ReactComponentStackFrame
			)
			describeNativeComponentFrame =
				ReactComponentStackFrame.describeNativeComponentFrame
		end)

		it("finds the appropriate line in the stack trace", function()
			local errorMessage = "some error"

			local function FooComponent()
				error(errorMessage)
			end

			local frame = describeNativeComponentFrame(FooComponent, false)
			jestExpect(frame).toBeDefined()
			local lines = String.trim(frame):split("\n")

			jestExpect(#lines).toBe(1)
			assertStringContains(lines[1], "FooComponent")
		end)
	end)

	describe("with enableComponentStackLocations to false", function()
		beforeEach(function()
			RobloxJest.resetModules()

			local ReactFeatureFlags = require(script.Parent.Parent.ReactFeatureFlags)

			-- ROBLOX FIXME: Calling mock after require won't work
			RobloxJest.mock(script.Parent.Parent.ReactFeatureFlags, function()
				return Object.assign({}, ReactFeatureFlags, {
					enableComponentStackLocations = false,
				})
			end)

			ReactComponentStackFrame = require(
				script.Parent.Parent.ReactComponentStackFrame
			)
		end)

		describe("describeBuiltInComponentFrame", function()
			it("shows only the component name if there is no source", function()
				local componentName = "SomeComponent"
				local frame = ReactComponentStackFrame.describeBuiltInComponentFrame(
					componentName
				)
				assertStringContains(frame, componentName)
			end)

			-- deviation: cannot have a field in a function object
			-- if _G.__DEV__ then
			-- 	it("shows the owner name if there is no source", function()
			-- 		local owner = function() end
			--  	owner.displayName = "foo"
			-- 		local frame = ReactComponentStackFrame.describeBuiltInComponentFrame(
			-- 			"FooComponent",
			-- 			nil,
			-- 			owner
			-- 		)
			-- 		assertStringContains(
			-- 			frame
			-- 			"created by " .. owner.displayName,
			-- 		)
			-- 	end)
			-- end

			local fileNames = {
				[""] = "",
				["/"] = "",
				["\\"] = "",
				Foo = "Foo",
				["Bar/Foo"] = "Foo",
				["Bar\\Foo"] = "Foo",
				["Baz/Bar/Foo"] = "Foo",
				["Baz\\Bar\\Foo"] = "Foo",
				["Foo.lua"] = "Foo.lua",
				["/Foo.lua"] = "Foo.lua",
				["\\Foo.lua"] = "Foo.lua",
				["Bar/Foo.lua"] = "Foo.lua",
				["Bar\\Foo.lua"] = "Foo.lua",
				["/Bar/Foo.lua"] = "Foo.lua",
				["\\Bar\\Foo.lua"] = "Foo.lua",
				["Bar/Baz/Foo.lua"] = "Foo.lua",
				["Bar\\Baz\\Foo.lua"] = "Foo.lua",
				["/Bar/Baz/Foo.lua"] = "Foo.lua",
				["\\Bar\\Baz\\Foo.lua"] = "Foo.lua",
				["C:\\funny long (path)/Foo.lua"] = "Foo.lua",
				["init.lua"] = "init.lua",
				["/init.lua"] = "init.lua",
				["\\init.lua"] = "init.lua",
				["Bar/init.lua"] = "Bar/init.lua",
				["Bar\\init.lua"] = "Bar/init.lua",
				["/Bar/init.lua"] = "Bar/init.lua",
				["\\Bar\\init.lua"] = "Bar/init.lua",
				["Bar/Baz/init.lua"] = "Baz/init.lua",
				["Bar\\Baz\\init.lua"] = "Baz/init.lua",
				["/Bar/Baz/init.lua"] = "Baz/init.lua",
				["\\Bar\\Baz\\init.lua"] = "Baz/init.lua",
				["C:\\funny long (path)/init.lua"] = "funny long (path)/init.lua",
			}

			local lineNumber = 0
			for fileName, expectedFileName in pairs(fileNames) do
				lineNumber = lineNumber + 1

				it(("converts the file name %q"):format(fileName), function()
					local owner = nil
					local componentName = "SomeComponent"
					local frame = ReactComponentStackFrame.describeBuiltInComponentFrame(
						componentName,
						{
							fileName = fileName,
							lineNumber = lineNumber,
						},
						owner
					)

					if _G.__DEV__ then
						assertStringContains(
							frame,
							("%s (at %s:%s)"):format(
								componentName,
								expectedFileName,
								lineNumber
							)
						)
					else
						assertStringContains(frame, componentName)
					end
				end)
			end
		end)
	end)

	describe("with enableComponentStackLocations to true", function()
		local describeBuiltInComponentFrame

		beforeEach(function()
			RobloxJest.resetModules()

			local ReactFeatureFlags = require(script.Parent.Parent.ReactFeatureFlags)

			-- ROBLOX FIXME: Calling mock after require won't work
			RobloxJest.mock(script.Parent.Parent.ReactFeatureFlags, function()
				return Object.assign({}, ReactFeatureFlags, {
					enableComponentStackLocations = true,
				})
			end)

			ReactComponentStackFrame = require(
				script.Parent.Parent.ReactComponentStackFrame
			)
			describeBuiltInComponentFrame =
				ReactComponentStackFrame.describeBuiltInComponentFrame
		end)

		describe("describeBuiltInComponentFrame", function()
			it("has the component name", function()
				local componentName = "foo"
				local frame = describeBuiltInComponentFrame(componentName, {
					fileName = "file name",
					lineNumber = 7,
				}, nil)

				assertStringContains(frame, componentName)
			end)

			it("does not have the file name", function()
				local componentName = "foo"
				local fileName = "file name"
				local frame = describeBuiltInComponentFrame(componentName, {
					fileName = fileName,
					lineNumber = 7,
				}, nil)

				jestExpect(frame:find(fileName)).never.toBeDefined()
			end)
		end)
	end)
end
