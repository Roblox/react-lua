return {
	assign = require(script.assign),
	freeze = require(script.freeze),
	seal = require(script.seal),
	-- Special marker type used in conjunction with `assign` to remove values
	-- from tables, since nil cannot be stored in a table
	None = require(script.None),
}