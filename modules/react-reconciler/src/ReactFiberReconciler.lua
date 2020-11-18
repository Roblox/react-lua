-- upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-reconciler/src/ReactFiberReconciler.js
-- FIXME: This is a stub!

local exports = {}
exports.createContainer = function()
    return {
        current = {
            stateNode = {
                containerInfo = {
                    rootId = nil
                }
            }
        }
    }
end

exports.updateContainer = function() end

return exports
