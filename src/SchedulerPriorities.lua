export type PriorityLevel = number

-- TODO: Use symbols?
return {
	NoPriority = 0,
	ImmediatePriority = 1,
	UserBlockingPriority = 2,
	NormalPriority = 3,
	LowPriority = 4,
	IdlePriority = 5,
}