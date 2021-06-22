return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	--[[
		A search bar with an icon and a text box
		When the icon is clicked, the TextBox captures focus
	]]
	local SearchBar = React.Component:extend("SearchBar")

	function SearchBar:init()
		self.textBoxRef = React.createRef()
	end

	function SearchBar:render()
		return React.createElement("Frame", {
			Size = UDim2.new(0, 300, 0, 50),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			SearchIcon = React.createElement("TextButton", {
				Size = UDim2.new(0, 50, 0, 50),
				AutoButtonColor = false,
				Text = "->",

				-- Handle click events on the search button
				[ReactRoblox.Event.Activated] = function()
					print("Button clicked; use our ref to have the TextBox capture focus")
					self.textBoxRef.current:CaptureFocus()
				end,
			}),

			SearchTextBox = React.createElement("TextBox", {
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.new(0, 50, 0, 0),

				-- Use ref to initalize a reference to the underlying object
				ref = self.textBoxRef,
			}),
		})
	end

	local app = React.createElement("ScreenGui", nil, {
		SearchBar = React.createElement(SearchBar),
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
