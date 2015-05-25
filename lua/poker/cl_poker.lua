include("poker/znumslider.lua")

local hudend = Material("gmpoker/hudend.png", "noclamp smooth")
local hudmid = Material("gmpoker/hudmid.png", "noclamp smooth")
local hudbtn = Material("gmpoker/hudbtn.png", "noclamp smooth")
local hudcurlytop = Material("gmpoker/hudcurlytop.png", "noclamp smooth")
local slider = Material("gmpoker/slider.png", "noclamp smooth")
local submat = Material("gmpoker/sub.png", "noclamp smooth")
local addmat = Material("gmpoker/add.png", "noclamp smooth")

local cards = {c={},s={},h={},d={}}
for i = 1, 13 do
	cards.c[i] = Material("playingcards/c_"..i..".png", "noclamp smooth")
	cards.s[i] = Material("playingcards/s_"..i..".png", "noclamp smooth")
	cards.h[i] = Material("playingcards/h_"..i..".png", "noclamp smooth")
	cards.d[i] = Material("playingcards/d_"..i..".png", "noclamp smooth")
end

local open = false

local scrw, scrh = ScrW(), ScrH()

local endw, endh = 95, 187
local midw, midh = 1176, 131
local btnw, btnh = 140, 46
local sliderw, sliderh = 23, 23
local subw, subh = 36, 36
local hudcurlyw, hudcurlyh = 81, 81
local cardw, cardh = math.floor(929/6), math.floor(1433/6)

surface.CreateFont("Poker_FBS27", {
	font="Fundamental  Brigade Schwer", -- these two spaces
	size=27,
})

surface.CreateFont("Poker_Futura30", {
	font="Futura LT",
	size=30,
	weight=500
})

surface.CreateFont("Poker_Bello35", {
	font="Bello Script",
	size=35,
})

surface.CreateFont("Poker_Bello45", {
	font="Bello Script",
	size=45,
})

surface.CreateFont("Poker_Bello60", {
	font="Bello Script",
	size=60,
})

surface.CreateFont("Poker_BelloSmCp50", {
	font="Bello SmCp",
	size=50,
})

local card1 = cards.d[2]
local card2 = cards.c[12]
local buttons = {
	{text="FOLD", onclick = function()
		print("Folded")
	end},
	{text="ZERF", onclick = function()
		net.Start("Poker_TakeTurn")
		net.SendToServer()
	end},
	{text="TEST", onclick = function()
		card1 = cards.d[math.random(1, 13)]
		card2 = cards.c[math.random(1, 13)]
	end},
}
local orangecolor = Color(164, 117, 63)
local players = {"The Player", "Brock", "Claptrap", "Ash", "Sam"}
function poker.OpenGUI()
	local main = vgui.Create("DPanel")
	poker.pnl = main
	open = true
	main:SetPos(0, 0)
	main:SetSize(scrw, scrh)
	function main:Paint(w, h)
		surface.SetDrawColor(orangecolor)
		surface.DrawRect(0, scrh-midh, scrw, 55) -- orange bar thing
		surface.SetDrawColor(color_white)
		surface.SetMaterial(hudend)
		surface.DrawTexturedRect(0, scrh-endh, endw, endh) -- left end
		surface.DrawTexturedRectUV(scrw-endw, scrh-endh, endw, endh, 1, 0, 0, 1) -- right end
		surface.SetMaterial(hudmid)
		surface.DrawTexturedRect(endw, scrh-midh, midw, midh) -- middle
		surface.SetMaterial(hudcurlytop)
		surface.DrawTexturedRect(0, 0, hudcurlyw, hudcurlyh) -- curly top left
		surface.DrawTexturedRectUV(scrw-hudcurlyw, 0, hudcurlyw, hudcurlyh, 1, 0, 0, 1) -- curly top right
		surface.SetMaterial(card1)
		surface.DrawTexturedRectRotated(1050, scrh-(cardh*0.2), cardw, cardh, 5)
		surface.SetMaterial(card2)
		surface.DrawTexturedRectRotated(1187, scrh-(cardh*0.2)+3, cardw, cardh, 353)
		local x = 195
		for i = 1, 5 do
			draw.SimpleText(players[i], "Poker_FBS27", x, 22, color_white, TEXT_ALIGN_CENTER)
			draw.SimpleText("$20,000", "Poker_Bello35", x, 40, color_white, TEXT_ALIGN_CENTER)
			x = x + 245
		end
	end
	local pot = vgui.Create("DLabel", main)
	pot:SetPos(endw+16, scrh-midh-5)
	pot:SetTextColor(color_white)
	pot:SetText("pot:")
	pot:SetFont("Poker_BelloSmCp50")
	pot:SizeToContents()
	local potcash = vgui.Create("DLabel", main)
	potcash:SetPos(endw+80, scrh-midh-17)
	potcash:SetTextColor(color_white)
	potcash:SetText("$1,200")
	potcash:SetFont("Poker_Bello60")
	potcash:SizeToContents()
	local x, y = potcash:GetSize()
	potcash:SetSize(x + 5, y + 5)
	for i = 1, #buttons do
		local btn = vgui.Create("DButton", main)
		btn:SetPos(80 + ((25+btnw)*(i-1)), scrh-7-btnh)
		btn:SetSize(btnw, btnh)
		btn:SetFont("Poker_Futura30")
		btn:SetTextColor(color_white)
		btn:SetText(buttons[i].text)
		function btn:Paint(w, h)
			surface.SetMaterial(hudbtn)
			surface.SetDrawColor(color_white)
			surface.DrawTexturedRect(0, 0, w, h) -- button background
		end
		function btn:OnCursorEntered()
			local x, y = self:GetPos()
			self:SetPos(x, y - 3)
		end
		function btn:OnCursorExited()
			local x, y = self:GetPos()
			self:SetPos(x, y + 3)
		end
		function btn:DoClick() buttons[i].onclick(self) end
	end
	local cashslider = vgui.Create("ZNumSlider", main)
	cashslider:SetPos(80 + ((25+btnw)*3) + 150, scrh-btnh-3)
	cashslider:SetSize(200, 32)
	cashslider:SetDecimals(0)
	cashslider:SetMin(800)
	cashslider:SetMax(1600)
	cashslider:SetValue(800)
	cashslider.OnValueChanged = function(self, val)
		self.NumText:SetText("$"..string.Comma(val))
	end
	cashslider.Slider.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.DrawLine(0, 19, w, 19)
	end
	cashslider.Knob.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.SetMaterial(slider)
		surface.DrawTexturedRect(0, 0, sliderw, sliderh)
	end
	local txt = cashslider.NumText
	txt:SetText("$800")
	txt:SetCursor("none")
	txt:Dock(NODOCK) -- break those constraints part 2
	txt:SetParent(main) -- break those constraints
	txt:SetSize(100, 55)
	txt:SetPos(80 + ((25+btnw)*3) + 20, scrh-btnh+5 - txt:GetTall()/2.5)
	txt:SetTextColor(color_white)
	txt:SetFont("Poker_Bello45")
	local x, y = cashslider:GetPos()
	for i = 1, 2 do
		local btn = vgui.Create("DImageButton", main)
		btn:SetPos(x+(i == 1 and -sliderw or cashslider:GetWide()), y+8)
		btn.m_Image:SetMaterial(i == 1 and submat or addmat)
		btn:SetSize(sliderw, sliderh)
		btn.OnMousePressed = function(self)
			self.IsPressed = true
		end
		btn.OnMouseReleased = function(self)
			self.IsPressed = false
		end
		btn.Think = function(self)
			if self.IsPressed and (not self.NextPress or self.NextPress < CurTime()) then
				cashslider:SetValue(cashslider:GetValue() + (i == 1 and -1 or 1))
				self.NextPress = CurTime() + 0.15
			end
		end
	end
end

net.Receive("Poker_OpenGUI", function(len)
	poker.OpenGUI()
end)

net.Receive("Poker_CloseGUI", function(len)
	if not open then return end
	poker.pnl:Remove()
	poker.pnl = nil
	open = false
end)

local shoulddraw = {CHudHealth = false, CHudBattery = false, CHudAmmo = false}
hook.Add("HUDShouldDraw", "PNATIHUD_Hide", function(element)
	if not open then return end
	return shoulddraw[element]
end)
