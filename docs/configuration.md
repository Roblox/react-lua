
Roact can currently be configured by assigning values to a small number of special global variables. Typically, they need to be set up before `React` or `ReactRoblox` is initialized via `require`. There are a couple of ways to do this:

* Set globals using the `lua.globals` argument to tooling like `robloxdev-cli`
	* If you're using `lest`, you can do this [in a configuration file](https://github.com/Roblox/lest/#configuration)
* Assign values immediately at the beginning of the entry point script in your project
	* For lua-apps projects, you can do this conditionally by checking if you're in studio in your project's `StarterScript`, and then assigning globals accordingly

## Globals

### \_\_DEV\_\_
Enabling `_G.__DEV__` enables "Dev Mode", a general-purpose option that sacrifices performance to enable a number of features that improve the development experience:

* Component `render` methods are run twice to ensure that no side-effects are being counted upon
* Warnings for behavior that violates Roact rules and best practices, like:
	* Reading state when it hasn't been initialized
	* Calling `setState` before a component has mounted
	* Assigning [multiple keys](deviations.md#stable-keys) to a component
	* Failing to assign keys to elements in a list (a potential de-optimization)
* Warnings for the use of deprecated components or features
* Validation of properties passed into components via [`validateProps` or `propTypes`](deviations.md#property-validation)

You should enable Dev Mode in any or all of the following situations:

* Running unit tests and rhodium tests
* Running storybooks
* Developing and testing locally as you work

**Dev Mode is _not_ meant to be enabled on production.** While it exposes a great deal of useful information and introduces extra assurances, it pays a hefty performance cost to do so.

!!! info
	In the future, projects will use tools like [darklua](https://gitlab.com/seaofvoices/darklua) to automatically remove all code branches that check for Dev Mode when creating bundles for production. This reduces the overhead of branching on Dev Mode logic and saves a little bit of extra performance in places where it matters.

### \_\_DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION\_\_
Occasionally, some older projects will issue more warnings in Dev Mode than can easily be resolved. In order to introduce prop validation but silence all other Dev Mode warnings, set the `__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__` global to `true`.

!!! info
	Typically, this is only necessary in tests that are strict about reducing warning output. In general, prefer the full-featured Dev Mode.

### \_\_COMPAT_WARNINGS\_\_
Enables compatibility warnings for any uses of outdated APIs in your code. These compatibility mismatches should have no effect on behavior, but can be modernized to better align to standards and anticipate future releases. Compat warnings will help you surface uses of outdated APIs when you [migrate from Roact 1.x](migrating-from-roact-1x.md/#updating-conventions-and-apis).


### \_\_ROACT_17_MOCK_SCHEDULER\_\_
Ensure that Roact's internal scheduler is mocked instead of using real async logic like `task.delay`. This is useful in conjunction with [the `act` function](api-reference/react-roblox.md#reactrobloxact) to test concurrent behavior via the "arrange-act-assert" pattern.

Use this global in test configuration to make sure that you're not inadvertently relying on asynchronous logic in tests. Since Roact 17 uses concurrent rendering by default, you will always need this global to be set to `true` (except when using the [`__ROACT_17_COMPAT_LEGACY_ROOT__`](#ROACT17COMPATLEGACYROOT) global described below).

!!! caution
	In future updates, Roact should _always_ mock the scheduler when in a testing environment and avoid extra configuration. For now, Roact favors explicitness while we shore up the testing experience.

### \_\_ROACT_17_INLINE_ACT\_\_
This global will automatically wrap the behavior of `RoactCompat.mount`, `RoactCompat.update`, and `RoactCompat.unmount` in `ReactRoblox.act`, which ensures that queued actions will be played forward by the mocked scheduler.

Use this global to shore up existing tests that may not be 

**This is intended for tests only, and will not work correctly unless `__ROACT_17_MOCK_SCHEDULER__` is also enabled.**

### \_\_ROACT_17_COMPAT_LEGACY_ROOT\_\_
Ensures that the `RoactCompat.mount` compatibility function creates a Legacy Root instead of a Concurrent Root, which is the default behavior.

Use this global to preserve old behavior in certain testing scenarios. If you need to explicitly rely on a legacy root in production, consider opting for the [`createLegacyRoot`](api-reference/react-roblox.md#reactrobloxcreatelegacyroot) API instead.

<!--
Unclear if we should bother documenting:
* __YOLO__
* __DEBUG__
* __PROFILE__
* __EXPERIMENTAL__
-->