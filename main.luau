-- not by me idk who tho
--[[ Bug :3 ]]--

-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local RobloxReplicatedStorage = game:GetService("RobloxReplicatedStorage")

-- RemoteEvents
local Request = RobloxReplicatedStorage:WaitForChild("RequestDeviceCameraCFrame")
local Replicate = RobloxReplicatedStorage:WaitForChild("ReplicateDeviceCameraCFrame")

-- UI Elements
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local PlayerViewCore = RobloxGui:WaitForChild("CoreScripts/PlayerView")
PlayerViewCore.Enabled = false

-- Module Socket
local Socket = {}

-- Only initialize once

if not shared.Socket then
	local Frequency = 1
	local Interval = 1 / Frequency
	local Accumulator = 0

	RunService.Heartbeat:Connect(function(Delta)
		Accumulator = Accumulator + Delta
		while Accumulator >= Interval do
			Accumulator = Accumulator - Interval

			-- This is what causes the spam
			for _, Player in next, Players:GetPlayers() do
				Request:FireServer(Player.UserId)
			end
		end
	end)
end

shared.Socket = true

-- Empty listener for Request event (could be placeholder)
Request.OnClientEvent:Connect(function() end)

-- Socket.Connect function
function Socket.Connect(Channel, Hash)
	local Channel = tostring(Channel)
	local Port = Hash or 0

	-- Generate a hash-like integer from the channel name
	for Index = 1, #Channel do
		Port = (bit32.lshift(Port, 5) + Port) + Channel:byte(Index)
		Port = bit32.band(Port, 0xFFFFFFFF) -- keep it within 32-bit
	end

	local Connection

	local Socket = {
		Send = function(self, ...)
			Replicate:FireServer(CFrame.new(Port, Port, Port), { ... })
		end,

		Close = function(self)
			Connection:Disconnect()
			self.OnClose()
		end,

		OnMessage = {
			Connections = {},

			Connect = function(self, f)
				table.insert(self.Connections, f)
			end,

			Fire = function(self, ...)
				for _, Connection in pairs(self.Connections) do
					Connection(...)
				end
			end
		},

		OnClose = function() end
	}

	--[[ 4DBug made this module ]]--
	Connection = Replicate.OnClientEvent:Connect(function(Player, Cast, Arguments)
		if CFrame.new(Port, Port, Port) == Cast then
			Socket.OnMessage:Fire(Player, unpack(Arguments))
		end
	end)

	return Socket
end

return Socket
