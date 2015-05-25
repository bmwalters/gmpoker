local PANEL = {}

AccessorFunc(PANEL, "m_numMin",			"Min")
AccessorFunc(PANEL, "m_numMax",			"Max")
AccessorFunc(PANEL, "m_fFloatValue",	"FloatValue")
AccessorFunc(PANEL, "m_iDecimals",		"Decimals")

function PANEL:Init()
	self.NumText = self:Add("DTextEntry")
	self.NumText:Dock(RIGHT)
	self.NumText:SetDrawBackground(false)
	self.NumText:SetWide(45)
	self.NumText:SetNumeric(true)
	self.NumText.OnChange = function(NumText, val) self:SetValue(self.NumText:GetText()) end

	self.Slider = self:Add("DSlider", self)
		self.Slider:SetLockY(0.5)
		self.Slider.TranslateValues = function(slider, x, y)
			self:SetValue(self:GetMin() + (x * self:GetRange()))
			return self:GetFraction(), y
		end
		self.Slider:SetTrapInside(true)
		self.Slider:Dock(FILL)
		self.Slider:SetHeight(16)
		self.Slider:SetNotches(0)
		Derma_Hook(self.Slider, "Paint", "Paint", "NumSlider")

	self.Knob = self.Slider.Knob

	self:SetTall(32)

	self:SetMin(0)
	self:SetMax(1)
	self:SetDecimals(2)
	self:SetValue(0.5)
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:SetValue(val)
	val = math.Clamp(tonumber(val) or 0, self:GetMin(), self:GetMax())

	if not val or self:GetValue() == val then return end

	self:SetFloatValue(val)
	self:ValueChanged(self:GetValue())
end

function PANEL:SetFraction(fraction)
	self:SetFloatValue(self:GetMin() + (fraction * self:GetRange()))
end

function PANEL:GetFraction()
	return (self:GetFloatValue() - self:GetMin()) / (self:GetRange())
end

function PANEL:GetTextValue()
	local decimals = self:GetDecimals()
	if decimals == 0 then
		return string.format("%i", self:GetFloatValue())
	end

	return string.format("%."..decimals.."f", self:GetFloatValue())
end

PANEL.GetValue = PANEL.GetFloatValue

function PANEL:IsEditing()
	return self.NumText:IsEditing() or self.Slider:IsEditing()
end

function PANEL:ValueChanged(val)
	val = math.Clamp(tonumber(val) or 0, self:GetMin(), self:GetMax())

	self.Slider:SetSlideX(self:GetFraction(val))

	if self.NumText ~= vgui.GetKeyboardFocus() then
		self.NumText:SetValue(self:GetTextValue())
	end

	self:OnValueChanged(self:GetTextValue())
end

function PANEL:OnValueChanged(val)
	-- For override
end

vgui.Register("ZNumSlider", PANEL, "Panel")
