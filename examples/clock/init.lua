return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local function ClockApp(props)
		local timeValue = props.time

		return Roact.createElement("ScreenGui", nil, {
			Main = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 400, 0, 300),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = "The current time is: " .. timeValue,
			}),
		})
	end

	local rootInstance = Instance.new("Folder")
	rootInstance.Parent = PlayerGui

	local running = true
	local currentTime = 0
	local root = Roact.createBlockingRoot(rootInstance)
	root:render(Roact.createElement(ClockApp, {
		time = currentTime,
	}))

	spawn(function()
		while running do
			currentTime = currentTime + 1

			root:render(Roact.createElement(ClockApp, {
				time = currentTime,
			}))

			wait(1)
		end
	end)

	local function stop()
		running = false
		root:unmount()
		rootInstance.Parent = nil
	end

	return stop
end