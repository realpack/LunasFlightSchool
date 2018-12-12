--DO NOT EDIT OR REUPLOAD THIS FILE

include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:LFSCalcViewFirstPerson( view )
	return view
end

function ENT:LFSCalcViewThirdPerson( view )
	return view
end

function ENT:LFSHudPaint( X, Y, data )
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
		local CurDist = (LocalPlayer():GetViewEntity():GetPos() - self:GetPos()):Length()
		self.PitchOffset = self.PitchOffset and self.PitchOffset + (math.Clamp((CurDist - self.OldDist) * FrameTime() * 300,-40,40) - self.PitchOffset) * FrameTime() * 5 or 0
		self.OldDist = CurDist
		local RPM = self:GetRPM()
		local Pitch = (RPM - self:GetIdleRPM()) / (self:GetLimitRPM() - self:GetIdleRPM())
		
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
