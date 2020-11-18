-- upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/__tests__/ReactNoopRendererAct-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @jest-environment node
 ]]

-- sanity tests for ReactNoop.act()

return function()
	local React = require('react')
	local ReactNoop = require('react-noop-renderer')
	local Scheduler = require('scheduler')

	it('can use act to flush effects', function()
		local expect: any = expect
		function App(props)
			React.useEffect(props.callback)
			return nil
		end

		local calledLog = {}
		ReactNoop.act(function()
			ReactNoop.render(
				React.createElement(App, {
					callback = function()
						table.insert(calledLog, #calledLog)
					end,
				})
			)
		end)
		expect(Scheduler).toFlushWithoutYielding()
		expect(calledLog).toEqual({0})
	end)

	-- it('should work with async/await', function()
	-- 	function App()
	-- 		local [ctr, setCtr] = React.useState(0)
	-- 		async function someAsyncFunction()
	-- 			Scheduler.unstable_yieldValue('stage 1')
	-- 			await nil
	-- 			Scheduler.unstable_yieldValue('stage 2')
	-- 			await nil
	-- 			setCtr(1)
	-- 		end
	-- 		React.useEffect(() => {
	-- 			someAsyncFunction()
	-- 		}, [])
	-- 		return ctr
	-- 	end
	-- 	await ReactNoop.act(async () => {
	-- 		ReactNoop.render(<App />)
	-- 	})
	-- 	expect(Scheduler).toHaveYielded(['stage 1', 'stage 2'])
	-- 	expect(Scheduler).toFlushWithoutYielding()
	-- 	expect(ReactNoop.getChildren()).toEqual([{text: '1', hidden: false}])
	-- })
end
