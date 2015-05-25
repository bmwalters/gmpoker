math.randomseed(os.time())

-- todo: kickers, associating cards to hands, winner and tie logic, royal flush
--        ranking hand categories (straightflush > 4kind > fullhouse > flush > straight > 3kind > twopair > pair > highcard),

-- http://en.wikipedia.org/wiki/Standard_52-card_deck
-- http://en.wikipedia.org/wiki/Playing_card
-- http://en.wikipedia.org/wiki/Poker
-- http://en.wikipedia.org/wiki/Texas_hold_%27em

local pot, communitycards, facecards, deck, actionphrases, actions, players, dealer, active, board, curbet, hands
local BLIND_BIG, BLIND_SMALL
hands = 0

local function string_comma(num) -- credit http://richard.warburton.it
	if not num or not tonumber(num) then return end
	local left,num,right = string.match(num,"^([^%d]*%d)(%d*)(.-)$")
	return "$" .. left..(num:reverse():gsub("(%d%d%d)","%1,"):reverse())..right
end

local function string_split(str)
	local words = {}
	for word in string.gmatch(str, "%w+") do
		table.insert(words, word)
	end
	return words
end

local function string_strikethrough(str)
	local ret = ""
	return (string.gsub(str, ".", function(c)
		return "\204\182" .. c
	end))
end

local function string_strikecount(str)
	return #string.gsub(str, "\204\182", "")
end

local BLIND_SMALL, BLIND_BIG

local function output(output)
	output = tostring(output)
	local f = io.open("joker.txt", "w")
	f:write(output)
	f:close()
end

facecards = {[10] = "X", [11] = "J", [12] = "Q", [13] = "K"}

local function createdeck()
	deck = {}
	for i = 1, 13 do
		local str = facecards[i] or i
		deck[#deck + 1] = str .. "♣"
		deck[#deck + 1] = str .. "♦"
		deck[#deck + 1] = str .. "♥"
		deck[#deck + 1] = str .. "♠"
	end
end
createdeck()

local function randomcard()
	return table.remove(deck, math.random(1, #deck))
end

local facecardsrev = {X = 10, J = 11, Q = 12, K = 13}
local function splitcard(c)
	local num = string.sub(c, 1, 1)
	return {facecardsrev[num] or tonumber(num), string.sub(c, 2)}
end

local function gethas(ply)
	local allcards = {}
	for _, c in pairs(communitycards) do
		allcards[#allcards + 1] = splitcard(c)
	end
	allcards[#allcards + 1] = splitcard(ply.card1)
	allcards[#allcards + 1] = splitcard(ply.card2)

	local has
	table.sort(allcards, function(a, b)
		return a[1] > b[1]
	end)

	-- Flush
	do
		local flush
		local straight
		local suitcounts = {}
		for i, v in pairs(allcards) do
			local suit = v[2]
			suitcounts[suit] = suitcounts[suit] and suitcounts[suit] + 1 or 1
			if suitcounts[suit] >= 5 then
				flush = {"flush", v}
				break
			end
		end

		-- Straight
		local seq = 0
		for i, v in ipairs(allcards) do
			if allcards[i + 1] and (allcards[i + 1][1] - v[1] ~= 1) then
				seq = 0
			else
				seq = seq + 1
			end
			if seq >= 5 then
				straight = {"straight"}
				break
			end
		end

		if straight and flush then has = {"straightflush"} return has end
		if flush or straight then
			has = flush or straight
			return has
		end
	end

	-- pairs, 3-of-a-kind, 4-of-a-kind, full house
	do
		local counts = {}
		local curhas
		for i, v in pairs(allcards) do
			local num = v[1]
			counts[num] = counts[num] and (counts[num] + 1) or 1
			if counts[num] == 4 then
				has = {"4kind", num}
				return has
			elseif counts[num] == 3 then
				if curhas and curhas[1] == "pair" and curhas[2] ~= num then
					has = {"fullhouse", string.sub(curhas, 5) .. " and " .. num}
					return has
				end
				curhas = {"3kind", num}
			elseif counts[num] == 2 then
				if curhas and curhas[1] == "pair" then
					has = {"twopair", curhas[2] .. " and " .. num}
					return has
				elseif curhas and curhas[1] == "3kind" and curhas[2] ~= num then
					has = {"fullhouse", curhas[2] .. " and " .. num}
					return has
				end
				curhas = {"pair", num}
			end
		end
		has = curhas
		if has then return has end
	end
end

local function checkForNewBettingRound()
	for k, v in pairs(players) do
		if not v.takenTurn then return false end
	end
	newhand()
end

actionphrases = {CALL = "%s called!", FOLD = "%s folded!", CHECK = "%s checked!", RAISE = "%s raised %s!", BET = "%s bet %s!", ALLIN = "%s went all in!", GETHAS = "%s has ^"}
actions = {
	BET = function(ply, amt)
		if not tonumber(amt) then return false, "Amount not valid!" end
		amt = math.abs(math.ceil(amt))
		if amt > ply.money then return false, "You don't have enough money!" end
		ply.money = ply.money - amt
		pot = pot + amt
	end,
	RAISE = function(ply, amt)
		if not tonumber(amt) then return false, "Amount not valid!" end
		amt = math.abs(math.ceil(amt))
		if amt + curbet > ply.money then return false, "You don't have enough money!" end
		ply.money = ply.money - (amt + curbet)
		pot = pot + (amt + curbet)
		curbet = curbet + amt
	end,
	CALL = function(ply)
		local amt = curbet
		if bettinground == 1 and ply.postedBlind == BLIND_SMALL then amt = BLIND_SMALL end
		if bettinground == 1 and ply.postedBlind == BLIND_BIG then return false, "You posted the big blind! Check instead!" end
		return actions["BET"](ply, amt)
	end,
	FOLD = function(ply)
		ply.folded = true
	end,
	CHECK = function(ply)
		if bettinground ~= 1 and ply.postedBlind ~= BLIND_BIG then return false, "You didn't post the big blind!" end
	end,
	ALLIN = function(ply)
		pot = pot + ply.money
		ply.money = 0
	end,
	GETHAS = function(ply)
		local has = gethas(ply)
		local msg = has and has[1] .. (has[2] and " of " .. has[2] or "") or "nothing special"
		print("Has:", msg)
	end
}

players = {}

local function getPlayer(num) -- The benefits of clockwise play :B1:
	num = num - 1
	num = (num % #players) + 1
	return players[num]
end

local PLAYER = {}
function PLAYER:takeTurn(action, amt)
	if not actionphrases[action] then return false, "Invalid action!" end
	local result, err = actions[action](self, amt)
	if result == false then return false, (err or "You can't do that!") end
	self.takenTurn = true
	active = getPlayer(self.index + 1)
	return string.format(actionphrases[action], self.name, string_comma(amt))
end
function PLAYER:postBlind(blind)
	self.postedBlind = blind
	self.money = self.money - blind
	pot = pot + blind
end
function PLAYER:newhand()
	self.card1 = randomcard()
	self.card2 = randomcard()
	self.takenTurn = false
end
function PLAYER:__index(k)
	return rawget(self, k) or PLAYER[k]
end
function PLAYER:__tostring()
	return "Player '"..self.name.."' ("..self.index..")"
end

local function Player(name)
	local mt = setmetatable({}, PLAYER)
	mt.name = name
	mt.money = 20000
	mt.card1 = randomcard()
	mt.card2 = randomcard()
	mt.takenTurn = false
	players[#players + 1] = mt
	mt.index = #players

	return mt
end

Player("La Abeja")
Player("La Oveja")
Player("Adder")
Player("rich")
local localplayer = Player("You")

local function newhand()
	hands = hands + 1
	print("New hand! ("..hands..")")
	createdeck()

	communitycards = {randomcard(), randomcard(), randomcard()}

	pot = 0
	bettinground = 0

	dealer = players[2]
	active = getPlayer(dealer.index + 3)

	BLIND_SMALL = 50
	BLIND_BIG = 100
	getPlayer(dealer.index + 1):postBlind(BLIND_SMALL)
	getPlayer(dealer.index + 2):postBlind(BLIND_BIG)

	curbet = BLIND_BIG

	for k, v in pairs(players) do
		v:newhand()
	end
end

newhand()

board = [[|=============================|
%s
 Comm: %s
 Pot: %s
|=============================|]]

local function printBoard()
	local playerstats = ""
	for _, p in pairs(players) do
		local name = p.name .. ":"
		if p == active then name = "-> " .. name end
		if p.folded then name = string_strikethrough(name) end
		local money = string.format("%s", string_comma(p.money))
		local cards = "[" .. p.card1 .. "][" .. p.card2 .. "]"
		playerstats = playerstats .. " " .. name .. string.rep(" ", (20 - string_strikecount(name) - #money)) .. money .. " " .. cards .. "\n"
	end

	local communitystr = ""
	for _, c in pairs(communitycards) do
		communitystr = communitystr .. "[" .. c .. "]"
	end

	return string.format(board, playerstats, communitystr, string_comma(pot))
end

local temp = {"FOLD", "CALL"}
local function loop()
	local nextdo = os.clock() + 3

	while true do
		if os.clock() > nextdo or active == localplayer then
			checkForNewBettingRound()
			local play, err
			if active == localplayer then
				print("Enter your turn")
				temp = string_split(io.read("line"))
				play, err = active:takeTurn(string.upper(temp[1]), temp[2])
			else
				play, err = active:takeTurn(temp[math.random(1, #temp)])
			end
			if not play then print("Invalid turn! ("..err..")") goto continue end

			local board = printBoard()
			print(play)
			output(board .. "\n" .. play)
			nextdo = os.clock() + 3
		end
		::continue::
	end
end

loop()
