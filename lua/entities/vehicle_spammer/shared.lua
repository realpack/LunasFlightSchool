ENT.Type            = "anim"


ENT.PrintName = "AI Vehicle Spammer"
ENT.Author = ""
ENT.Information = ""
ENT.Category = "[LFS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Int",0, "Type",	{ KeyName = "Vehicle Type",Edit = { type = "Int",	order = 1,min = 1, max = 8,	category = "Options"} } )
	self:NetworkVar( "Bool",1, "AutoTeam",{ KeyName = "AI Auto Team",Edit = { type = "Boolean",	order = 2,	category = "Options"} } )
	self:NetworkVar( "Int",2, "TeamOverride", { KeyName = "AI Team", Edit = { type = "Int", order = 3,min = 0, max = 2, category = "Options"} } )
	self:NetworkVar( "Int",3, "RespawnTime", { KeyName = "spawntime", Edit = { type = "Int", order = 3,min = 1, max = 120, category = "Options"} } )
	
	if SERVER then
		self:NetworkVarNotify( "Type", self.OnTypeChanged )
		
		self:SetAutoTeam( true )
		self:SetRespawnTime( 10 )
		self:SetType( 3 )
	end
end