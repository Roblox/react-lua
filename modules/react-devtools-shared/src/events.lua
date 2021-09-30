-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/events.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  */

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = { [number]: T }
type Map<K, V> = { [K]: V }
type Function = (...any) -> ...any
type ElementType<T, U> = any
type EventListener = (...ElementType<any, string>) -> any

export type EventEmitter<Events> = {
	listenersMap: Map<string, Array<Function>>,
	-- ROBLOX TODO: function generics <Event: $Keys<Events>>(
	addListener: (
		self: EventEmitter<Events>,
		event: string,
		listener: EventListener
	) -> (),
	-- ROBLOX TODO: function generics <Event: $Keys<Events>>(
	emit: (EventEmitter<Events>, string, ...ElementType<Events, string>) -> (),
	removeAllListeners: (EventEmitter<Events>) -> (),
	-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
	removeListener: (self: EventEmitter<Events>, event: string, listener: Function) -> (),
}
local EventEmitter = {}
local EventEmitterMetatable = { __index = EventEmitter }

function EventEmitter.new()
	local self = {}
	self.listenersMap = {} :: Map<string, Array<EventListener>>

	return setmetatable(self, EventEmitterMetatable)
end

function EventEmitter:addListener(event: string, listener: EventListener): ()
	local listeners = self.listenersMap[event] :: Array<EventListener>?
	if listeners == nil then
		self.listenersMap[event] = { listener }
	else
		local index = Array.indexOf(listeners :: Array<EventListener>, listener)
		if index < 1 then
			table.insert(listeners :: Array<EventListener>, listener)
		end
	end
end

-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
function EventEmitter:emit(event: string, ...: ElementType<any, string>): ()
	local listeners = self.listenersMap[event] :: Array<EventListener>?
	if listeners ~= nil then
		if #(listeners :: Array<EventListener>) == 1 then
			-- No need to clone or try/catch
			local listener = (listeners :: Array<EventListener>)[1]
			listener(...)
		else
			local didThrow = false
			local caughtError = nil
			local clonedListeners = Array.from((listeners :: Array<EventListener>))
			for i = 1, #clonedListeners do
				local listener = clonedListeners[i]
				local ok, error_ = pcall(function(...)
					listener(...)
					return nil
				end, ...)
				if not ok then
					didThrow = true
					caughtError = error_
				end
			end
			if didThrow then
				error(caughtError)
			end
		end
	end
end

function EventEmitter:removeAllListeners(): ()
	table.clear(self.listenersMap)
end

-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
function EventEmitter:removeListener(event: string, listener: Function): ()
	local listeners = self.listenersMap[event] :: Array<EventListener>?

	if listeners ~= nil then
		local index = Array.indexOf(listeners :: Array<EventListener>, listener)

		if index >= 1 then
			Array.splice(listeners :: Array<EventListener>, index, 1)
		end
	end
end

return EventEmitter
