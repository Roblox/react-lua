# Scheduler
A Roblox Lua port of the scheduler package from React.

Original source: https://github.com/facebook/react/tree/master/packages/scheduler

## Status

### Ported
The main Scheduler logic has been ported along with a couple of associated utilities.

#### JavaScript setTimeout/clearTimeout Adapter
Files:
* (new file) -> `src/Timeout/Timeout.lua`
* (new file) -> `src/Timeout/makeTimeout.lua`

Test Files:
* (new file) -> `src/Timeout/__tests__/Timeout.spec.lua`

An added utility that replicates the interface of `setTimeout` and `clearTimeout` JavaScript functions, using Roblox's `delay` to mimic the underlying behavior.

#### MinHeap
Files:
* `src/SchedulerMinHeap.js` -> `src/SchedulerMinHeap.lua`

Test Files:
* (new file) -> `src/__tests__/SchedulerMinHeap.spec.lua`

A straightforward translation of the MinHeap implementation used in React's scheduler package. While React's version has no associated tests, it made sense to add a small test case to verify some of the corners of the logic, especially since changes were made to the implementation to accommodate Lua's 1-indexing.

#### Scheduler Interface
Files:
* `src/Scheduler.js` -> `src/Scheduler.lua`
* `src/SchedulerPriorities.js` -> `src/SchedulerPriorities.lua`
* `src/forks/SchedulerHostConfig.default.js` -> `src/SchedulerHostConfig.lua`

Test Files:
* `src/forks/SchedulerHostConfig.mock.js` -> `src/MockSchedulerHostConfig.lua`
* `src/__tests__/Scheduler-test.js` -> `src/__tests__/Scheduler.spec.lua`
* `src/__tests__/SchedulerNoDOM-test.js` -> `src/__tests__/SchedulerNoDOM.spec.lua`

Basic interface for the Scheduler.

This includes two sets of tests:
* A small, basic set of tests based on mocking the time logic that underpins `setTimeout` and `clearTimeout`, made possible by injecting mock timing logic into `src/Timeout/makeTimeout.lua`.
* A more robust test suite that uses `MockSchedulerHostConfig.lua`, which mocks the entire HostConfig interface and provides functionality to manipulate it within tests.

### Not Ported
A number of components in the scheduler repository are considered extraneous or in an uncertain state and have not been ported at this time.

#### PostTask logic
Files:
* `unstable_post_task.js`
* `src/SchedulerPostTask.js`

Test Files:
* `src/__tests__/SchedulerPostTask-test.js`

An alternate implementation of the Scheduler interface based on the new postTask browser API. There are relatively recent commits to these files, as well, suggesting new or ongoing development. Since the underlying browser API isn't relevant to the Roblox environment, this logic has been excluded.

#### Profiling
Files:
* `src/SchedulerProfiling.js`

Test files:
* `src/__tests__/SchedulerProfiling-test.js`

Profiling logic used for debugging the Scheduler. Includes tests that produce flamegraphs of processed tasks. This functionality is gated behind the `enableProfiling` flag defined in `SchedulerFeatureFlags.js`.

#### Tracing
Files:
* `tracing.js`
* `src/Tracing.js`
* `src/TracingSubscription.js`

Test files:
* `src/__tests__/Tracing-test.js`
* `src/__tests__/Tracing-test.internal.js`
* `src/__tests__/TracingSubscriptions-test.internal.js`

The tracing logic appears to be a layer of additional debugging functionality woven into the Scheduler interface. It's tied to a shared React feature flag, so it's likely involved with some functionality used by consumers of Scheduler, rather than internally to Scheduler itself.