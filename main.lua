local socket = require("socket")
local sqlite3 = require("lsqlite3")
local save = require("save")
local login = require("login")

-- Handling the save process
_G.db = sqlite3.open("mud.db")

db:exec([[
	CREATE TABLE IF NOT EXISTS credentials (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username VARCHAR(20) UNIQUE,
		password_hash TEXT,
		current_room INTEGER
	);
]])

db:exec([[
	CREATE TABLE IF NOT EXISTS equipments (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(127) NOT NULL,
		description TEXT,
		price INTEGER
	);
]])

db:exec([[
	CREATE TABLE IF NOT EXISTS items (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(127) NOT NULL,
		description TEXT,
		price INTEGER
	);
]])

db:exec([[
	CREATE TABLE IF NOT EXISTS players (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username VARCHAR(20) UNIQUE,
		hp INTEGER,
		atk INTEGER,
		def INTEGER,
		gold INTEGER
	);
]])

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
