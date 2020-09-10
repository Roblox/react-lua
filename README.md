# Roact Alignment
A temporary ground-up Roact repository that will track our preliminary alignment with React, starting with leaf nodes like the scheduler.

# How to run the tests

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
testez run --target roblox-cli modules/scheduler/
```

# Contribution Guidelines

* Try to keep the directory structure, file name/location, and code symbol names aligned with React upstream. At the top of the mirrored files, put a comment in this format that includes the specific hash of the version of the file you're mirroring: 
```
-- upstream https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Scheduler.js
```


* If you have a deviation from upstream code logic for Lua-specific reasons (1-based array indices, etc) put a comment above the deviated line:
```
-- deviation: use explicit nil check instead of falsey
``` 

* For deviations due to Lua langauge differences (no spread operator) that don't involve changing the logic, don't put a deviation comment. Just use the appropriate equivalent from the Cryo and other utility libraries.

* For files that are new and Roblox-specific, use the file name:
```Timeout.roblox.lua```

* and for Roblox-specific tests, use the file name format:
```Timeout.roblox.spec.lua```



