if SERVER then AddCSLuaFile() end

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.Spawnable	= true
ENT.AdminOnly	= false

ENT.Model		= Model("models/pokernight2/poker_table.mdl") -- models/pnati/pokertable.mdl or models/pokernight2/poker_table.mdl

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end
		poker.RegisterTable(self)
	end

	function ENT:Use(activator, caller, usetype, value)
		poker.UseTable(caller, self.TableIndex)
	end

	function ENT:OnRemove()
		poker.RemoveTable(self)
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
