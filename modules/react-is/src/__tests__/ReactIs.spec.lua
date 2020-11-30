-- upstream: https://github.com/facebook/react/blob/c57fe4a2c1402acdbf31ac48cfc6a6bf336c4067/react-is/src/__tests__/ReactIs-test.js
-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck

return function()
	local Workspace = script.Parent.Parent.Parent
	local ReactIs = require(Workspace.ReactIs)
	local React = require(Workspace.React.React)
	local ReactBaseClasses = require(Workspace.React.ReactBaseClasses)
	local Component = ReactBaseClasses.Component
	local PureComponent = ReactBaseClasses.PureComponent

	describe('ReactIs', function()
		it('should return nil for unknown/invalid types', function()
			expect(ReactIs.typeOf('abc')).toEqual(nil)
			expect(ReactIs.typeOf(true)).toEqual(nil)
			expect(ReactIs.typeOf(123)).toEqual(nil)
			expect(ReactIs.typeOf({})).toEqual(nil)
			expect(ReactIs.typeOf(nil)).toEqual(nil)
		end)

		it('identifies valid element types', function()
			local MyComponent = Component:extend("MyComponent")
			Component.render = function()
				return React.createElement('TextLabel')
			end

			local MyPureComponent = PureComponent:extend("MyPureComponent")
			PureComponent.render = function()
				return React.createElement('TextLabel')
			end

			local FunctionComponent = function()
				return React.createElement('TextLabel')
			end
			--const ForwardRefComponent = React.forwardRef((props, ref) =>
			--React.createElement(Component, {forwardedRef: ref, ...props}),
			--);
			--const LazyComponent = React.lazy(() => Component);
			--const MemoComponent = React.memo(Component);
			--const Context = React.createContext(false);

			expect(ReactIs.isValidElementType('TextLabel')).toEqual(true)
			expect(ReactIs.isValidElementType(MyComponent)).toEqual(true)
			expect(ReactIs.isValidElementType(MyPureComponent)).toEqual(true);
			expect(ReactIs.isValidElementType(FunctionComponent)).toEqual(true)
			--            expect(ReactIs.isValidElementType(ForwardRefComponent)).toEqual(true);
			--            expect(ReactIs.isValidElementType(LazyComponent)).toEqual(true);
			--            expect(ReactIs.isValidElementType(MemoComponent)).toEqual(true);
			--            expect(ReactIs.isValidElementType(Context.Provider)).toEqual(true);
			--            expect(ReactIs.isValidElementType(Context.Consumer)).toEqual(true);
			--if (!__EXPERIMENTAL__) {
			--let factory;
			--expect(() => {
			--factory = React.createFactory('TextLabel');
			--}).toWarnDev(
			--'Warning: React.createFactory() is deprecated and will be removed in a ' +
			--'future major release. Consider using JSX or use React.createElement() ' +
			--'directly instead.',
			--{withoutStack: true},
			--);
			--expect(ReactIs.isValidElementType(factory)).toEqual(true);
			--}
			--expect(ReactIs.isValidElementType(React.Fragment)).toEqual(true);
			--expect(ReactIs.isValidElementType(React.StrictMode)).toEqual(true);
			--expect(ReactIs.isValidElementType(React.Suspense)).toEqual(true);

			expect(ReactIs.isValidElementType(true)).toEqual(false)
			expect(ReactIs.isValidElementType(123)).toEqual(false)
			expect(ReactIs.isValidElementType({})).toEqual(false)
			expect(ReactIs.isValidElementType(nil)).toEqual(false)
			--            expect(ReactIs.isValidElementType(undefined)).toEqual(false);
			expect(
				ReactIs.isValidElementType({
					type = 'TextLabel',
					props = {},
				})
			).toEqual(false)
		end)
	end)
end
