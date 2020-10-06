-- upstream: https://github.com/facebook/react/blob/2ba43edc2675380a0f2222f351475bf9d750c6a9/packages/shared/ReactInstanceMap.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

--[[*
 * `ReactInstanceMap` maintains a mapping from a public facing stateful
 * instance (key) and the internal representation (value). This allows public
 * methods to accept the user facing instance as an argument and map them back
 * to internal methods.
 *
 * Note that this module is currently shared and assumed to be stateless.
 * If this becomes an actual Map, that will break.
 ]]

--[[*
 * This API should be called `delete` but we'd have to make sure to always
 * transform these to strings for IE support. When this transform is fully
 * supported we can rename it.
 ]]

local exports = {}

exports.remove = function(key)
	key._reactInternals = nil
end

exports.get = function(key)
	return key._reactInternals
end

exports.has = function(key)
	return key._reactInternals ~= nil
end

exports.set = function(key, value)
	key._reactInternals = value
end

return exports
