-- upstream: https://github.com/facebook/react/blob/9a5576f4d263ac5d7a9462a287d1524fda3355b8/packages/shared/__tests__/ReactErrorProd-test.internal.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
--!strict

return function()
	local formatProdErrorMessage

	describe('ReactErrorProd', function()
		beforeEach(function()
			-- deviation: This modules only has pure functions, so resetting is a no
			-- op in this case
			-- jest.resetModules()
			formatProdErrorMessage = require(script.Parent.Parent.formatProdErrorMessage)
		end)

		it('should throw with the correct number of `%s`s in the URL', function()
			expect(formatProdErrorMessage(124, 'foo', 'bar')).to.equal(
				'Minified React error #124; visit ' ..
					'https://reactjs.org/docs/error-decoder.html?invariant=124&args[]=foo&args[]=bar' ..
					' for the full message or use the non-minified dev environment' ..
					' for full errors and additional helpful warnings.'
			)

			expect(formatProdErrorMessage(20)).to.equal(
				'Minified React error #20; visit ' ..
					'https://reactjs.org/docs/error-decoder.html?invariant=20' ..
					' for the full message or use the non-minified dev environment' ..
					' for full errors and additional helpful warnings.'
			)

			expect(formatProdErrorMessage(77, '<div>', '&?bar')).to.equal(
				'Minified React error #77; visit ' ..
					'https://reactjs.org/docs/error-decoder.html?invariant=77&args[]=%3Cdiv%3E&args[]=%26%3Fbar' ..
					' for the full message or use the non-minified dev environment' ..
					' for full errors and additional helpful warnings.'
			)
		end)
	end)
end
