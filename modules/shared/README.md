# shared
A Roblox Lua port of the `shared` pseudo-package from React, which contains a number of common utilities and definitions used across the React monorepo.

Status: ✔️ Ported

Source: https://github.com/facebook/react/tree/master/packages/shared

---

### ✏️ Notes
* `ReactTypes.js` contains a number of complex flow-type definitions that are not yet possible with Luau, so it's been simplified to a stub called `ReactTypes.roblox.lua`
* `ReactComponentStackFrame.js` is replaced by a partially-ported stub (`ReactComponentStackFrame.roblox.lua`) since it contains logic for parsing/navigating JS-specific stack structure. This needs to be ported to the equivalent functionality in Luau.
* Some slight changes to `isValidElement.lua` that account for the divergent shape of Component and PureComponent objects in our port (for `react`, they're functions; for us, they're tables)

### ❌ Excluded

#### Forked Config
```
forks/ReactFeatureFlags.native-fb.js
forks/ReactFeatureFlags.native-oss.js
forks/ReactFeatureFlags.readonly.js
forks/ReactFeatureFlags.test-renderer.js
forks/ReactFeatureFlags.test-renderer.native.js
forks/ReactFeatureFlags.test-renderer.www.js
forks/ReactFeatureFlags.testing.js
forks/ReactFeatureFlags.testing.www.js
forks/ReactFeatureFlags.www-dynamic.js
forks/ReactFeatureFlags.www.js
forks/Scheduler.umd.js
forks/SchedulerTracing.umd.js
forks/consoleWithStackDev.www.js
forks/invokeGuardedCallbackImpl.www.js
forks/object-assign.inline-umd.js
forks/object-assign.umd.js
```

Forks that specify different flag states are used in React with the help of a bundler that swaps in the correct file for the given environment. We don't have this kind of functionality yet, nor the same set of environments.

#### Integration Tests
```
__tests__/describeComponentFrame-test.js
__tests__/ReactError-test.internal.js
```
These tests required use of React and ReactDOM, and are not viable to port until we have more of the reconciler ported.