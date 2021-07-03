return function(expected, received)
	if typeof(expected) == "table" then
		local i = 1
		while expected[i] == received[i] do
			i += 1
		end
		return ("Error with message, expected:\n%s\nGot:\n%s"):format(
			expected[i],
			received[i]
		)
	else
		return ("Expected:\n%q\nGot:\n%q"):format(expected, received)
	end
end
