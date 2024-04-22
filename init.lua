local init = {}

function init.init_db()
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
end

return init
