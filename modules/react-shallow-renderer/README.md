# react-shallow-renderer
A Roblox Lua port of the react-shallow-reconciler package re-exported from React. Used to run integration-level tests in `react-dom`. Will likely be useful with the Roblox renderer when it's more thoroughly integrated.

Status: ✔️ Ported

Source: https://github.com/NMinhNguyen/react-shallow-renderer/

---

### ✏️ Notes
* Includes some minor adjustments to the shallow renderer interface to better facilitate its translation
	* Most member functions use `:` function calls instead of `.` to avoid having to explicitly bind them to self. We could revisit this to align it more directly.
	* Implementation for `useState` returns multiple values instead of an array. This will likely be carried over to the full implementation in the reconciler as well
	* Context narrowing via `contextTypes` is only available on class components (since functions cannot have fields in Luau)
	* PropTypes are unsupported for now

### ❌ Excluded

```
src/__tests__/ReactShallowRendererMemo-test.js
```

Small test that didn't seem critical to port right now.