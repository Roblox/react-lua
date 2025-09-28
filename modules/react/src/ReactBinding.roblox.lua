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

type AnyBinding<T> = Binding<T> | MapBinding<T>

type BindingPrototype<B, T> = {
	__subscribe: (binding: B, f: (value: T) -> ()) -> (() -> ()),
	__tostring: (binding: B) -> string,
	update: (binding: B, newValue: T) -> (),
	getValue: (binding: B) -> T,

	["$$typeof"]: typeof(ReactSymbols.REACT_BINDING_TYPE),
	__index: BindingPrototype<B, T>,
}

type BaseInheritedBindingPrototype<B, T, U, GV> = typeof(setmetatable({} :: {
	getValue: GV,
	update: U,
}, {} :: BindingPrototype<B, T>))

type BaseInheritedBinding<B, T, U, GV, UB, P, V> = typeof(setmetatable({} :: {
	__upstreamBindings: UB,
	__source: string?,
	__predicate: P,
	value: V,
}, ({} :: any) :: BaseInheritedBindingPrototype<B, T, U, GV>))



type Binding<T> = typeof(setmetatable({} :: {
	__source: string?,
	value: T,
}, {} :: BindingPrototype<Binding<T>, T>))

-- ROBLOX FIXME: correct MapBindingPrototype type that currently doesn't work because of recursive type restriction
-- type MapBindingPrototype<U, T = any> = typeof(setmetatable({} :: {
--    update: (mapBinding: MapBinding<U, T>) -> never,
--    getValue: (MapBinding: MapBinding<U, T>) -> U,
-- }, {} :: BindingPrototype<U>))
type MapBindingPrototype<U> = typeof(setmetatable({} :: {
	update: (mapBinding: MapBinding<U>) -> never,
	getValue: (MapBinding: MapBinding<U>) -> U,
}, {} :: BindingPrototype<U>))

-- ROBLOX FIXME: correct MapBinding type that currently doesn't work because of recursive type restriction
-- type MapBinding<T, U = any> = typeof(setmetatable({} :: {
--     __upstreamBinding:  Binding<T> | MapBinding<any, T>,
--     __predicate: (value: T) -> U,
--     __source: string?,
-- }, {} :: MapBindingPrototype<T, U>))
type MapBinding<U> = typeof(setmetatable({} :: {
	__upstreamBinding: Binding<any> | MapBinding<any> | JoinBinding<any>,
	__predicate: (value: any) -> U,
	__source: string?,
}, {} :: MapBindingPrototype<U>))

type JoinBindingPrototype<T> = typeof(setmetatable({} :: {
	update: (mapBinding: JoinBinding<T>) -> never,
}, {} :: BindingPrototype<T>))

type JoinBinding<T> = typeof(setmetatable({} :: {
	__upstreamBindings: { [string | number]: Binding<any> | JoinBinding<any> | MapBinding<any> }
}, {} :: BindingPrototype<T>))

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

-- stylua: ignore
local bindingPrototype = {} do
	bindingPrototype["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE
	bindingPrototype.__index = bindingPrototype

	function bindingPrototype.__tostring(binding)
		return `RoactBinding({binding:getValue()})`
	end

	function bindingPrototype.__subscribe(binding, callback)
		return binding.__subscribe(callback)
	end

	function bindingPrototype.update(binding, newValue)
		binding.value = newValue
		binding.__fire(newValue)
	end

	function bindingPrototype.getValue(binding)
		return binding.value
	end

	function ReactBinding.create<T>(initialValue: T): (Binding<T>, BindingUpdater<T>)
		local subscribe, fire = createSignal()
		local source

		if ReactGlobals.__DEV__ then
			-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
			source = debug.traceback("Binding created at:", 3)
		end

		local binding = setmetatable({
			__subscribe = subscribe,
			value = initialValue,
			__source = source,
			__fire = fire,
		}, bindingPrototype)

		local function setAndFire(newValue)
			binding.value = newValue
			fire(newValue)
		end

		return binding, setAndFire
	end

end

do -- map binding
	local mapBindingPrototype = setmetatable({}, bindingPrototype)
	mapBindingPrototype.__index = mapBindingPrototype

	function mapBindingPrototype.getValue(mapBinding)
		return mapBinding.__predicate(mapBinding.__upstreamBinding:getValue())
	end

	function mapBindingPrototype.__subscribe(mapBinding, callback)
		local predicate = mapBinding.__predicate

		return mapBinding.__upstreamBinding:__subscribe(function(newValue)
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
			__upstreamBinding = upstreamBinding,
			__predicate = predicate,
			__source = source,
		}, mapBindingPrototype)
	end

	function BASE_BINDING_PROTOTYPE.map(baseBinding, predicate)
		return mapBinding(baseBinding, predicate)
	end

	ReactBinding.map = mapBinding
	table.freeze(mapBindingPrototype)
	table.freeze(bindingPrototype)
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

	local joinBindingPrototype = setmetatable({}, bindingPrototype)
	joinBindingPrototype.__index = joinBindingPrototype

	function joinBindingPrototype.getValue(joinBinding)
		return getValueJoin(joinBinding.__upstreamBindings)
	end

	function joinBindingPrototype.__subscribe(joinBinding, callback)
		local upstreamBindings = joinBinding.__upstreamBindings
		local disconnects: any = {}

		for key, upstream in upstreamBindings do
			disconnects[key] = upstream:__subscribe(function(newValue)
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
			__upstreamBindings = upstreamBindings,
			__source = source,
		}, joinBindingPrototype)
	end

	table.freeze(joinBindingPrototype)
end

return table.freeze(ReactBinding)
