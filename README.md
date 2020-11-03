# Roact Alignment
A temporary ground-up Roact repository that will track our preliminary alignment with React, starting with leaf nodes like the scheduler.

## Status
The [react repo](https://github.com/facebook/react) is a monorepo with a number of member projects in its `packages` folder, managed by a yarn workspace. Below is a description of each of those package, its status in our alignment repo, and how it likely fits into our future plans.

📌 _Considered part of react's core functionality or testing capabilities; some or all of this package is necessary to build and validate an MVP._

| Project | Description | Status | Plan | Notes |
| - | - | - | - | - |
| `create-subscription` | Used for subscribing to external data | ❌ Not ported | ❔ Not yet assessed | |
| `dom-event-testing-library` | Dom event simulation for tests | ❌ Not ported | ❔ Not yet assessed | May inspire Rhodium improvements |
| `eslint-plugin-react-hooks` | Linting plugin for hooks rules | ❌ Not ported | ❔ Not yet assessed | Depends on future linting tools |
| `jest-mock-scheduler` | Reexports scheduler testing utilities | ❌ Not ported | ❔ Not yet assessed | |
| 📌`jest-react` | Jest matchers and utilities | ❌ Not ported | ➕ Likely to be ported | Haven't yet run into any uses of this in tests we've ported so far |
| 📌`react` | Base react interface | 🔨 Port in progress |  | Defines basic shape of internals like Components and Elements. We may add things like Bindings here. |
| `react-art` | For drawing vector graphics | ❌ Not ported | ➖ Unlikely to be ported | |
| `react-cache` | Basic cache for use with experimental React features | ❌ Not ported | ❔ Not yet assessed | API is flagged as unstable |
| `react-client` | Experimental package for consuming React streaming models | ❌ Not ported | ❔ Not yet assessed | API considered unstable. Might be worth investigating if it stabilizes |
| `react-debug-tools` | Experimental debugger package | ❌ Not ported | ❔ Not yet assessed | API considered unstable |
| `react-devtools` | Top-level app for react devtools | ❌ Not ported | ➕ Likely to be ported | Devtools needs to be addressed as a whole to see where/how it translates |
| `react-devtools-core` | Standalone devtools impl | ❌ Not ported | ➕ Likely to be ported | Devtools needs to be addressed as a whole to see where/how it translates |
| `react-devtools-extensions` | Devtools browser extension | ❌ Not ported | ➖ Unlikely to be ported | |
| `react-devtools-inline` | Impl for embedding in browser-based IDEs | ❌ Not ported | ➕ Likely to be ported | Devtools needs to be addressed as a whole to see where/how it translates |
| `react-devtools-scheduling-profiler` | Experimental concurrent mode profiler | ❌ Not ported | ❔ Not yet assessed | |
| `react-devtools-shared` | Private shared utilities for devtools | ❌ Not ported | ➕ Likely to be ported | Devtools needs to be addressed as a whole to see where/how it translates |
| `react-devtools-shell` | Harness for testing other devtools packages | ❌ Not ported | ❔ Not yet assessed | Devtools needs to be addressed as a whole to see where/how it translates |
| `react-dom` | Entrypoint for DOM and server renderers | ❌ Not ported | ➖ Unlikely to be ported | Will inform top-level interface, but will be mostly replaced with Roblox-specific logic |
| `react-fetch` | For use with experimental React features | ❌ Not ported | ❔ Not yet assessed | API considered unstable |
| `react-interactions` | For use with experimental React features | ❌ Not ported | ❔ Not yet assessed | |
| 📌`react-is` | Runtime type checks for React elements | ✔️ Ported | | |
| `react-native-renderer` | Renderer interface for react-native | ❌ Not ported | ❔ Not yet assessed | This package has no readme, so it's hard to understand its scope |
| 📌`react-noop-renderer` | Renderer used for debugging Fiber | 🔨 Port in progress |  | Will be needed to verify our Fiber/Reconciler work |
| 📌`react-reconciler` | Reconciler implementation used with various renderers | 🔨 Port in progress |  | Bulk of React's complicated logic lives here |
| `react-refresh` | Wiring for Fast Refresh | ❌ Not ported | ❔ Not yet assessed, depend on applicability | Officially supported successor to "hot reloading" |
| `react-server` | Experimental package for creating React streaming server renderers | ❌ Not ported | ❔ Not yet assessed | |
| `react-test-renderer` | Test renderer with dom snapshotting | ❌ Not ported | ➕ Likely to be ported | Used for testing much of React's internals |
| `react-transport-dom-delay` | Internal package, likely for testing | ❌ Not ported | ➖ Unlikely to be ported | No readme in package |
| `react-transport-dom-webpack` | Related to above | ❌ Not ported | ➖ Unlikely to be ported | Appears to be webpack-specific |
| 📌`scheduler` | Cooperative scheduling implementation | ✔️ Ported | | Tracing feature is excluded, will be needed at some point for devtools |
| 📌`shared` | Loose collection of shared utilities and definitions | ✔️ Ported | | Working with upstream to see if this can be cleaned up |
| `use-subscription` | Hook for managing subscriptions in concurrent mode | ❌ Not ported | ❔ Not yet assessed | Not sure if/how this will apply to Roblox |

Projects not in the react repo:
| Project | Description | Notes |
| - | - | - |
| 📌`react-shallow-renderer` | Shallow renderer used in tests for some older React features. Re-exported alongside `react-test-renderer`, source of truth [here](https://github.com/NMinhNguyen/react-shallow-renderer). |  ✔️ Ported - with tests that are helping us exercise functionality in the `react` package |
| `roblox-jest` | Custom matchers and timer logic for TestEZ | A rough approximation of what we'll eventually have with the [`jest` alignment effort](https://github.com/Roblox/lest-alignment) |
| `roblox-js-polyfill` | Implementations of JS specific interfaces or functionality | Most implementations are incomplete or slightly adjusted for Lua |

## How to run the tests

You need to create a GitHub Access Token:
* GitHub.com -> Settings -> Developer Settings -> Personal Access Tokens
* On that same page, you then need to click Enable SSO
* BE SURE TO COPY THE ACCESS TOKEN SOMEWHERE 

```
npm login --registry=https://npm.pkg.github.com/ --scope=@roblox
```
For your password here, you will enter the GitHub Access Token from the instructions above.

```
npm install --global @roblox/rbx-aged-cli
```

Before you can use rbx-aged-cli, you need to be logged into the VPN so the Artifactory repository is accessible.

```
mkdir ~/bin
rbx-aged-cli download roblox-cli --dst ~/bin
export PATH=$PATH:~/bin
roblox-cli --help
git clone git@github.com:Roblox/roact-alignment.git
cd roact-alignment
roblox-cli analyze modules/scheduler/default.project.json
```

Foreman uses Rust, so you'll have to install Rust first.

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
export PATH=$PATH:$HOME/.cargo/bin
cargo install foreman
foreman github-auth  # your auth token should be in your ~/.npmrc
foreman install
export PATH=$PATH:~/.foreman/bin/
```

Now you can run the tests, edit code, and contribute!

```
rotrieve install
rojo build --output model.rbxmx
roblox-cli run --load.model model.rbxmx --run bin/spec.lua
```

### Common Issues

If rojo doesn't understand the nested project structure, exemplified by require statements not finding things, make sure you don't have a globally-installed rojo binary that is shadowing the one this project specifies locally. You *must* be using rojo 6.0 or above.

Once you remove the global rojo, you'll need to tickle bash's PATH hash cache so it doesn't keep looking in the place rojo *was*. (Yes, this is weird.) To update the bash path hash cache, run:
```hash -d rojo```

To avoid this in the future, be sure that your foreman binary path is *before* the carbo binary path in your `PATH` enviroment.

## Contribution Guidelines

* Try to keep the directory structure, file name/location, and code symbol names aligned with React upstream. At the top of the mirrored files, put a comment in this format that includes the specific hash of the version of the file you're mirroring: 
```
-- upstream https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Scheduler.js
```


* If you have a deviation from upstream code logic for Lua-specific reasons (1-based array indices, etc) put a comment above the deviated line:
```
-- deviation: use explicit nil check instead of falsey
``` 

* For deviations due to Lua langauge differences (no spread operator) that don't involve changing the logic, don't put a deviation comment. Just use the appropriate equivalent from the Cryo and other utility libraries.

* For files that are new and Roblox-specific, use the file name: ```Timeout.roblox.lua```

* and for Roblox-specific tests, use the file name format: ```Timeout.roblox.spec.lua```



