--DO NOT EDIT OR REUPLOAD THIS FILE

include("shared.lua")

function ENT:CheckEngineState()
	local Active = self:GetRPM() > 0
	
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