local login = {}
local bcrypt = require("bcrypt")
local save = require("save")

function login.login(username, password)
	local results = save.getPlayerProgress(username, { "password_hash", "current_room" })
	if bcrypt.verify(password, results["password_hash"]) then
		return results
	else
		return {}
	end
end

function login.createAccount(username, password)
	local Exists = save.getPlayerProgress(username)
	if not Exists["current_room"] then
		local passwordHash = bcrypt.digest(password, 12)
		local stmt = db:prepare("INSERT INTO credentials (username, password_hash, current_room) VALUES (?, ?, ?)")
		stmt:bind_values(username, passwordHash, 1)
		stmt:step()
		stmt:finalize()
		return true
	end
	return false
end

return login
