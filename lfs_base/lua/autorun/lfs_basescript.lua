--DO NOT EDIT OR REUPLOAD THIS FILE

local cVar = GetConVar( "ai_ignoreplayers" )
local meta = FindMetaTable( "Player" )

simfphys = istable( simfphys ) and simfphys or {} -- lets check if the simfphys table exists. if not, create it!
simfphys.LFS = {} -- lets add another table for this project. We will be storing all our global functions and variables here. LFS means LunasFlightSchool

simfphys.LFS.VERSION = 95 -- note to self: Workshop is 10-version increments ahead. (next workshop update at 105)

simfphys.LFS.PlanesStored = {}
simfphys.LFS.NextPlanesGetAll = 0
simfphys.LFS.IgnorePlayers = cVar and cVar:GetBool() or false

simfphys.LFS.FreezeTeams = CreateConVar( "lfs_freeze_teams", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"enable/disable auto ai-team switching" )
simfphys.LFS.PlayerDefaultTeam = CreateConVar( "lfs_default_teams", "0", {FCVAR_REPLICATED , FCVAR_ARCHIVE},"set default player ai-team" )

simfphys.LFS.pSwitchKeys = {
	[KEY_1] = 1,
	[KEY_2] = 2,
	[KEY_3] = 3,
	[KEY_4] = 4,
	[KEY_5] = 5,
	[KEY_6] = 6,
	[KEY_7] = 7,
	[KEY_8] = 8,
	[KEY_9] = 9,
	[KEY_0] = 10,
}

simfphys.LFS.pSwitchKeysInv = {
	[1] = KEY_1,
	[2] = KEY_2,
	[3] = KEY_3,
	[4] = KEY_4,
	[5] = KEY_5,
	[6] = KEY_6,
	[7] = KEY_7,
	[8] = KEY_8,
	[9] = KEY_9,
	[10] = KEY_0,
}

function simfphys.LFS.GetVersion()
	return simfphys.LFS.VERSION
end

function simfphys.LFS:PlanesGetAll()
	local Time = CurTime()
	
	if simfphys.LFS.NextPlanesGetAll < Time then
		simfphys.LFS.NextPlanesGetAll = Time + FrameTime()
		
		table.Empty( simfphys.LFS.PlanesStored )
		
		local Index = 0

		for _,v in pairs( ents.GetAll() ) do
			if v.LFS then
				Index = Index + 1
				simfphys.LFS.PlanesStored[Index] = v
			end
		end
	end
	
	return simfphys.LFS.PlanesStored
end

function meta:lfsGetPlane()
	if not self:InVehicle() then return NULL end
	
	local Pod = self:GetVehicle()
	
	if not IsValid( Pod ) then return NULL end
	
	if Pod.LFSchecked == true then
		
		return Pod.LFSBaseEnt
		
	elseif Pod.LFSchecked == nil then
		
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then Pod.LFSchecked = false return NULL end
		
		if not Parent.LFS then Pod.LFSchecked = false return NULL end
		
		Pod.LFSchecked = true
		Pod.LFSBaseEnt = Parent
		
		return Parent
	else
		return NULL
	end
end

function meta:lfsGetAITeam()
	return self:GetNWInt( "lfsAITeam", simfphys.LFS.PlayerDefaultTeam:GetInt() )
end

if SERVER then 
	resource.AddWorkshop("1571918906")
	
	util.AddNetworkString( "lfs_failstartnotify" )
	util.AddNetworkString( "lfs_shieldhit" )
	util.AddNetworkString( "lfs_admin_setconvar" )
	
	net.Receive( "lfs_admin_setconvar", function( length, ply )
		if not IsValid( ply ) or not ply:IsSuperAdmin() then return end
		
		local ConVar = net.ReadString()
		local Value = tonumber( net.ReadString() )
		
		RunConsoleCommand( ConVar, Value ) 
	end)
	
	function meta:lfsSetAITeam( nTeam )
		nTeam = nTeam or simfphys.LFS.PlayerDefaultTeam:GetInt()
		
		if self:lfsGetAITeam() ~= nTeam then
			self:PrintMessage( HUD_PRINTTALK, "[LFS] Your AI-Team has been updated to: Team "..nTeam )
		end
		
		self:SetNWInt( "lfsAITeam", nTeam )
	end
	
	hook.Add( "PlayerButtonDown", "!!!lfsSeatswitcher", function( ply, button )
		local vehicle = ply:lfsGetPlane()
		
		if not IsValid( vehicle ) then return end
		
		if button == KEY_1 then
			if not IsValid( vehicle:GetDriver() ) and not vehicle:GetAI() then
				ply:ExitVehicle()
				
				local DriverSeat = vehicle:GetDriverSeat()
				
				if IsValid( DriverSeat ) then
					timer.Simple( FrameTime(), function()
						if not IsValid( vehicle ) or not IsValid( ply ) then return end
						if IsValid( vehicle:GetDriver() ) or not IsValid( DriverSeat ) or vehicle:GetAI() then return end
						
						ply:EnterVehicle( DriverSeat )
						
						timer.Simple( FrameTime() * 2, function()
							if not IsValid( ply ) or not IsValid( vehicle ) then return end
							ply:SetEyeAngles( Angle(0,vehicle:GetAngles().y,0) )
						end)
					end)
				end
			end
		else
			for _, Pod in pairs( vehicle:GetPassengerSeats() ) do
				if Pod:GetNWInt( "pPodIndex", 3 ) == simfphys.LFS.pSwitchKeys[ button ] then
					if not IsValid( Pod:GetDriver() ) then
						ply:ExitVehicle()
					
						timer.Simple( FrameTime(), function()
							if not IsValid( Pod ) or not IsValid( ply ) then return end
							if IsValid( Pod:GetDriver() ) then return end
							
							ply:EnterVehicle( Pod )
						end)
					end
				end
			end
		end
	end )
	
	hook.Add( "PlayerLeaveVehicle", "!!LFS_Exit", function( ply, vehicle )
		if not ply:IsPlayer() then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lfsGetPlane()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then return end
		
		if not simfphys.LFS.FreezeTeams:GetBool() then
			ply:lfsSetAITeam( Parent:GetAITEAM() )
		end
		
		local ent = Pod
		local b_ent = Parent
		
		local Center = b_ent:LocalToWorld( b_ent:OBBCenter() )
		local vel = b_ent:GetVelocity()
		local radius = b_ent:BoundingRadius()
		local HullSize = Vector(18,18,0)
		local Filter1 = {ent,ply}
		local Filter2 = {ent,ply,b_ent}
		
		if vel:Length() > 250 then
			local pos = b_ent:GetPos()
			local dir = vel:GetNormalized()
			local targetpos = pos - dir *  (radius + 40)
			
			local tr = util.TraceHull( {
				start = Center,
				endpos = targetpos - Vector(0,0,10),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter2
			} )
			
			local exitpoint = tr.HitPos + Vector(0,0,10)
			
			if util.IsInWorld( exitpoint ) then
				ply:SetPos(exitpoint)
				ply:SetEyeAngles((pos - exitpoint):Angle())
			end
		else
			local pos = ent:GetPos()
			local targetpos = (pos + ent:GetRight() * 80)
			
			local tr1 = util.TraceLine( {
				start = targetpos,
				endpos = targetpos - Vector(0,0,100),
				filter = {}
			} )
			local tr2 = util.TraceHull( {
				start = targetpos,
				endpos = targetpos + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = targetpos,filter = Filter2} )
			
			local HitGround = tr1.Hit
			local HitWall = tr2.Hit or traceto.Hit
			
			local check0 = (HitWall == true or HitGround == false or util.IsInWorld( targetpos ) == false) and (pos - ent:GetRight() * 80) or targetpos
			local tr = util.TraceHull( {
				start = check0,
				endpos = check0 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check0,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			
			local check1 = (HitWall == true or HitGround == false or util.IsInWorld( check0 ) == false) and (pos + ent:GetUp() * 100) or check0
			
			local tr = util.TraceHull( {
				start = check1,
				endpos = check1 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check1,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check2 = (HitWall == true or util.IsInWorld( check1 ) == false) and (pos - ent:GetUp() * 100) or check1
			
			local tr = util.TraceHull( {
				start = check2,
				endpos = check2 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check2,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check3 = (HitWall == true or util.IsInWorld( check2 ) == false) and b_ent:LocalToWorld( Vector(0,radius,0) ) or check2
			
			local tr = util.TraceHull( {
				start = check3,
				endpos = check3 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check3,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check4 = (HitWall == true or util.IsInWorld( check3 ) == false) and b_ent:LocalToWorld( Vector(0,-radius,0) ) or check3
			
			local tr = util.TraceHull( {
				start = check4,
				endpos = check4 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check4,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local exitpoint = (HitWall == true or util.IsInWorld( check4 ) == false) and b_ent:LocalToWorld( Vector(0,0,0) ) or check4
			
			if util.IsInWorld( exitpoint ) then
				ply:SetPos(exitpoint)
				ply:SetEyeAngles((pos - exitpoint):Angle())
			end
		end
	end )
end

if CLIENT then
	local cvarVolume = CreateClientConVar( "lfs_volume", 1, true, false)
	local cvarCamFocus = CreateClientConVar( "lfs_camerafocus", 0, true, false)
	
	local HintPlayerAboutHisFuckingIncompetence = true
	local smTran = 0

	hook.Add( "CalcView", "!!!!LFS_calcview", function(ply, pos, angles, fov)
		HintPlayerAboutHisFuckingIncompetence = false
	 
		if ply:GetViewEntity() ~= ply then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lfsGetPlane()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then return end
		
		local cvarFocus = math.Clamp( cvarCamFocus:GetFloat() , -1, 1 )
		
		smTran = smTran + ((ply:KeyDown( IN_WALK ) and 0 or 1) - smTran) * FrameTime() * 10
		
		local view = {}
		view.origin = pos
		view.fov = fov
		view.drawviewer = true
		view.angles = (Parent:GetForward() * (1 + cvarFocus) * smTran * 0.8 + ply:EyeAngles():Forward() * math.max(1 - cvarFocus, 1 - smTran)):Angle()
		view.angles.r = 0
		
		if Parent:GetDriverSeat() ~= Pod then
			view.angles = ply:EyeAngles()
		end
		
		if not Pod:GetThirdPersonMode() then
			
			view.drawviewer = false
			
			return Parent:LFSCalcViewFirstPerson( view )
		end
		
		local radius = 550
		radius = radius + radius * Pod:GetCameraDistance()
		
		local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
		local WallOffset = 4

		local tr = util.TraceHull( {
			start = view.origin,
			endpos = TargetOrigin,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LFS
				
				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )
		
		view.origin = tr.HitPos
		
		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return Parent:LFSCalcViewThirdPerson( view )
	end )

	local function DrawCircle( X, Y, radius )
		local segmentdist = 360 / ( 2 * math.pi * radius / 2 )
		
		for a = 0, 360 - segmentdist, segmentdist do
			surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
			
			surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
		end
	end

	surface.CreateFont( "LFS_FONT", {
		font = "Verdana",
		extended = false,
		size = 20,
		weight = 2000,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false,
	} )

	surface.CreateFont( "LFS_FONT_SWITCHER", {
		font = "Verdana",
		extended = false,
		size = 16,
		weight = 2000,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont( "LFS_FONT_PANEL", {
		font = "Arial",
		extended = false,
		size = 14,
		weight = 1,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	local MinZ = 0
	local function PaintPlaneHud( ent, X, Y )

		if not IsValid( ent ) then return end
		
		local vel = ent:GetVelocity():Length()
		
		local Throttle = math.max( math.Round( ((ent:GetRPM() - ent:GetIdleRPM()) / (ent:GetMaxRPM() - ent:GetIdleRPM())) * 100, 0) ,0)
		local Col = Throttle <= 100 and Color(255,255,255,255) or Color(255,0,0,255)
		draw.SimpleText( "THR", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( Throttle.."%" , "LFS_FONT", 120, 10, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
		local speed = math.Round(vel * 0.09144,0)
		draw.SimpleText( "IAS", "LFS_FONT", 10, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( speed.."km/h" , "LFS_FONT", 120, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
		local ZPos = math.Round( ent:GetPos().z,0)
		if (ZPos + MinZ)< 0 then MinZ = math.abs(ZPos) end
		
		local alt = math.Round( (ent:GetPos().z + MinZ) * 0.0254,0)
		
		draw.SimpleText( "ALT", "LFS_FONT", 10, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( alt.."m" , "LFS_FONT", 120, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
		local AmmoPrimary = ent:GetAmmoPrimary()
		local AmmoSecondary = ent:GetAmmoSecondary()
		
		if ent:GetMaxAmmoPrimary() > -1 then
			draw.SimpleText( "PRI", "LFS_FONT", 10, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			draw.SimpleText( ent:GetAmmoPrimary(), "LFS_FONT", 120, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		end
		
		if ent:GetMaxAmmoSecondary() > -1 then
			draw.SimpleText( "SEC", "LFS_FONT", 10, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			draw.SimpleText( ent:GetAmmoSecondary(), "LFS_FONT", 120, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		end
		
		ent:LFSHudPaint( X, Y, {speed = speed, altitude = alt, PrimaryAmmo = AmmoPrimary, SecondaryAmmo = AmmoSecondary, Throttle = Throttle})
	end
	
	local smHider = 0
	local function PaintSeatSwitcher( ent, X, Y )
		local me = LocalPlayer()
		
		if not IsValid( ent ) then return end
		
		local pSeats = ent:GetPassengerSeats()
		local SeatCount = table.Count( pSeats ) 
		
		if SeatCount <= 0 then return end
		
		pSeats[0] = ent:GetDriverSeat()
		
		draw.NoTexture() 
		
		local MySeat = me:GetVehicle():GetNWInt( "pPodIndex", -1 )
		
		local Passengers = {}
		for _, ply in pairs( player.GetAll() ) do
			if ply:lfsGetPlane() == ent then
				local Pod = ply:GetVehicle()
				Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = ply:GetName()
			end
		end
		if ent:GetAI() then
			Passengers[1] = "[AI] "..ent.PrintName
		end
		
		me.SwitcherTime = me.SwitcherTime or 0
		me.oldPassengers = me.oldPassengers or {}
		
		local Time = CurTime()
		for k, v in pairs( Passengers ) do
			if me.oldPassengers[k] ~= v then
				me.oldPassengers[k] = v
				me.SwitcherTime = Time + 2
			end
		end
		for k, v in pairs( me.oldPassengers ) do
			if not Passengers[k] then
				me.oldPassengers[k] = nil
				me.SwitcherTime = Time + 2
			end
		end
		
		for _, v in pairs( simfphys.LFS.pSwitchKeysInv ) do
			if input.IsKeyDown(v) then
				me.SwitcherTime = Time + 2
			end
		end
		
		local Hide = me.SwitcherTime > Time
		smHider = smHider + ((Hide and 1 or 0) - smHider) * FrameTime() * 15
		local Alpha1 = 75 + 170 * smHider 
		local HiderOffset = 300 * smHider
		local Offset = -50
		local yPos = Y - (SeatCount + 1) * 30 - 10
		
		for _, Pod in pairs( pSeats ) do
			local I = Pod:GetNWInt( "pPodIndex", -1 )
			if I >= 0 then
				if I == MySeat then
					draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(127,0,0,50 + 100 * smHider) )
				else
					draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,50 + 100 * smHider) )
				end
				if Hide then
					if Passengers[I] then
						draw.DrawText( Passengers[I], "LFS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
					else
						draw.DrawText( "-", "LFS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
					end
					
					draw.DrawText( "["..I.."]", "LFS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				else
					if Passengers[I] then
						draw.DrawText( "[^"..I.."]", "LFS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
					else
						draw.DrawText( "["..I.."]", "LFS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
					end
				end
			end
		end
	end

	local NextFind = 0
	local AllPlanes = {}
	local function PaintPlaneIdentifier( ent )
		if NextFind < CurTime() then
			NextFind = CurTime() + 3
			AllPlanes = simfphys.LFS:PlanesGetAll()
		end
		
		local MyPos = ent:GetPos()
		local MyTeam = ent:GetAITEAM()
		
		for _, v in pairs( AllPlanes ) do
			if IsValid( v ) then
				if v ~= ent then
					if isvector( v.SeatPos ) then
						local rPos = v:LocalToWorld( v.SeatPos )
						local Pos = rPos:ToScreen()
						local Size = 60
						local Dist = (MyPos - rPos):Length()
						
						if Dist < 13000 then
							local Alpha = math.max(255 - Dist * 0.015,0)
							local Team = v:GetAITEAM()
							if Team ~= MyTeam or Team == 0 then
								surface.SetDrawColor( 255, 0, 0, Alpha )
							else
								surface.SetDrawColor( 0, 127, 255, Alpha )
							end
							
							surface.DrawLine( Pos.x - Size, Pos.y + Size, Pos.x + Size, Pos.y + Size )
							
							surface.DrawLine( Pos.x - Size, Pos.y - Size, Pos.x - Size, Pos.y + Size )
							
							surface.DrawLine( Pos.x + Size, Pos.y - Size, Pos.x + Size, Pos.y + Size )
							surface.DrawLine( Pos.x - Size, Pos.y - Size, Pos.x + Size, Pos.y - Size )
						end
					end
				end
			end
		end
	end

	local LFS_TIME_NOTIFY = 0
	net.Receive( "lfs_failstartnotify", function( len )
		surface.PlaySound( "common/wpn_hudon.ogg" )
		LFS_TIME_NOTIFY = CurTime() + 2
	end )
	
	net.Receive( "lfs_shieldhit", function( len )
		local Pos = net.ReadVector()
		if isvector( Pos ) then
			local effectdata = EffectData()
				effectdata:SetOrigin( Pos )
			util.Effect( "lfs_shield_deflect", effectdata )
		end
	end )

	hook.Add( "HUDPaint", "!!!!LFS_hud", function()
		local ply = LocalPlayer()
		
		if ply:GetViewEntity() ~= ply then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lfsGetPlane()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then 
			ply.oldPassengers = {}
			
			return
		end
		
		local X = ScrW()
		local Y = ScrH()
		
		PaintSeatSwitcher( Parent, X, Y )
		
		if Parent:GetDriverSeat() ~= Pod then return end
		
		if HintPlayerAboutHisFuckingIncompetence then
			if not Parent.ERRORSOUND then
				surface.PlaySound( "error.wav" )
				Parent.ERRORSOUND = true
			end
			
			local HintCol = Color(255,0,0, 255 )
			
			surface.SetDrawColor( 0, 0, 0, 255 )
			surface.DrawRect( 0, 0, X, Y ) 
			surface.SetDrawColor( 255, 255, 255, 255 )
			
			draw.SimpleText( "OOPS! SOMETHING WENT WRONG :( ", "LFS_FONT", X * 0.5, Y * 0.5 - 40, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "ONE OF YOUR ADDONS IS BREAKING THE CALCVIEW HOOK. PLANES WILL NOT BE USEABLE", "LFS_FONT", X * 0.5, Y * 0.5 - 20, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "HOW TO FIX?", "LFS_FONT", X * 0.5, Y * 0.5 + 20, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "DISABLE ALL ADDONS THAT COULD POSSIBLY MESS WITH THE CAMERA-VIEW", "LFS_FONT", X * 0.5, Y * 0.5 + 40, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "(THIRDPERSON ADDONS OR SIMILAR)", "LFS_FONT", X * 0.5, Y * 0.5 + 60, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			draw.SimpleText( ">>PRESS YOUR USE-KEY TO LEAVE THE VEHICLE & HIDE THIS MESSAGE<<", "LFS_FONT", X * 0.5, Y * 0.5 + 120, Color(255,0,0, math.abs( math.cos( CurTime() ) * 255) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			return
		end
		
		PaintPlaneHud( Parent, X, Y )
		PaintPlaneIdentifier( Parent )
		
		local startpos =  Parent:GetRotorPos()
		local TracePlane = util.TraceLine( {
			start = startpos,
			endpos = (startpos + Parent:GetForward() * 50000),
			filter = Parent
		} )
		
		local TracePilot = util.TraceLine( {
			start = startpos,
			endpos = (startpos + ply:EyeAngles():Forward() * 50000),
			filter = Parent
		} )
		
		local HitPlane = TracePlane.HitPos:ToScreen()
		local HitPilot = TracePilot.HitPos:ToScreen()

		local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
		local Len = Sub:Length()
		local Dir = Sub:GetNormalized()
		surface.SetDrawColor( 255, 255, 255, 100 )
		if Len > 34 then
			local FailStart = LFS_TIME_NOTIFY > CurTime()
			if FailStart then
				surface.SetDrawColor( 255, 0, 0, math.abs( math.cos( CurTime() * 10 ) ) * 255 )
			end
			
			if not ply:KeyDown( IN_WALK ) or FailStart then
				surface.DrawLine( HitPlane.x + Dir.x * 10, HitPlane.y + Dir.y * 10, HitPilot.x - Dir.x * 34, HitPilot.y- Dir.y * 34 )
			end
		end
		
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		DrawCircle( HitPlane.x, HitPlane.y, 10 )
		surface.DrawLine( HitPlane.x + 10, HitPlane.y, HitPlane.x + 20, HitPlane.y ) 
		surface.DrawLine( HitPlane.x - 10, HitPlane.y, HitPlane.x - 20, HitPlane.y ) 
		surface.DrawLine( HitPlane.x, HitPlane.y + 10, HitPlane.x, HitPlane.y + 20 ) 
		surface.DrawLine( HitPlane.x, HitPlane.y - 10, HitPlane.x, HitPlane.y - 20 ) 
		
		DrawCircle( HitPilot.x, HitPilot.y, 34 )
	end )
	
	local Frame
	local bgMat = Material( "lfs_controlpanel_bg.png" )
	local function OpenMenu()
		if not IsValid( Frame ) then
			Frame = vgui.Create( "DFrame" )
			Frame:SetSize( 400, 200 )
			Frame:SetTitle( "" )
			Frame:SetDraggable( true )
			Frame:MakePopup()
			Frame:Center()
			Frame.Paint = function(self, w, h )
				draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
				draw.RoundedBox( 8, 1, 26, w-2, h-27, Color( 120, 120, 120, 255 ) )
				draw.RoundedBox( 8, 0, 0, w, 25, Color( 127, 0, 0, 255 ) )
				draw.SimpleText( "[LFS] Planes - Control Panel ", "LFS_FONT", 5, 11, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
				
				surface.SetDrawColor( 255, 255, 255, 50 )
				surface.SetMaterial( bgMat )
				surface.DrawTexturedRect( 0, -50, w, w )
				
				draw.DrawText( "( -1 = Focus Mouse   1 = Focus Plane )", "LFS_FONT_PANEL", 20, 95, Color( 200, 200, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				
				if LocalPlayer():IsSuperAdmin() then
					draw.DrawText( "( This will only affect new connected Players )", "LFS_FONT_PANEL", 20, 135, Color( 200, 200, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				end
				
				draw.DrawText( "v"..simfphys.LFS.GetVersion()..".GIT", "LFS_FONT_PANEL", w - 15, h - 20, Color( 200, 200, 200, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
				
			end
			
			local slider = vgui.Create( "DNumSlider", Frame)
			slider:SetPos( 20, 40 )
			slider:SetSize( 300, 20 )
			slider:SetText( "Engine Volume" )
			slider:SetMin( 0 )
			slider:SetMax( 1 )
			slider:SetDecimals( 2 )
			slider:SetConVar( "lfs_volume" )
			
			local slider = vgui.Create( "DNumSlider", Frame)
			slider:SetPos( 20, 80 )
			slider:SetSize( 300, 20 )
			slider:SetText( "Camera Focus" )
			slider:SetMin( -1 )
			slider:SetMax( 1 )
			slider:SetDecimals( 2 )
			slider:SetConVar( "lfs_camerafocus" )
			
			if LocalPlayer():IsSuperAdmin() then
				local slider = vgui.Create( "DNumSlider", Frame)
				slider:SetPos( 20, 120 )
				slider:SetSize( 300, 20 )
				slider:SetText( "Player Default AI-Team" )
				slider:SetMin( 0 )
				slider:SetMax( 2 )
				slider:SetDecimals( 0 )
				slider:SetConVar( "lfs_default_teams" )
				function slider:OnValueChanged( val )
					net.Start("lfs_admin_setconvar")
						net.WriteString("lfs_default_teams")
						net.WriteString( tostring( val ) )
					net.SendToServer()
				end
				
				local CheckBox = vgui.Create( "DCheckBoxLabel", Frame)
				CheckBox:SetPos( 20, 160 )
				CheckBox:SetText( "Freeze Player AI-Team" )
				CheckBox:SetValue( GetConVar( "lfs_freeze_teams" ):GetInt() )
				CheckBox:SizeToContents()
				function CheckBox:OnChange( val )
					net.Start("lfs_admin_setconvar")
						net.WriteString("lfs_freeze_teams")
						net.WriteString( tostring( val and 1 or 0 ) )
					net.SendToServer()
				end
			end
		end
	end
	
	hook.Add( "EntityEmitSound", "!!!lfs_volumemanager", function( t )

		if t.Entity.LFS then
			t.Volume = t.Volume * cvarVolume:GetFloat()
			return true
		end
	end )

	list.Set( "DesktopWindows", "LFSMenu", {
		title = "[LFS] Settings",
		icon = "icon64/iconlfs.png",
		init = function( icon, window )
			OpenMenu()
		end
	} )
	
	concommand.Add( "lfs_openmenu", function( ply, cmd, args )
		OpenMenu()
	end )
	
	timer.Simple(10, function()
		if not istable( scripted_ents ) or not isfunction( scripted_ents.GetList ) then return end
		
		for _, v in pairs( scripted_ents.GetList()  ) do
			if v and istable( v.t ) then
				if v.t.Spawnable then
					if v.t.Base and string.StartWith( v.t.Base:lower(), "lunasflightschool_basescript" ) then
						if v.t.Category and v.t.PrintName then
							if istable( killicon ) and isfunction( killicon.Add ) then
								killicon.Add( v.t.ClassName, "HUD/killicons/lfs_plane", Color( 255, 80, 0, 255 ) )
							end
						end
					end
				end
			end
		end
	end)
end

cvars.AddChangeCallback( "ai_ignoreplayers", function( convar, oldValue, newValue ) 
	simfphys.LFS.IgnorePlayers = tonumber( newValue ) ~=0
end)

http.Fetch("https://github.com/Blu-x92/LunasFlightSchool", function(contents,size) 
	local LatestVersion = tonumber( string.match( contents, "%s*(%d+)\n%s*</span>\n%s*commits" ) ) or 0  -- i took this from acf. I hope they don't mind
	
	if simfphys.LFS.GetVersion() >= LatestVersion then
		print("[LFS] is up to date, Version: "..simfphys.LFS.GetVersion())
	else
		print("[LFS] a newer version is available! Version: "..LatestVersion..", You have Version: "..simfphys.LFS.GetVersion())
		print("[LFS] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")
		
		if CLIENT then 
			timer.Simple(10, function() 
				chat.AddText( Color( 255, 0, 0 ), "[LFS] a newer version is available!" )
				surface.PlaySound( "lfs/notification/ding.ogg" )
				timer.Simple(0.5, function() surface.PlaySound( "lfs/notification/"..math.random(1,19)..".ogg" ) end )
			end)
		end
	end
end)