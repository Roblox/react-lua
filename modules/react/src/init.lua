-- ROBLOX deviation: simulates `index.js` and exports React's public interface
local React = require(script.React)

local ReactLazy = require(script.ReactLazy)
export type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

return React
