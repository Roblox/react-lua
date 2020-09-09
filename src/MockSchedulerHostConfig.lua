return function()
	local currentTime: number = 0
	local scheduledCallback: ((boolean, number) -> ()) | nil = nil
	local scheduledTimeout: ((number) -> ()) | nil = nil
	local timeoutTime: number = -1
	local yieldedValues: { [number]: any } = nil
	local expectedNumberOfYields: number = -1
	local didStop: boolean = false
	local isFlushing: boolean = false
	local needsPaint: boolean = false
	local shouldYieldForPaint: boolean = false

	local function requestHostCallback(callback: (boolean) -> ())
		scheduledCallback = callback
	end

	local function cancelHostCallback()
		scheduledCallback = nil
	end

	local function requestHostTimeout(callback: (number) -> (), ms: number)
		scheduledTimeout = callback
		timeoutTime = currentTime + ms
	end

	local function cancelHostTimeout()
		scheduledTimeout = nil
		timeoutTime = -1
	end

	local function shouldYieldToHost(): boolean
		if
			(expectedNumberOfYields ~= -1 and yieldedValues ~= nil and #yieldedValues >= expectedNumberOfYields) or
			(shouldYieldForPaint and needsPaint)
		then
			-- We yielded at least as many values as expected. Stop flushing.
			didStop = true
			return true
		end

		return false
	end

	local function getCurrentTime(): number
		return currentTime
	end

	local function forceFrameRate()
		-- No-op
	end

	local function reset()
		if isFlushing then
			error('Cannot reset while already flushing work.')
		end

		currentTime = 0
		scheduledCallback = nil
		scheduledTimeout = nil
		timeoutTime = -1
		yieldedValues = nil
		expectedNumberOfYields = -1
		didStop = false
		isFlushing = false
		needsPaint = false
	end

	-- Should only be used via an assertion helper that inspects the yielded values.
	local function unstable_flushNumberOfYields(count: number)
		if isFlushing then
			error('Already flushing work.')
		end

		if scheduledCallback ~= nil then
			local cb = scheduledCallback
			expectedNumberOfYields = count
			isFlushing = true

			local ok, result = pcall(function()
				local hasMoreWork = true
				repeat
					hasMoreWork = cb(true, currentTime)
				until not hasMoreWork or didStop

				if not hasMoreWork then
					scheduledCallback = nil
				end
			end)

			expectedNumberOfYields = -1
			didStop = false
			isFlushing = false

			if not ok then
				error(result)
			end

			-- local ok, result = pcall(function()
			-- 	local hasMoreWork = true
			-- 	repeat
			-- 		hasMoreWork = cb(true, currentTime)
			-- 	until not hasMoreWork or didStop

			-- 	if not hasMoreWork then
			-- 		scheduledCallback = nil
			-- 	end
			-- end)

			-- expectedNumberOfYields = -1
			-- didStop = false
			-- isFlushing = false

			-- if not ok then
			-- 	error(result)
			-- end
		end
	end

	local function unstable_flushUntilNextPaint()
		if isFlushing then
			error('Already flushing work.')
		end

		if scheduledCallback ~= nil then
			local cb = scheduledCallback
			shouldYieldForPaint = true
			needsPaint = false
			isFlushing = true
			local ok, result = pcall(function()
				local hasMoreWork = true
				repeat
					hasMoreWork = cb(true, currentTime)
				until not hasMoreWork or didStop

				if not hasMoreWork then
					scheduledCallback = nil
				end
			end)

			shouldYieldForPaint = false
			didStop = false
			isFlushing = false

			if not ok then
				error(result)
			end
		end
	end

	local function unstable_flushExpired()
		if isFlushing then
			error('Already flushing work.')
		end
		if scheduledCallback ~= nil then
			isFlushing = true
			local ok, result = pcall(function()
				local hasMoreWork = scheduledCallback(false, currentTime)
				if not hasMoreWork then
					scheduledCallback = nil
				end
			end)

			isFlushing = false

			if not ok then
				error(result)
			end
		end
	end

	local function unstable_flushAllWithoutAsserting(): boolean
		-- Returns false if no work was flushed.
		if isFlushing then
			error('Already flushing work.')
		end
		if scheduledCallback ~= nil then
			local cb = scheduledCallback
			isFlushing = true
			local ok, result = pcall(function()
				local hasMoreWork = true
				repeat
					hasMoreWork = cb(true, currentTime)
				until not hasMoreWork

				if not hasMoreWork then
					scheduledCallback = nil
				end
			end)

			isFlushing = false

			if not ok then
				error(result)
			end

			return true
		else
			return false
		end
	end

	local function unstable_clearYields(): { [number]: any }
		if yieldedValues == nil then
			return {}
		end
		local values = yieldedValues
		yieldedValues = nil
		return values
	end

	local function unstable_flushAll()
		if yieldedValues ~= nil then
			error('Log is not empty. Assert on the log of yielded values before ' ..
				'flushing additional work.'
			)
		end
		unstable_flushAllWithoutAsserting()
		if yieldedValues ~= nil then
			error('While flushing work, something yielded a value. Use an ' ..
				'assertion helper to assert on the log of yielded values, e.g. ' ..
				'expect(Scheduler).toFlushAndYield([...])'
			)
		end
	end

	local function unstable_yieldValue(value: any)
		-- eslint-disable-next-line react-internal/no-production-logging
		-- if console.log.name == 'disabledLog' then
		-- 	-- If console.log has been patched, we assume we're in render
		-- 	-- replaying and we ignore any values yielding in the second pass.
		-- 	return
		-- end
		if yieldedValues == nil then
			yieldedValues = {value}
		else
			table.insert(yieldedValues, value)
		end
	end

	local function unstable_advanceTime(ms: number)
		-- eslint-disable-next-line react-internal/no-production-logging
		-- if console.log.name == 'disabledLog' then
		-- 	-- If console.log has been patched, we assume we're in render
		-- 	-- replaying and we ignore any time advancing in the second pass.
		-- 	return
		-- end
		currentTime += ms

		if scheduledTimeout ~= nil and timeoutTime <= currentTime then
			scheduledTimeout(currentTime)
			timeoutTime = -1
			scheduledTimeout = nil
		end
	end

	local function requestPaint()
		needsPaint = true
	end

	return {
		requestHostCallback = requestHostCallback,
		cancelHostCallback = cancelHostCallback,
		requestHostTimeout = requestHostTimeout,
		cancelHostTimeout = cancelHostTimeout,
		shouldYieldToHost = shouldYieldToHost,
		getCurrentTime = getCurrentTime,
		forceFrameRate = forceFrameRate,
		reset = reset,
		unstable_flushNumberOfYields = unstable_flushNumberOfYields,
		unstable_flushUntilNextPaint = unstable_flushUntilNextPaint,
		unstable_flushExpired = unstable_flushExpired,
		unstable_flushAllWithoutAsserting = unstable_flushAllWithoutAsserting,
		unstable_clearYields = unstable_clearYields,
		unstable_flushAll = unstable_flushAll,
		unstable_yieldValue = unstable_yieldValue,
		unstable_advanceTime = unstable_advanceTime,
		requestPaint = requestPaint,
	}
end