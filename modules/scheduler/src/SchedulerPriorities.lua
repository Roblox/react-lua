-- upstream https://github.com/facebook/react/blob/0f6e3cd61cf4a5a1491bb3c92780936aebc2a146/packages/scheduler/src/SchedulerPriorities.js
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