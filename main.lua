local socket = require("socket")
local sqlite3 = require("lsqlite3")
local save = require("save")
local login = require("login")
local init = require("init")
local rooms = require("rooms")

-- Handling the save process
_G.db = sqlite3.open("mud.db")

init:init_db()

-- handling the game logic
local host = "localhost"
local port = 12345

local function send(client, message)
	client:send(message .. "\n")
end

local function handleClient(client)
	send(client, "Welcome to MoonMud")
	local choice = nil
	local username = nil
	local currentRoom = nil

	while not choice do
		send(client, "Choose between: 1 - login, 2 - create an account")
		choice = client:receive()

		if choice == "1" then
			send(client, "Enter your username or 0 to return:")
			username = client:receive()
			if username == 0 then
				choice = nil
			end

			send(client, "Password:")
			local password = client:receive()

			currentRoom = login.login(username, password)["current_room"]

			if not currentRoom then
				send(client, "User " .. username .. " does not exists.")
				choice = nil
			else
				send(client, "Sucess! Welcome back, " .. username .. "!")
			end
		elseif choice == "2" then
			send(client, "Enter your new username or 0 to return:")
			username = client:receive()
			if username == 0 then
				choice = nil
			end
			send(client, "Password:")
			local password = client:receive()
			local success = login.createAccount(username, password)
			if success then
				send(client, "Created with success! Welcome, " .. username)
				currentRoom = 1
				save.savePlayerProgress(username, currentRoom)
			else
				send(client, "Username already exists. Choose another or login.")
				choice = nil
			end
		else
			client:send("Invalid command.")
			choice = nil
		end
	end

	while true do
		local area_msg = "You're in " .. rooms[currentRoom].name .. ", " .. rooms[currentRoom].description
		send(client, area_msg)

		local exitList = "Exits: "
		for direction, room in pairs(rooms[currentRoom].exits) do
			exitList = exitList .. direction .. " goes to " .. rooms[room].name .. ", "
		end
		exitList = exitList:sub(1, -3)
		send(client, exitList)

		local command = client:receive()

		if not command then
			break
		end

		local direction = string.match(command, "^go (%a+)$")
		if direction and rooms[currentRoom].exits[direction] then
			currentRoom = rooms[currentRoom].exits[direction]
		else
			send(client, "Invalid command.")
		end
	end

	save.savePlayerProgress(username, currentRoom)
	client:close()
end

local server = socket.bind(host, port)
print("Server started at " .. host .. ":" .. port)

while true do
	local client = server:accept()
	print("Client connected.")
	handleClient(client)
	print("Client disconnected.")
end
