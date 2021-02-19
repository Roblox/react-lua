return function()
	local RunService = game:GetService("RunService")
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local NODE_SIZE = 10
	local GRID_SIZE = 50

	--[[
		A frame that changes its background color according to time and position props
	]]
	local function Node(props)
		local x = props.x
		local y = props.y
		local currentTime = props.time

		local n = currentTime + x / NODE_SIZE + y / NODE_SIZE

		return Roact.createElement("Frame", {
			Size = UDim2.new(0, NODE_SIZE, 0, NODE_SIZE),
			Position = UDim2.new(0, NODE_SIZE * x, 0, NODE_SIZE * y),
			BackgroundColor3 = Color3.new(0.5 + 0.5 * math.sin(n), 0.5, 0.5),
		})
	end

	--[[
		Displays a large number of nodes and updates each of them every RunService step
	]]
	local App = Roact.Component:extend("App")

	function App:init()
		self.state = {
			time = tick(),
		}
	end

	function App:render()
		local currentTime = self.state.time
		local nodes = {}

		local n = 0
		for x = 0, GRID_SIZE - 1 do
			for y = 0, GRID_SIZE - 1 do
				n = n + 1
				nodes[n] = Roact.createElement(Node, {
					x = x,
					y = y,
					time = currentTime,
				})
			end
		end

		return Roact.createElement("Frame", {
			Size = UDim2.new(0, GRID_SIZE * NODE_SIZE, 0, GRID_SIZE * NODE_SIZE),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, nodes)
	end

	function App:componentDidMount()
		self.connection = RunService.Stepped:Connect(function()
			self:setState({
				time = tick(),
			})
		end)
	end

	function App:componentWillUnmount()
		self.connection:Disconnect()
	end

	local app = Roact.createElement("ScreenGui", nil, {
		Main = Roact.createElement(App),
	})

	local rootInstance = Instance.new("Folder")
	rootInstance.Parent = PlayerGui

	local root = Roact.createBlockingRoot(rootInstance)
	root:render(app)

	local function stop()
		root:unmount()
		rootInstance.Parent = nil
	end

	return stop
end