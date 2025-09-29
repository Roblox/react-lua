--!strict
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent

local ReactGlobals = require(Packages.ReactGlobals)
local Shared = require(Packages.Shared)
local ReactSymbols = Shared.ReactSymbols
local ReactTypes = Shared

local function IS_BINDING(value: unknown): boolean
	-- stylua: ignore
	return type(value) == "table"
		and	value["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
end

local ReactBinding = {}

-- stylua: ignore
local bindingPrototype = {} do
	bindingPrototype["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE
	bindingPrototype.__index = bindingPrototype

	function bindingPrototype.__tostring(binding)
		return `RoactBinding({binding:getValue()})`
	end

	function bindingPrototype._subscribe(binding, callback)
		local callbacks = binding._callbacks
		local callbackState = callbacks[callback]

		if binding._firing and callbackState then
			callbacks[callback] = false
		elseif callbackState == nil then
			callbacks[callback] = true
		end

		return function()
			callbacks[callback] = nil
		end
	end

	function bindingPrototype.getValue(binding)
		return binding._value
	end

	function ReactBinding.create<T>(initialValue: T): (
		ReactTypes.ReactBinding<T>,
		ReactTypes.ReactBindingUpdater<T>
	)
		local callbacks = {}
		local source

		if ReactGlobals.__DEV__ then
			-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
			source = debug.traceback("Binding created at:", 3)
		end

		local binding = {
			_callbacks = callbacks,
			_value = initialValue,
			_source = source,
			_firing = false,
		}

		local function update<T>(newValue: T)
			binding._value = newValue

			binding._firing = true
			for callback, notSuspended in callbacks do
				if notSuspended then
					callback(newValue)
				else
					callbacks[callback] = false
				end
			end
			binding._firing = false
		end

		binding.update = update

		return setmetatable(binding, bindingPrototype) :: any, update
	end
end

do -- map binding
	local mapBindingPrototype = setmetatable({}, bindingPrototype)
	mapBindingPrototype.__index = mapBindingPrototype

	function mapBindingPrototype.getValue(mapBinding)
		return mapBinding._predicate(mapBinding._upstreamBinding:getValue())
	end

	function mapBindingPrototype._subscribe(mapBinding, callback)
		local predicate = mapBinding._predicate

		return mapBinding._upstreamBinding:_subscribe(function(newValue)
			callback(predicate(newValue))
		end)
	end

	function mapBindingPrototype.update()
		error("Bindings created by Binding:map() cannot be updated directly", 2)
	end

	local function mapBinding<T, U>(
		upstreamBinding: ReactTypes.ReactBinding<T>,
		predicate: (T) -> U
	): ReactTypes.ReactBinding<U>
		local source

		if ReactGlobals.__DEV__ then
			-- ROBLOX TODO: More informative error messages here
			assert(
				IS_BINDING(upstreamBinding),
				"Expected 'upstreamBinding' to be of type 'Binding'"
			)
			assert(type(predicate) == "function", "Expected 'predicate' to be a function")

			-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
			source = debug.traceback("Mapped binding created at:", 3)
		end

		return setmetatable({
			_upstreamBinding = upstreamBinding,
			_predicate = predicate,
			_source = source,
		}, mapBindingPrototype) :: any
	end

	function bindingPrototype.map(binding, predicate)
		return mapBinding(binding, predicate)
	end

	ReactBinding.map = mapBinding
	table.freeze(mapBindingPrototype)
	table.freeze(bindingPrototype)
end

do -- join
	local function getValueJoin(
		upstreamBindings: { [string | number]: ReactTypes.ReactBinding<any> }
	): { [string | number]: any }
		local value = {}

		for key, upstream in upstreamBindings do
			value[key] = upstream:getValue()
		end

		return value
	end

	local joinBindingPrototype = setmetatable({}, bindingPrototype)
	joinBindingPrototype.__index = joinBindingPrototype

	function joinBindingPrototype.getValue(joinBinding)
		return getValueJoin(joinBinding._upstreamBindings)
	end

	function joinBindingPrototype._subscribe(joinBinding, callback)
		local upstreamBindings = joinBinding._upstreamBindings
		local disconnects = {} :: { () -> () }

		for key, upstream in upstreamBindings do
			table.insert(disconnects, upstream:_subscribe(function(newValue)
				callback(getValueJoin(upstreamBindings))
			end))
		end

		return function()
			for _, disconnect in disconnects do
				disconnect()
			end
		end
	end

	function joinBindingPrototype.update()
		error("Bindings created by React.joinBindings() cannot be updated directly", 2)
	end

	-- The `join` API is used statically, so the input will be a table with values
	-- typed as the public Binding type
	function ReactBinding.join<T>(
		upstreamBindings: { [string | number]: ReactTypes.ReactBinding<any> }
	): ReactTypes.ReactBinding<T>
		local source

		if ReactGlobals.__DEV__ then
			assert(
				type(upstreamBindings) == "table",
				"Expected arg #1 to be of type table"
			)

			for key, value in upstreamBindings do
				if IS_BINDING(value) then
					continue
				end

				error(
					`Expected table 'upstreamBindings' to contain only bindings, but key "{key}" had a non-binding value`,
					2
				)
			end

			-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
			source = debug.traceback("Joined binding created at:", 2)
		end

		return setmetatable({
			_upstreamBindings = upstreamBindings,
			_source = source,
		}, joinBindingPrototype) :: any
	end

	table.freeze(joinBindingPrototype)
end

return table.freeze(ReactBinding)
