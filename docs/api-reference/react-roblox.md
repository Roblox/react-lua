# ReactRoblox

The ReactRoblox package is the entry point for any Roblox-opinionated logic. It can be thought of as the equivalent of the ReactDOM package in React JS.

However, rather than fully implementing all of the features of ReactDOM, it leaves most deprecated APIs out entirely, implementing only the modern and forward-looking portions of the API.

Notable absences are:

* `render` - Use `createRoot` (or, depending on the circumstances, `createBlockingRoot` or `createLegacyRoot`) instead
* `unmountComponentAtNode` - Use the `unmount` method on the root object returned from `createRoot` instead
* `findDOMNode` - Use [refs](https://reactjs.org/docs/refs-and-the-dom.html) instead

## ReactRoblox.createRoot
Adopted as part of the Concurrent Mode API. Refer to [`ReactDOM.createRoot` documentation](https://reactjs.org/docs/concurrent-mode-reference.html#createroot).

## ReactRoblox.createBlockingRoot
Adopted as part of the Concurrent Mode API. "Blocking" roots represent a transitional step between synchronous rendering and full concurrent rendering. Refer to [`ReactDOM.createBlockingRoot` documentation](https://reactjs.org/docs/concurrent-mode-adoption.html#migration-step-blocking-mode).

## ReactRoblox.createLegacyRoot
Adopted as part of the Concurrent Mode API. "Legacy" roots are essentially equivalent to pre-concurrent React behavior. Refer to [`ReactDOM.createLegacyRoot` documentation](https://reactjs.org/docs/concurrent-mode-adoption.html#migration-step-blocking-mode).

### Deviations
React documentation provides [a handy chart](https://reactjs.org/docs/concurrent-mode-adoption.html#feature-comparison) that explains the feature differences between the roots. This table lists three deprecated features under legacy roots only:

* [String Refs](https://reactjs.org/docs/refs-and-the-dom.html#legacy-api-string-refs)
* [Legacy Context](https://reactjs.org/docs/legacy-context.html)
* [findDOMNode](https://reactjs.org/docs/strict-mode.html#warning-about-deprecated-finddomnode-usage)

**These features were never implemented in legacy Roact, and have not been ported.** Instead, creating a Legacy Mode root simply tells Roact to render synchronously. This behavior is most similar to legacy Roact or pre-Concurrent-Mode React JS.

Generally speaking, `ReactRoblox.createRoot` should be used for all new work, while the Blocking and Legacy versions can be used for upgrading existing Roact logic in the event that it does not yet meet the requirements for Concurrent Mode.

## ReactRoblox.createPortal
Refer to [`ReactDOM.createPortal` documentation](https://reactjs.org/docs/portals.html).

<!-- Testing/globals only -->
## ReactRoblox.act
Used for testing code with scheduling logic mocked. This ensures that tests behave consistently and don't batch work unpredictably across frames. `act` executes a function and then plays forward the mock scheduler after it's done, and should be used to wrap any interactions that trigger updates to a roact UI.

More info on using `act` can be found [in the migration guide](../migrating-from-1x/adopt-new-features.md#reactrobloxact).

Refer to [ReactDOM's `act` testing documentation](https://reactjs.org/docs/test-utils.html#act) for more high-level guidance.

### Deviations
In production, `ReactRoblox.act` will not be available. Set the global value `_G.__ROACT_17_INLINE_ACT__` to `true` in order to enable this behavior in tests.

!!! info
	This behavior is still a work in progress, and there may be changes to how Roact detects whether or not it should provide the `act` function. For now, use the global `__ROACT_17_INLINE_ACT__` to enable it for tests.

## ReactRoblox.Event
*Roact-only*

Re-exports [`React.Event`](react.md#reactevent). This is only exposed for backwards compatibility; please prefer to use `React.Event`.

## ReactRoblox.Change
*Roact-only*

Re-exports [`React.Change`](react.md#reactchange). This is only exposed for backwards compatibility; please prefer to use `React.Change`.

