local Workspace = script.Parent.Parent.Parent

local ReactInternalTypes = require(Workspace.ReactReconciler.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
type FiberRoot = ReactInternalTypes.FiberRoot;
local ReactTypes = require(Workspace.Shared.ReactTypes)
type MutableSource<T> = ReactTypes.MutableSource<T>;
type ReactNodeList = ReactTypes.ReactNodeList;

type Array<T> = { [number]: T };

-- deviation: Containers should also be instances; at some point, we may
-- restrict which _kinds_ of instances, but that's not necessary right now
export type Container = Instance;
-- export type Container =
--   | (Element & {_reactRootContainer?: RootType, ...})
--   | (Document & {_reactRootContainer?: RootType, ...})

-- deviation: We can't export this as `Instance`; luau gets upset!
export type HostInstance = Instance;

-- export type TextInstance = Text;
-- deviation: Placeholder for now
export type SuspenseInstance = any;

export type RootType = {
  render: (ReactNodeList) -> (),
  unmount: () -> (),
  _internalRoot: FiberRoot,
  -- ...
  [any]: any,
};

export type RootOptions = {
  hydrate: boolean?,
  hydrationOptions: {
    onHydrated: (any) -> ()?,
    onDeleted: (any) -> ()?,
    mutableSources: Array<MutableSource<any>>?,
    -- ...
    [any]: any,
  }?,
  -- ...
  [any]: any,
};

return {}
