--[[
	A utility to lazy-initialize a module and all of its member functions. This
	allows us to permit cycles between modules without breaking the runtime
	entirely. The module will be initialized once one of its member functions is
	called.

	Create a LazyModule by putting the entirety of your module body inside the
	body of the first argument to the LazyModule function:

		local LazyModule = require(script.Parent.LazyModule)

		return LazyModule(function(exports)
			exports.doSomething = function()
				-- ...
			end
		end)

	You can depend on LazyModules the same way you would any standard modules.
	They're also resilient to capturing members at require time and calling them
	later:

		local MyLazyModule = require(script.Parent.MyLazyModule)
		local doSomething = MyLazyModule.doSomething

		function runProgram()
			-- This works even though it was captured when uninitialized
			doSomething()
		end

	FIXME: There is a performance cost to this trick! It's inclusion is intended
	as a temporary solution that allows us to keep our translation as close as
	possible to upstream.
]]
local function LazyModule(initializer: ({ [any]: any}) -> ())
	local ModuleTable = {}
	local initialized = false

	setmetatable(ModuleTable, {
		-- When a module's members aren't yet defined, but we still want to
		-- capture a function, we need to create a proxy function that lazily
		-- invokes the real one (once initialization is complete)
		__index = function(self, key)
			return function(...)
				if not initialized then
					initializer(self)
					initialized = true
				end

				return self[key](...)
			end
		end
	})

	return ModuleTable
end

return LazyModule