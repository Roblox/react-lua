-- upstream: https://github.com/facebook/react/blob/3e94bce765d355d74f6a60feb4addb6d196e3482/packages/shared/__tests__/ReactErrorUtils-test.internal.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
--!nolint UnknownGlobal
--!nocheck

return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local Error = require(Workspace.JSPolyfill.Error)

	local invokeGuardedCallbackImpl = require(script.Parent.Parent.invokeGuardedCallbackImpl)
	local ReactErrorUtilsModule = require(script.Parent.Parent.ReactErrorUtils)
	local ReactErrorUtils

	-- deviation: FIXME: add arrays polyfill w/ push/pop/shift/etc.
	local push = function(list, value)
		list[#list + 1] = value
	end

	describe('ReactErrorUtils', function()
		beforeEach(function()
			-- TODO: can we express this test with only public API?
			ReactErrorUtils = ReactErrorUtilsModule.makeWithArgs(invokeGuardedCallbackImpl)
		end)

		it('it should rethrow caught errors', function()
			local err = Error('foo')
			local callback = function()
				error(err)
			end
			ReactErrorUtils.invokeGuardedCallbackAndCatchFirstError(
				'foo',
				callback,
				nil
			)
			expect(ReactErrorUtils.hasCaughtError()).to.equal(false);
			local ok, result = pcall(function()
				return ReactErrorUtils.rethrowCaughtError()
			end)

			-- deviation: FIXME: align `toThrow` more closely
			-- deviation: FIXME: proper deep-equal comparison
			expect(ok).to.equal(false)
			expect(result.name).to.equal(err.name)
			expect(result.message).to.equal(err.message)
		end)

		it('should call the callback the passed arguments', function()
			local callback = RobloxJest.createSpy()
			ReactErrorUtils.invokeGuardedCallback(
				'foo',
				callback.value,
				nil,
				'arg1',
				'arg2'
			)
			-- deviation: In Lua, calling a function with `self` (which is the
			-- equivalent of the `context` argument used in
			-- invokeGuardedCallbackImpl) includes `self` as the first argument;
			-- we have to account for this by expecting the `nil` in addition to
			-- the two args
			callback:assertCalledWith(nil, 'arg1', 'arg2')
		end)

		it('should call the callback with the provided context', function()
			local context = { didCall = false }
			ReactErrorUtils.invokeGuardedCallback(
				'foo',
				function(self)
					self.didCall = true
				end,
				context
			)
			expect(context.didCall).to.equal(true)
		end)

		it('should catch errors', function()
			local err = Error()
			local returnValue = ReactErrorUtils.invokeGuardedCallback(
				'foo',
				function()
					error(err)
				end,
				nil,
				'arg1',
				'arg2'
			)
			expect(returnValue).to.equal(nil);
			expect(ReactErrorUtils.hasCaughtError()).to.equal(true);
			expect(ReactErrorUtils.clearCaughtError()).to.equal(err);
		end)

		it('should return false from clearCaughtError if no error was thrown', function()
			local callback = RobloxJest.createSpy()
			ReactErrorUtils.invokeGuardedCallback('foo', callback.value, nil);
			expect(ReactErrorUtils.hasCaughtError()).to.equal(false);
			local ok, result = pcall(ReactErrorUtils.clearCaughtError)

			expect(ok).to.equal(false)
			-- deviation: FIXME: align `toThrow` more closely
			expect((string.find(result.message, 'no error was captured'))).to.be.ok()
		end)

		it('can nest with same debug name', function()
			local err1 = Error()
			local err2
			local err3 = Error()
			ReactErrorUtils.invokeGuardedCallback(
				'foo',
				function()
					ReactErrorUtils.invokeGuardedCallback(
						'foo',
						function()
							error(err1)
						end,
						nil
					)
					err2 = ReactErrorUtils.clearCaughtError()
					error(err3)
				end,
				nil
			)
			local err4 = ReactErrorUtils.clearCaughtError()

			expect(err2).to.equal(err1)
			expect(err4).to.equal(err3)
		end)

		it('handles nested errors', function()
			local err1 = Error()
			local err2
			ReactErrorUtils.invokeGuardedCallback(
				'foo',
				function()
					ReactErrorUtils.invokeGuardedCallback(
						'foo',
						function()
							error(err1)
						end,
						nil
					)
					err2 = ReactErrorUtils.clearCaughtError()
				end,
				nil
			)
			-- Returns nil because inner error was already captured
			expect(ReactErrorUtils.hasCaughtError()).to.equal(false)

			expect(err2).to.equal(err1)
		end)

		it('handles nested errors in separate renderers', function()
			-- deviation: call our initializer instead of using module resetting
			local ReactErrorUtils1 = ReactErrorUtilsModule.makeWithArgs(invokeGuardedCallbackImpl);
			-- jest.resetModules();
			local ReactErrorUtils2 = ReactErrorUtilsModule.makeWithArgs(invokeGuardedCallbackImpl);
			expect(ReactErrorUtils1).never.to.equal(ReactErrorUtils2)

			local ops = {}

			ReactErrorUtils1.invokeGuardedCallback(
				nil,
				function()
					ReactErrorUtils2.invokeGuardedCallback(
						nil,
						function()
							error(Error('nested error'))
						end,
						nil
					)
					-- ReactErrorUtils2 should catch the error
					push(ops, ReactErrorUtils2.hasCaughtError())
					push(ops, ReactErrorUtils2.clearCaughtError().message)
				end,
				nil
			)

			-- ReactErrorUtils1 should not catch the error
			push(ops, ReactErrorUtils1.hasCaughtError())

			-- deviation: FIXME: add a deep-equal expectation
			expect(ops[1]).to.equal(true)
			expect(ops[2]).to.equal('nested error')
			expect(ops[3]).to.equal(false)
		end)

		if not __DEV__ then
			-- jsdom doesn't handle this properly, but Chrome and Firefox should. Test
			-- this with a fixture.
			it('catches nil values', function()
				ReactErrorUtils.invokeGuardedCallback(
					nil,
					function()
						error(nil) -- eslint-disable-line no-throw-literal
					end,
					nil
				)
				expect(ReactErrorUtils.hasCaughtError()).to.equal(true)
				expect(ReactErrorUtils.clearCaughtError()).to.equal(nil)
			end)
		end

		it('can be shimmed', function()
			local ops = {}
			-- deviation: No module resetting/mocking support
			-- jest.resetModules();
			ReactErrorUtils = ReactErrorUtilsModule.makeWithArgs(function(reporter, name, func, context, a)
				push(ops, a)
				local ok, result = pcall(function()
					func(context, a)
				end)

				if not ok then
					reporter.onError(result)
				end
			end)

			-- deviation: no need to wrap in try/finally since we don't need to
			-- undo the mock like we would with jest
			local err = Error('foo')
			local callback = function()
				error(err)
			end
			ReactErrorUtils.invokeGuardedCallbackAndCatchFirstError(
				'foo',
				callback,
				nil,
				'somearg'
			)

			-- deviation: FIXME: align `toThrow` more closely
			local ok, result = pcall(ReactErrorUtils.rethrowCaughtError)
			expect(ok).to.equal(false)
			expect(result).to.equal(err)

			expect(#ops).to.equal(1)
			expect(ops[1]).to.equal('somearg')
		end)
	end)
end
