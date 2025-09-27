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

local createSignal = require(script.Parent["createSignal.roblox"])
local ReactGlobals = require(Packages.ReactGlobals)
local ReactSymbols = require(Packages.Shared).ReactSymbols
local ReactTypes = require(Packages.Shared)

-- stylua: ignore
local BASE_BINDING_PROTOTYPE = {} do
	BASE_BINDING_PROTOTYPE["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE
	BASE_BINDING_PROTOTYPE.__index = BASE_BINDING_PROTOTYPE

	function BASE_BINDING_PROTOTYPE.__tostring(baseBinding)
		return `RoactBinding({baseBinding:getValue()})`
	end
end

local function IS_BINDING(value: unknown): boolean
	-- stylua: ignore
	return type(value) == "table"
		and	value["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
end

local ReactBinding = {}

do -- create
	local bindingPrototype = setmetatable({}, BASE_BINDING_PROTOTYPE)
	bindingPrototype.__index = bindingPrototype

	function bindingPrototype.update(binding, newValue)
		binding.value = newValue
		binding._fire(newValue)
	end

	function bindingPrototype.getValue(binding)
		return binding.value
	end

	function bindingPrototype.subscribe(binding, callback)
		return binding._subscribe(callback)
	end

	function ReactBinding.create<T>(initialValue: T): (Binding<T>, BindingUpdater<T>)
		local subscribe, fire = createSignal()
		local source

		if ReactGlobals.__DEV__ then
			-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
			source = debug.traceback("Binding created at:", 3)
		end

		local binding = setmetatable({
			_subscribe = subscribe,
			value = initialValue,
			_source = source,
			_fire = fire,
		}, bindingPrototype)

		local function setAndFire(newValue)
			binding.value = newValue
			fire(newValue)
		end

		return binding, setAndFire
	end

	table.freeze(bindingPrototype)
end

do -- map binding
	local mapBindingPrototype = setmetatable({}, BASE_BINDING_PROTOTYPE)
	mapBindingPrototype.__index = mapBindingPrototype

	function mapBindingPrototype.getValue(mapBinding)
		return mapBinding._predicate(mapBinding._upstreamBinding:getValue())
	end

	function mapBindingPrototype.subscribe(mapBinding, callback)
		local predicate = mapBinding._predicate

		return mapBinding._upstreamBinding:subscribe(function(newValue)
			callback(predicate(newValue))
		end)
	end

	function mapBindingPrototype.update()
		error("Bindings created by Binding:map() cannot be updated directly", 2)
	end

	local function mapBinding<T, U>(
		upstreamBinding: BindingInternal<T>,
		predicate: (T) -> U
	): MapBinding<U>
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
		}, mapBindingPrototype)
	end

	function BASE_BINDING_PROTOTYPE.map(baseBinding, predicate)
		return mapBinding(baseBinding, predicate)
	end

	ReactBinding.map = mapBinding
	table.freeze(mapBindingPrototype)
	table.freeze(BASE_BINDING_PROTOTYPE)
end

do -- join
	local function getValueJoin(
		upstreamBindings: { [string | number]: Binding<any> }
	): { [string | number]: any }
		local value = {}

		for key, upstream in upstreamBindings do
			value[key] = upstream:getValue()
		end

		return value
	end

	local joinBindingPrototype = setmetatable({}, BASE_BINDING_PROTOTYPE)
	joinBindingPrototype.__index = joinBindingPrototype

	function joinBindingPrototype.getValue(joinBinding)
		return getValueJoin(joinBinding._upstreamBindings)
	end

	function joinBindingPrototype.subscribe(joinBinding, callback)
		local upstreamBindings = joinBinding._upstreamBindings
		local disconnects: any = {}

		for key, upstream in upstreamBindings do
			disconnects[key] = upstream:subscribe(function(newValue)
				callback(getValueJoin(upstreamBindings))
			end)
		end

		return function()
			if not disconnects then
				return
			end

			for _, disconnect in disconnects do
				disconnect()
			end
			disconnects = nil
		end
	end

	function joinBindingPrototype.update()
		error("Bindings created by React.joinBindings() cannot be updated directly", 2)
	end

	-- The `join` API is used statically, so the input will be a table with values
	-- typed as the public Binding type
	function ReactBinding.join<T>(
		upstreamBindings: { [string | number]: Binding<any> }
	): Binding<T>
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
		}, joinBindingPrototype)
	end

	table.freeze(joinBindingPrototype)
end

return table.freeze(ReactBinding)
