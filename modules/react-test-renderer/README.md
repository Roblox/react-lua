# react-test-renderer
A Roblox Lua port of the react-test-reconciler package re-exported from React. Used to run integration-level tests in `react-dom`. Will likely be useful with the Roblox renderer when it's more thoroughly integrated.

Status: 🔨 Partially Ported

Source: https://github.com/facebook/react/tree/master/packages/react-test-renderer

---

### ✏️ Notes
* For now, only includes configs for testing with the noop renderer,

### ❌ Excluded

```
src/__tests__/ReactTestRenderer-test.internal.js
src/__tests__/ReactTestRenderer-test.js
src/__tests__/ReactTestRendererAct-test.js
src/__tests__/ReactTestRendererAsync-test.js
src/__tests__/ReactTestRendererTraversal-test.js
src/ReactTestRenderer.js
```

Actual test renderer impl is excluded for now.

```
src/__tests__/ReactShallowRenderer-test.js
src/__tests__/ReactShallowRendererHooks-test.js
src/__tests__/ReactShallowRendererMemo-test.js
```

These tests appear to be copied from the shallow renderer, which react depends upon and re-exports via `react-test-renderer`