local socket = require("socket")
local sqlite3 = require("lsqlite3")

-- Handling the save process
local db = sqlite3.open("mud.db")

db:exec([[
	CREATE TABLE IF NOT EXISTS players (
		id INTEGER PRIMARY KEY NOT NULL,
		username TEXT UNIQUE,
		current_room INTEGER
	);
]])

local function savePlayerProgress(username, currentRoom)
	local stmt = db:prepare("INSERT OR REPLACE INTO players (username, current_room) VALUES (?, ?)")
	stmt:bind_values(username, currentRoom)
	stmt:step()
	stmt:finalize()
end

local function getPlayerProgress(username)
	local stmt = db:prepare("SELECT current_room FROM players WHERE username = ?")
	stmt:bind_values(username)

	local currentRoom = nil
	if stmt:step() == sqlite3.ROW then
		currentRoom = stmt:get_value(0)
	end
	stmt:finalize()
	return currentRoom
end

-- handling the game logic
local host = "localhost"
local port = 12345

local rooms = {
	{ name = "Room 1", description = "This is room 1", exits = { east = 2 } },
	{ name = "Room 2", description = "This is room 2", exits = { west = 1 } },
}

local function send(client, message)
	client:send(message .. "\n")
end

local function login(username)
	local currentRoom = getPlayerProgress(username)
	return currentRoom
end

local function createAccount(username)
	local usernameExists = getPlayerProgress(username)
	if not usernameExists then
		savePlayerProgress(username, 1)
		return true
	end
	return false
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
			currentRoom = login(username)
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
			local success = createAccount(username)
			if success then
				send(client, "Created with success! Welcome, " .. username)
				currentRoom = 1
				savePlayerProgress(username, currentRoom)
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
		send(client, rooms[currentRoom].description)

		local exitList = "Exits: "
		for direction, room in pairs(rooms[currentRoom].exits) do
			exitList = exitList .. direction .. " goes to room " .. room .. ", "
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

	savePlayerProgress(username, currentRoom)
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
