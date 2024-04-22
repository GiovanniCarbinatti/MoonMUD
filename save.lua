local save = {}
local sqlite3 = require("lsqlite3")

function save.savePlayerProgress(username, currentRoom)
	local stmt = db:prepare("UPDATE credentials SET current_room = ? WHERE username = ?")
	stmt:bind_values(currentRoom, username)
	stmt:step()
	stmt:finalize()
end

function save.getPlayerProgress(username, fields)
	if not fields then
		fields = { "current_room" }
	end

	local fieldList = table.concat(fields, ", ")
	local stmt = db:prepare("SELECT	" .. fieldList .. " FROM credentials WHERE username = ?")
	stmt:bind_values(username)

	local result = {}
	if stmt:step() == sqlite3.ROW then
		for i, field in ipairs(fields) do
			result[field] = stmt:get_value(i - 1)
		end
	end
	stmt:finalize()
	return result
end

return save
