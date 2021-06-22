return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	local app = React.createElement("ScreenGui", nil, {
		Button = React.createElement("TextButton", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),

			-- Attach event listeners using `ReactRoblox.Event[eventName]`
			-- Event listeners get `rbx` as their first parameter
			-- followed by their normal event arguments.
			[ReactRoblox.Event.Activated] = function(rbx)
				print("The button was clicked!")
			end,
		}),
	})

	local rootInstance = Instance.new("Folder")
	rootInstance.Parent = PlayerGui

	local root = ReactRoblox.createBlockingRoot(rootInstance)
	root:render(app)

	local function stop()
		root:unmount()
		rootInstance.Parent = nil
	end

	return stop
end
