simfphys = istable( simfphys ) and simfphys or {} -- lets check if the simfphys table exists. if not, create it!
simfphys.LFS = {} -- lets add another table for this project. We will be storing all our global functions and variables here. LFS means LunasFlightSchool

simfphys.LFS.VERSION = 32 -- don't forget to update this

function simfphys.LFS.GetVersion()
	return simfphys.LFS.VERSION
end

http.Fetch("https://github.com/Blu-x92/LunasFlightSchool", function(contents,size) 
	local LatestVersion = tonumber( string.match( contents, "%s*(%d+)\n%s*</span>\n%s*commits" ) ) or 0  -- i took this from acf. I hope they don't mind
	
	if simfphys.LFS.GetVersion() >= LatestVersion then
		print("[LFS][simfphys planes] is up to date, Version: "..simfphys.LFS.GetVersion())
	else
		print("[LFS][simfphys planes] a newer version is available! Version: "..LatestVersion..", You have Version: "..simfphys.LFS.GetVersion())
		print("[LFS][simfphys planes] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")
		
		if CLIENT then 
			timer.Simple(10, function() 
				chat.AddText( Color( 255, 0, 0 ), "[LFS][simfphys planes] a newer version is available!" )
				surface.PlaySound( "lfs/notification.ogg" ) 
			end)
		end
	end
end)


local meta = FindMetaTable( "Player" )

function meta:lfsGetPlane()
	if not self:InVehicle() then return NULL end
	
	local Pod = self:GetVehicle()
	
	if not IsValid( Pod ) then return NULL end
	
	if Pod.LFSchecked == true then
		
		return Pod.LFSBaseEnt
		
	elseif Pod.LFSchecked == nil then
		
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then Pod.LFSchecked = false return NULL end
		
		if not Parent:GetClass():lower():StartWith( "lunasflightschool" ) then Pod.LFSchecked = false return NULL end
		
		Pod.LFSchecked = true
		Pod.LFSBaseEnt = Parent
		
		return Parent
	else
		return NULL
	end
end

if SERVER then util.AddNetworkString( "lfs_failstartnotify" ) end