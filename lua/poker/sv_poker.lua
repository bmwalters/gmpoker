util.AddNetworkString("Poker_OpenGUI")
util.AddNetworkString("Poker_CloseGUI")
util.AddNetworkString("Poker_TakeTurn")

function poker.OverrideTables()
	local count, ccount = 0, 0
	local tablepos = {}
	for _, ent in pairs(ents.GetAll()) do
		if (ent:GetModel() == "models/pnati/pokertable.mdl" or ent:GetModel() == "models/pokernight2/poker_table.mdl") and ent:GetClass() ~= "pokertable" then
			local pos = ent:GetPos()
			tablepos[#tablepos + 1] = pos
			local ang = ent:GetAngles()
			local mdl = ent:GetModel()
			ent:Remove()
			local pokertable = ents.Create("pokertable")
			pokertable:SetPos(pos)
			pokertable:SetAngles(ang)
			pokertable:SetModel(mdl)
			pokertable:Spawn()
			pokertable:Activate()
			count = count + 1
		elseif poker.ChairModels[ent:GetModel()] then
			for _, pos in pairs(tablepos) do
				if pos:Distance(ent:GetPos()) < 200 then -- TODO: Is this foolproof?
					ent:Remove()
					ccount = ccount + 1
				end
			end
		end
	end
	if count > 0 then MsgC(color_green, "Replaced "..count.." poker table props with the pokertable entity!\n") end
	if ccount > 0 then MsgC(color_green, "Removed "..ccount.." poker chair props!\n") end
end

hook.Add("InitPostEntity", "Poker_OverrideTables", poker.OverrideTables)

poker.Tables = poker.Tables or {}

-- Some code taken from Bobblehead's "Resistance" (http://steamcommunity.com//sharedfiles/filedetails/?id=382065862)
local deg2rad = math.pi / 180
function poker.SpawnSeats(tbli)
	local tbl = poker.Tables[tbli].ent
	if not IsValid(tbl) then return end
	local tblpos, tblang = tbl:GetPos(), tbl:GetAngles()
	tbl:SetAngles(Angle(0, 0, 0))
	local mdldata = poker.TableModels[tbl:GetModel()]
	local x, y, z = tblpos.x + (mdldata.xmod or 0), tblpos.y + (mdldata.ymod or 0), tblpos.z + (mdldata.zmod or 0)
	local w, h = mdldata.w, mdldata.h
	for i = 1, 5 do
		local ang = (i/5)*360*deg2rad

		local pos = Vector(x+(math.cos(ang)*(w/2-30)), y+(math.sin(ang)*(h/2-30)),z)
		local rotation = Angle(0,ang/deg2rad,0)

		local chair = ents.Create("prop_vehicle_prisoner_pod")
		chair:SetPos(pos)
		chair:SetAngles(rotation)
		chair:SetModel("models/gmpoker/chair.mdl")
		chair:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
		--chair:SetKeyValue("limitview", "0")
		chair:Spawn()
		chair:Activate()
		chair:SetParent(tbl)
		poker.Tables[tbli].seats[i] = chair
	end
	tbl:SetAngles(tblang)
end

function poker.RegisterTable(tbl)
	if tbl.TableIndex then return end
	local index = #poker.Tables + 1
	poker.Tables[index] = {ent=tbl,players={},playersseq={},seats={},curturn=1}
	tbl.TableIndex = index
	poker.SpawnSeats(index)
end

function poker.RemoveTable(tbl)
	if not tbl.TableIndex then return end
	local index = tbl.TableIndex
	for ply, _ in pairs(poker.Tables[index].players) do
		poker.CloseTable(ply)
	end
	table.remove(poker.Tables, num)
	tbl.TableIndex = nil
end

function poker.UseTable(ply, tbli)
	if poker.Tables[tbli].players[ply] then
		poker.CloseTable(ply)
	else
		poker.OpenTable(ply, tbli)
	end
end

function poker.OpenTable(ply, tbli)
	local tbl = poker.Tables[tbli]
	tbl.players[ply] = true
	table.insert(tbl.playersseq, ply)

	ply.PokerTable = tbli
	ply.PokerSlot = #tbl.playersseq

	ply:EnterVehicle(tbl.seats[#tbl.playersseq])

	net.Start("Poker_OpenGUI")
	net.Send(ply)

	local are, plural = #tbl.playersseq > 1 and "are" or "is", #tbl.playersseq > 1 and "players" or "player"
	ply:MessageC("You opened table "..tbli.."! There "..are.." now "..#tbl.playersseq.." "..plural.." at it!")
end

function poker.CloseTable(ply)
	local tbli = ply.PokerTable
	if not tbli then return end

	if ply:InVehicle() then
		ply:ExitVehicle(ply:GetVehicle())
	end

	net.Start("Poker_CloseGUI")
	net.Send(ply)

	table.remove(poker.Tables[tbli].playersseq, ply.PokerSlot)
	poker.Tables[tbli].players[ply] = nil

	ply.PokerTable = nil
	ply.PokerSlot = nil

	ply:MessageC("You closed table "..tbli.."!")
end

hook.Add("PlayerUse", "Poker_UseChair", function(ply, ent)
	local parent = ent:GetParent()
	if not (parent ~= NULL and parent.TableIndex and poker.Tables[parent.TableIndex].players[ply]) then return end
	poker.CloseTable(ply)
end)

net.Receive("Poker_TakeTurn", function(len, ply)
	local tbl = poker.Tables[ply.PokerTable]
	if tbl.curturn ~= ply.PokerSlot then return end
	local i = tbl.curturn
	local cnt = #tbl.playersseq
	i = i + 1
	if i > cnt then i = 1 end
	tbl.curturn = i
	print(tbl.curturn)
end)
