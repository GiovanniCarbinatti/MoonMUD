local battle = {}

function battle.damage(attacker, defender)
	local damage = attacker.atk - defender.def
	if damage < 0 then
		return 0
	end
	return damage
end

function battle.attack(attacker, defender)
	defender.hp = defender.hp - battle.damage(attacker, defender)
end

return battle
