# ReactNoopRenderer
A Roblox Lua port of the react-noop-renderer package from React.

Original source: https://github.com/facebook/react/tree/master/packages/react-noop-renderer

## Status

### Ported
Files:
* `src/createReactNoop.js` -> `src/createReactNoop.lua`
* `src/ReactNoop.js` -> `src/ReactNoop.lua`

The entire implementation of the NoopRenderer, plus an entry point that exports all the relevant members.

### Not Ported
Files:
* `src/ReactNoopFlightClient.js`
* `src/ReactNoopFlightServer.js`
* `src/ReactNoopServer.js`

Serves additional entry points that enable use with the `react-client` and `react-server` packages. We can revisit this if we port those

Files:
* `src/ReactNoopPersistent.js`

A version of the NoopRenderer that's created with `useMutation = false`. If this is needed at some point, it'll be trivial to port.

### Intentional Deviations
Currently, we're not supporting JSX or an equivalent markup syntax. Select parts of `createReactNoop.lua` are only partially translated and are commented out.