--[[

	OTE GlassPremium Master Control
	Do not modify, copy or distribute without permission of author
	Helkarakse 20131213
	
]]

-- Libraries
os.loadAPI("functions")

-- Variables
local modemFrequency = 1
local modem

-- References
local peripheral = peripheral
local tonumber = tonumber

-- Arrays
local menuOptions = {
	{name = "[1] Perform configuration backup"},
	{name = "[2] Perform rolling reboots"},
	{name = "[3] Reboot this computer"}
}

local function displayMenu()
	while true do
		term.clear()
		term.setCursorPos(1, 1)
	
		for i = 1, #menuOptions do
			print(menuOptions[i].name);
		end
		
		print("Enter option:")
		local option = read()
		
		if (tonumber(option) == 1) then
			modem.transmit(modemFrequency, modemFrequency, "backup")
		elseif (tonumber(option) == 2) then
			modem.transmit(modemFrequency, modemFrequency, "reboot")
		elseif (tonumber(option) == 3) then
			os.reboot()
		end
	end
end

local function init()
	local hasModem, modemDir = functions.locatePeripheral("modem")
	if (hasModem) then
		modem = peripheral.wrap(modemDir)
		modem.open(modemFrequency)
	end
	
	displayMenu()
end

init()