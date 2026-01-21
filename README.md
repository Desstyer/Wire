# Wire
Simple server-client communication module.

Example usage on the server:
```lua
-- On the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wire = require(ReplicatedStorage.Libraries.Wire)

-- This exposes a signal called 'ClientRequest' to all clients
local ClientRequest = Wire.Signal(`ClientRequest`)

ClientRequest:Connect(function(player, ...)
	print(`Client {player.Name} sent {tostring(...)}`)
end)

-- Wire also supports remote functions
Wire.Callback(`AddNumbers`, function(player, num1, num2)
	return num1 + num2
end)
```

Then on the client:
```lua
-- On the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wire = require(ReplicatedStorage.Libraries.Wire)

local ClientRequest = Wire.Signal(`ClientRequest`)

ClientRequest:Fire("Hello from client!")

local AddNumbers = Wire.Callback(`AddNumbers`)

print(AddNumbers(1, 3)) -- Wire.Callback returns a function that calls the RemoteFunction behind it

-- We can also listen from the client and fire from the server
ClientRequest:Connect(function(...)
	-- ...
end)
```
