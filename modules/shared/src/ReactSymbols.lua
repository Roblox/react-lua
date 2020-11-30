-- upstream: https://github.com/facebook/react/blob/b61174fb7b09580c1ec2a8f55e73204b706d2935/packages/shared/ReactSymbols.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ATTENTION
-- When adding new symbols to this file,
-- Please consider also adding to 'react-devtools-shared/src/backend/ReactSymbols'

local exports = {}

-- The Symbol used to tag the ReactElement-like types. If there is no native Symbol
-- nor polyfill, then a plain number is used for performance.
exports.REACT_ELEMENT_TYPE = 0xeac7
exports.REACT_PORTAL_TYPE = 0xeaca
exports.REACT_FRAGMENT_TYPE = 0xeacb
exports.REACT_STRICT_MODE_TYPE = 0xeacc
exports.REACT_PROFILER_TYPE = 0xead2
exports.REACT_PROVIDER_TYPE = 0xeacd
exports.REACT_CONTEXT_TYPE = 0xeace
exports.REACT_FORWARD_REF_TYPE = 0xead0
exports.REACT_SUSPENSE_TYPE = 0xead1
exports.REACT_SUSPENSE_LIST_TYPE = 0xead8
exports.REACT_MEMO_TYPE = 0xead3
exports.REACT_LAZY_TYPE = 0xead4
exports.REACT_BLOCK_TYPE = 0xead9
exports.REACT_SERVER_BLOCK_TYPE = 0xeada
exports.REACT_FUNDAMENTAL_TYPE = 0xead5
exports.REACT_SCOPE_TYPE = 0xead7
exports.REACT_OPAQUE_ID_TYPE = 0xeae0
exports.REACT_DEBUG_TRACING_MODE_TYPE = 0xeae1
exports.REACT_OFFSCREEN_TYPE = 0xeae2
exports.REACT_LEGACY_HIDDEN_TYPE = 0xeae3

-- deviation: not Symbol 4 u (for now)
-- if (typeof(Symbol) == 'function' && Symbol.for)
--   local symbolFor = Symbol.for
--   REACT_ELEMENT_TYPE = symbolFor('react.element')
--   REACT_PORTAL_TYPE = symbolFor('react.portal')
--   REACT_FRAGMENT_TYPE = symbolFor('react.fragment')
--   REACT_STRICT_MODE_TYPE = symbolFor('react.strict_mode')
--   REACT_PROFILER_TYPE = symbolFor('react.profiler')
--   REACT_PROVIDER_TYPE = symbolFor('react.provider')
--   REACT_CONTEXT_TYPE = symbolFor('react.context')
--   REACT_FORWARD_REF_TYPE = symbolFor('react.forward_ref')
--   REACT_SUSPENSE_TYPE = symbolFor('react.suspense')
--   REACT_SUSPENSE_LIST_TYPE = symbolFor('react.suspense_list')
--   REACT_MEMO_TYPE = symbolFor('react.memo')
--   REACT_LAZY_TYPE = symbolFor('react.lazy')
--   REACT_BLOCK_TYPE = symbolFor('react.block')
--   REACT_SERVER_BLOCK_TYPE = symbolFor('react.server.block')
--   REACT_FUNDAMENTAL_TYPE = symbolFor('react.fundamental')
--   REACT_SCOPE_TYPE = symbolFor('react.scope')
--   REACT_OPAQUE_ID_TYPE = symbolFor('react.opaque.id')
--   REACT_DEBUG_TRACING_MODE_TYPE = symbolFor('react.debug_trace_mode')
--   REACT_OFFSCREEN_TYPE = symbolFor('react.offscreen')
--   REACT_LEGACY_HIDDEN_TYPE = symbolFor('react.legacy_hidden')
-- end

-- devcation: short circuit for now
--local MAYBE_ITERATOR_SYMBOL = false -- devation: typeof(Symbol) == 'function' and Symbol.iterator
--local FAUX_ITERATOR_SYMBOL = '@@iterator'

type Iterator<T> = {
	next: () -> {
		value: T,
		done: boolean,
	},
}
exports.getIteratorFn = function(maybeIterable): nil | () -> Iterator<any>
	if typeof(maybeIterable) == "table" then
		return function()
			local currentKey: any, currentValue: any
			return {
				next = function()
					currentKey, currentValue = next(maybeIterable, currentKey)
					return {
						done = currentValue == nil,
						value = currentValue,
					}
				end,
			}
		end
	end

	return nil
end

return exports
