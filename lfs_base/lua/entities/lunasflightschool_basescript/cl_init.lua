--DO NOT EDIT OR REUPLOAD THIS FILE

include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:LFSCalcViewFirstPerson( view, ply )
	return view
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	return view
end

function ENT:LFSHudPaint( X, Y, data, ply )
end

function ENT:LFSHudPaintPassenger( X, Y, ply )
end

function ENT:Think()
	self:AnimCabin()
	self:AnimLandingGear()
	self:AnimRotor()
	self:AnimFins()
	
	self:CheckEngineState()
	
	self:ExhaustFX()
	self:DamageFX()
end

function ENT:DamageFX()
	local HP = self:GetHP()
	if HP == 0 or HP > self:GetMaxHP() * 0.5 then return end
	
	self.nextDFX = self.nextDFX or 0
	
	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetRotorPos() - self:GetForward() * 50 )
		util.Effect( "lfs_blacksmoke", effectdata )
	end
end

function ENT:ExhaustFX()
end

function ENT:CalcEngineSound( RPM, Pitch, Doppler )
end

function ENT:EngineActiveChanged( bActive )
end

function ENT:OnRemove()
	self:SoundStop()
end

function ENT:SoundStop()
end

function ENT:CheckEngineState()
	local Active = self:GetEngineActive()
	
	if Active then
		local RPM = self:GetRPM()
		local LimitRPM = self:GetLimitRPM()
		
		local tPer = RPM / LimitRPM
		
		local CurDist = (LocalPlayer():GetViewEntity():GetPos() - self:GetPos()):Length()
		self.PitchOffset = self.PitchOffset and self.PitchOffset + (math.Clamp((CurDist - self.OldDist) * FrameTime() * 300,-40,20 *  tPer) - self.PitchOffset) * FrameTime() * 5 or 0
		self.OldDist = CurDist
		
		local Pitch = (RPM - self:GetIdleRPM()) / (LimitRPM - self:GetIdleRPM())
		
		self:CalcEngineSound( RPM, Pitch, -self.PitchOffset )
	end
	
	if self.oldEnActive ~= Active then
		self.oldEnActive = Active
		self:EngineActiveChanged( Active )
	end
end

function ENT:AnimFins()
end

function ENT:AnimRotor()
end

function ENT:AnimCabin()
end

function ENT:AnimLandingGear()
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}
		
		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lfs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end