--!nolint LocalShadowPedantic
return function()
	local Reconciler = script.Parent.Parent
	local Workspace = script.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Object = LuauPolyfill.Object

	local setInstance = require(Workspace.Shared.ReactInstanceMap).set
	local ReactWorkTags = require(Reconciler.ReactWorkTags)
	local ClassComponent = ReactWorkTags.ClassComponent
	local HostRoot = ReactWorkTags.HostRoot
	local FunctionComponent = ReactWorkTags.FunctionComponent
	local SuspenseComponent = ReactWorkTags.SuspenseComponent

	local ReactFiberFlags = require(Reconciler.ReactFiberFlags)
	local NoFlags = ReactFiberFlags.NoFlags
	local Placement = ReactFiberFlags.Placement
	local Hydrating = ReactFiberFlags.Hydrating

	local ReactFiberTreeReflection

	describe("ReactFiberTreeReflection", function()
		beforeEach(function()
			RobloxJest.resetModules()
			RobloxJest.mock(Reconciler.ReactFiberHostConfig, function()
				return {}
			end)

			ReactFiberTreeReflection = require(Reconciler.ReactFiberTreeReflection)
		end)

		describe("getSuspenseInstanceFromFiber", function()
			local getSuspenseInstanceFromFiber

			beforeEach(function()
				getSuspenseInstanceFromFiber = ReactFiberTreeReflection.getSuspenseInstanceFromFiber
			end)

			local function mockFiber(mock)
				return Object.assign({
					tag = SuspenseComponent,
					alternate = nil,
					memoizedState = nil,
				}, mock)
			end

			it('returns the dehydrated memoized state from the fiber', function()
				local suspenseInstance = {}
				local fiber = mockFiber({
					memoizedState = {dehydrated = suspenseInstance},
				})
				expect(getSuspenseInstanceFromFiber(fiber)).to.equal(suspenseInstance)
			end)

			it('returns the dehydrated memoized state from the alternate fiber', function()
				local suspenseInstance = {}
				local fiber = mockFiber({
					alternate = mockFiber({
						memoizedState = {dehydrated = suspenseInstance},
					}),
				})
				expect(getSuspenseInstanceFromFiber(fiber)).to.equal(suspenseInstance)
			end)

			it('returns null if the fiber does not have the SuspenseComponent tag', function()
				local fiber = mockFiber({tag = FunctionComponent})
				expect(getSuspenseInstanceFromFiber(fiber)).to.equal(nil)
			end)
		end)

		describe('getContainerFromFiber', function()
			local getContainerFromFiber

			beforeEach(function()
				getContainerFromFiber = ReactFiberTreeReflection.getContainerFromFiber
			end)

			local function mockFiber(mock)
				return Object.assign({
					tag = HostRoot,
				}, mock)
			end

			it('returns a container if fiber is a host root', function()
				local container = {}
				local fiber = mockFiber({
					stateNode = {containerInfo = container},
				})
				expect(getContainerFromFiber(fiber)).to.equal(container)
			end)

			it('returns null if the fiber is not a host root', function()
				local fiber = mockFiber({tag = FunctionComponent})
				expect(getContainerFromFiber(fiber)).to.equal(nil)
			end)
		end)

		describe('different fiber states', function()
			local function mockFiber(mock)
				return Object.assign({
					alternate = nil,
					return_ = nil,
					tag = FunctionComponent,
					flags = NoFlags,
				}, mock)
			end
			local fiber

			local function generateIsFiberMounted(expected)
				local it = getfenv(2).it
				it(('isFiberMounted() is %s'):format(tostring(expected)), function()
					expect(ReactFiberTreeReflection.isFiberMounted(fiber)).to.equal(expected)
				end)
			end

			local function generateIsMounted(expected)
				local it = getfenv(2).it
				it(('isMounted() is %s'):format(tostring(expected)), function()
					local component = {}
					setInstance(component, fiber)
					expect(ReactFiberTreeReflection.isMounted(component)).to.equal(expected)
				end)
			end

			describe('with an alternate fiber', function()
				describe('last return node has the HostRoot tag', function()
					beforeEach(function()
						local rootFiber = mockFiber({tag = HostRoot})
						local middleFiber = mockFiber({return_ = rootFiber})
						fiber = mockFiber({
							alternate = mockFiber(),
							return_ = middleFiber,
						})
					end)

					generateIsFiberMounted(true)
					generateIsMounted(true)

					it('getNearestMountedFiber() returns the same fiber', function()
						expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(fiber)
					end)
				end)

				describe('last return node does not have the HostRoot tag', function()
					beforeEach(function()
						local rootFiber = mockFiber()

						fiber = mockFiber({
							alternate = mockFiber(),
							return_ = rootFiber,
						})
					end)

					it('getNearestMountedFiber() returns null', function()
						expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(nil)
					end)

					it('findCurrentFiberUsingSlowPath() throws', function()
						local expect: any = expect
						expect(function()
							ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)
						end).toThrow('Unable to find node on an unmounted component')
					end)

					generateIsFiberMounted(false)
					generateIsMounted(false)
				end)

				describe('fiber has the RootHost tag', function()
					beforeEach(function()
						fiber = mockFiber({
							alternate = mockFiber(),
							tag = HostRoot,
						})
					end)

					it('getNearestMountedFiber() returns the same fiber', function()
						expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(fiber)
					end)

					it(
						'findCurrentFiberUsingSlowPath() returns the same fiber ' ..
							'if the stateNode.current is the fiber',
						function()
							fiber.stateNode = {current = fiber}

							expect(ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)).to.equal(fiber)
						end
					)

					it(
						'findCurrentFiberUsingSlowPath() returns the alternate fiber ' ..
							'if the stateNode.current is not the given fiber',
						function()
							fiber.stateNode = {current = nil}

							expect(ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)).to.equal(fiber.alternate)
						end
					)

					generateIsFiberMounted(true)
					generateIsMounted(true)
				end)
			end)

			describe('without an alternate fiber', function()
				describe('all its return nodes do not have the placement or hydrating flag', function()
					beforeEach(function()
						local rootFiber = mockFiber({tag = HostRoot})
						local middleFiber = mockFiber({return_ = rootFiber})

						fiber = mockFiber({return_ = middleFiber})
					end)

					it('getNearestMountedFiber() returns the same fiber', function()
						expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(fiber)
					end)

					it('findCurrentFiberUsingSlowPath() returns the same fiber', function()
						expect(ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)).to.equal(fiber)
					end)

					generateIsFiberMounted(true)
					generateIsMounted(true)
				end)

				local fiberFlags = {
					placement = Placement,
					hydrating = Hydrating,
				}

				for name, flag in pairs(fiberFlags) do
					describe(('one of the return node has the %s flag'):format(name), function()
						local rootFiber

						beforeEach(function()
							rootFiber = mockFiber({tag = HostRoot})

							local middleFiber = mockFiber({
								return_ = rootFiber,
								flags = flag,
							})

							fiber = mockFiber({return_ = middleFiber})
						end)

						it('getNearestMountedFiber() returns the parent fiber', function()
							expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(rootFiber)
						end)

						it('findCurrentFiberUsingSlowPath() returns null', function()
							expect(ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)).to.equal(nil)
						end)

						generateIsFiberMounted(false)
						generateIsMounted(false)
					end)

					describe(
						('the return node of the fiber where it has the %s '):format(name) ..
							'flag does not have the HostRoot tags',
						function()
							beforeEach(function()
								local rootFiber = mockFiber()
								local middleFiber = mockFiber({
									return_ = rootFiber,
									flags = flag,
								})

								fiber = mockFiber({return_ = middleFiber})
							end)

							it('getNearestMountedFiber() returns null', function()
								expect(ReactFiberTreeReflection.getNearestMountedFiber(fiber)).to.equal(nil)
							end)

							it('findCurrentFiberUsingSlowPath() throws', function()
								local expect: any = expect
								expect(function()
									ReactFiberTreeReflection.findCurrentFiberUsingSlowPath(fiber)
								end).toThrow('Unable to find node on an unmounted component')
							end)

							generateIsFiberMounted(false)
							generateIsMounted(false)
						end
					)
				end
			end)
		end)

		describe('isFiberSuspenseAndTimedOut', function()
			local isFiberSuspenseAndTimedOut
			beforeEach(function()
				isFiberSuspenseAndTimedOut = ReactFiberTreeReflection.isFiberSuspenseAndTimedOut
			end)

			it('is true for a SuspenseComponent fiber when memoizedState.dehydrated is null', function()
				local fiber = {
					tag = SuspenseComponent,
					memoizedState = {dehydrated = nil},
				}
				expect(isFiberSuspenseAndTimedOut(fiber)).to.equal(true)
			end)

			it('is false if the fiber is not tagged as SuspenseComponent', function()
				local fiber = {
					tag = ClassComponent,
					memoizedState = {dehydrated = nil},
				}
				expect(isFiberSuspenseAndTimedOut(fiber)).to.equal(false)
			end)

			it('is false if the fiber does not have memoizedState', function()
				local fiber = {
					tag = SuspenseComponent,
					memoizedState = nil,
				}
				expect(isFiberSuspenseAndTimedOut(fiber)).to.equal(false)
			end)

			it('is false if the fiber memoizedState.dehydrated is not null', function()
				local fiber = {
					tag = SuspenseComponent,
					memoizedState = {
						dehydrated = 'foo',
					},
				}
				expect(isFiberSuspenseAndTimedOut(fiber)).to.equal(false)
			end)
		end)

		describe('doesFiberContain', function()
			local doesFiberContain
			beforeEach(function()
				doesFiberContain = ReactFiberTreeReflection.doesFiberContain
			end)

			local function mockFiber(mock)
				return Object.assign({
					return_ = nil,
					alternate = nil,
				}, mock or {})
			end

			it('is true if the parent and the child are the same fiber', function()
				local fiber = mockFiber()
				expect(doesFiberContain(fiber, fiber)).to.equal(true)
			end)

			it('is true if the parent alternate and the child are the same fiber', function()
				local fiber = mockFiber()
				local parent = mockFiber({alternate = fiber})
				expect(doesFiberContain(parent, fiber)).to.equal(true)
			end)

			it('is true if the child return node and the parent are the same fiber', function()
				local parent = mockFiber()
				local child = mockFiber({return_ = parent})
				expect(doesFiberContain(parent, child)).to.equal(true)
			end)

			it('is true if the child return node and the parent alternate are the same fiber', function()
				local parentAlternate = mockFiber()
				local parent = mockFiber({alternate = parentAlternate})
				local child = mockFiber({return_ = parentAlternate})
				expect(doesFiberContain(parent, child)).to.equal(true)
			end)

			it('is false if none of the child parents are the parent fiber', function()
				local parent = mockFiber()
				local child = mockFiber()
				expect(doesFiberContain(parent, child)).to.equal(false)
			end)
		end)
	end)
end
