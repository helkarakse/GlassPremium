--[[

	OTE GlassPremium Version 1.1 Release
	Do not modify, copy or distribute without permission of author
	Helkarakse & Shotexpert, 20131203
	
	TODO: Add color schemes v1.2
]]

-- Libraries
os.loadAPI("functions")
os.loadAPI("tickParser")
os.loadAPI("rssParser")

-- Variables
local jsonFile = "profile.txt"
local rssLink = "http://www.otegamers.com/index.php?app=core&module=global&section=rss&type=forums&id=24"
local configFile = "config"

-- Supposedly references like this improve performance
local tonumber = tonumber
local tostring = tostring
local tableInsert = table.insert
local pairs = pairs
local type = type
local switch = functions.switch

-- Color array
local colors = {
	headerStart = 0x18caf0,
	headerEnd = 0x9fedfd,
	white = 0xFFFFFF,
	red = 0xFF0000,
	black = 0x000000,
	green = 0x00FF00,
	blue = 0x0000FF,
	yellow = 0xFFFF00,
}

local colorSchemes = {}

-- Default config function
local function getDefaultConfig(key)
	-- default settings
	local array = {
		textColor = {
			name = "Text Color",
			keyword = "color",
			value = colors.white,
			type = "color"
		},
		textSize = {
			name = "Text Size",
			keyword = "size",
			value = 1,
			formattedValue = "1"
		},
		opacity = {
			name = "Opacity",
			keyword = "opacity",
			value = 0.15,
			formattedValue = "0.15"
		},
		windowStartColor = {
			name = "Window Gradient Start Color",
			keyword = "window start",
			value = colors.headerStart,
			type = "color"
		},
		windowEndColor = {
			name = "Window Gradient End Color",
			keyword = "window end",
			value = colors.headerEnd,
			type = "color"
		}
	}
	
	if (key) then
		return array[key]
	else
		return array
	end
end

-- Load configuration file
local configExists, configArray = functions.readTable(configFile)
if (configExists ~= true) then
	functions.debug("Config file not found, creating config array in memory")
	configArray = getDefaultConfig()
	functions.debug("Writing the config file to disk")
	functions.writeTable(configArray, configFile)
end

-- Glass elements
local bridge, mainBox, edgeBox
local header, headerText, clockText, tpsText, lastUpdatedText, rssUpdatedText

-- Display limit
local limit = 5

-- For the refresh loop
local lastUpdated, currentFileSize

-- Text size array
local constSizeSmall = 0.6
local constSizeNormal = 1
local constSizeLarge = 1.25

local size = {
	small = constSizeSmall * configArray.textSize.value, normal = constSizeNormal  * configArray.textSize.value, large = constSizeLarge  * configArray.textSize.value
}

-- Data arrays
local entitiesArray, chunksArray, typesArray, callsArray

-- Positioning variables
local headerHeight = (size.small * 10)
local tpsHeight = (size.normal * 10)
local lineMultiplier = headerHeight

local positionArray = {
	{x = 10, y = 65, width = 95 * configArray.textSize.value, height = (size.normal * 10) + (size.large * 10) + 12.5}, -- small
	{x = 10, y = 65, width = 260 * configArray.textSize.value, height = (28 * lineMultiplier) + 10}, -- large
	{x = 10, y = 65, width = 225 * configArray.textSize.value, height = (12 * lineMultiplier) + 10}, -- rss
	{x = 10, y = 65, width = 200 * configArray.textSize.value, height = ((functions.getTableCount(configArray) + 6) * lineMultiplier)  + 10}, -- options
	{x = 10, y = 65, width = 250 * configArray.textSize.value, height = (20 * lineMultiplier) + 10} -- help
}

-- Event handling related
local currentDisplay = 1 -- main display

-- Functions
local function drawMain(inputX, inputY, inputWidth, inputHeight)
	mainBox = bridge.addBox(inputX, inputY, inputWidth, inputHeight, configArray.windowEndColor.value, configArray.opacity.value)
	edgeBox = bridge.addGradientBox(inputX, inputY + inputHeight - 2, inputWidth, 2, configArray.windowStartColor.value, 1, configArray.windowEndColor.value, 0, 2)
end

local function drawHeader(inputX, inputY, inputWidth)
	header = bridge.addGradientBox(inputX - 5, inputY, inputWidth, headerHeight, configArray.windowEndColor.value, 0, configArray.windowStartColor.value, 1, 2)
	header.setZIndex(2)
	headerText = bridge.addText(inputX, inputY + 1, "OTE Glass (c) Helk & Shot 2013", configArray.textColor.value)
	headerText.setZIndex(3)
	headerText.setScale(size.small)
end

local function drawTps(inputX, inputY)
	local width = positionArray[currentDisplay].width
	local height = positionArray[currentDisplay].height
	
	local tps = tickParser.getTps()
	local check = switch {
		[1] = function()
			local tpsLabelText = bridge.addText(inputX + width - (55 * configArray.textSize.value), inputY + height - tpsHeight, "TPS:", configArray.textColor.value)
			tpsLabelText.setScale(size.normal)
			tpsLabelText.setZIndex(4)
			
			tpsText = bridge.addText(inputX + width - (30 * configArray.textSize.value), inputY + height - tpsHeight, tps, tickParser.getTpsHexColor(tps))
			tpsText.setScale(size.normal)
			tpsText.setZIndex(4)
			
			clockText = bridge.addText(inputX + 5, inputY + headerHeight + 5, "", configArray.textColor.value)
			clockText.setScale(size.large)
			clockText.setZIndex(4)
		end,
		[2] = function()
			local tpsLabelText = bridge.addText(inputX + width - (55 * configArray.textSize.value), inputY + height - tpsHeight, "TPS:", configArray.textColor.value)
			tpsLabelText.setScale(size.normal)
			tpsLabelText.setZIndex(4)
			
			tpsText = bridge.addText(inputX + width - (30 * configArray.textSize.value), inputY + height - tpsHeight, tps, tickParser.getTpsHexColor(tps))
			tpsText.setScale(size.normal)
			tpsText.setZIndex(4)
			
			clockText = bridge.addText(inputX + width - (30 * configArray.textSize.value), inputY + 1, "", configArray.textColor.value)
			clockText.setScale(size.small)
			clockText.setZIndex(4)
			
			local lastUpdatedLabelText = bridge.addText(inputX + width - (100 * configArray.textSize.value), inputY + 1, "Last Updated:", configArray.textColor.value)
			lastUpdatedLabelText.setScale(size.small)
			lastUpdatedLabelText.setZIndex(4)
			
			lastUpdatedText = bridge.addText(inputX + width - (55 * configArray.textSize.value), inputY + 1, "", configArray.textColor.value)
			lastUpdatedText.setScale(size.small)
			lastUpdatedText.setZIndex(4)
		end,
		[3] = function()
			local rssUpdatedLabelText = bridge.addText(inputX + width - (125 * configArray.textSize.value), inputY + 1, "Last Updated:", configArray.textColor.value)
			rssUpdatedLabelText.setScale(size.small)
			rssUpdatedLabelText.setZIndex(4)
			
			rssUpdatedText = bridge.addText(inputX + width - (80 * configArray.textSize.value), inputY + 1, "", configArray.textColor.value)
			rssUpdatedText.setScale(size.small)
			rssUpdatedText.setZIndex(4)
		end
	}
	
	check:case(currentDisplay)
end

local function drawEntities(inputX, inputY)
	local data = tickParser.getSingleEntities()
	entitiesArray = {}
	
	tableInsert(entitiesArray, bridge.addText(inputX, inputY, "Entity Name:", configArray.textColor.value).setScale(size.small))
	tableInsert(entitiesArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY, "Position:", configArray.textColor.value).setScale(size.small))
	tableInsert(entitiesArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY, "%", configArray.textColor.value).setScale(size.small))
	tableInsert(entitiesArray, bridge.addText(inputX + (200 * configArray.textSize.value), inputY, "Dimension:", configArray.textColor.value).setScale(size.small))
	
	for i = 1, limit do
		tableInsert(entitiesArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].name, configArray.textColor.value).setScale(size.small))
		tableInsert(entitiesArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].position, configArray.textColor.value).setScale(size.small))
		tableInsert(entitiesArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
		tableInsert(entitiesArray, bridge.addText(inputX + (200 * configArray.textSize.value), inputY + (lineMultiplier * i), tickParser.getDimensionName(tickParser.getServerId(os.getComputerID()), data[i].dimId), configArray.textColor.value).setScale(size.small))
	end
	
	for i = 1, #entitiesArray do
		entitiesArray[i].setZIndex(5)
	end
end

local function drawChunks(inputX, inputY)
	local data = tickParser.getChunks()
	chunksArray = {}
	
	tableInsert(chunksArray, bridge.addText(inputX, inputY, "Chunk Position (X, Z):", configArray.textColor.value).setScale(size.small))
	tableInsert(chunksArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY, "Time/Tick:", configArray.textColor.value).setScale(size.small))
	tableInsert(chunksArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY, "%", configArray.textColor.value).setScale(size.small))
	
	for i = 1, limit do
		tableInsert(chunksArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].positionX .. ", " .. data[i].positionZ, configArray.textColor.value).setScale(size.small))
		tableInsert(chunksArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].time, configArray.textColor.value).setScale(size.small))
		tableInsert(chunksArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
	end
	
	for i = 1, #chunksArray do
		chunksArray[i].setZIndex(5)
	end
end

local function drawTypes(inputX, inputY)
	local data = tickParser.getEntityByTypes()
	typesArray = {}
	
	tableInsert(typesArray, bridge.addText(inputX, inputY, "Entity Type:", configArray.textColor.value).setScale(size.small))
	tableInsert(typesArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY, "Time/Tick:", configArray.textColor.value).setScale(size.small))
	tableInsert(typesArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY, "%", configArray.textColor.value).setScale(size.small))
	
	for i = 1, limit do
		tableInsert(typesArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].type, configArray.textColor.value).setScale(size.small))
		tableInsert(typesArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].time, configArray.textColor.value).setScale(size.small))
		tableInsert(typesArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
	end
	
	for i = 1, #typesArray do
		typesArray[i].setZIndex(5)
	end
end

local function drawCalls(inputX, inputY)
	local data = tickParser.getAverageCalls()
	callsArray = {}
	
	tableInsert(callsArray, bridge.addText(inputX, inputY, "Entity Name:", configArray.textColor.value).setScale(size.small))
	tableInsert(callsArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY, "Time/Tick:", configArray.textColor.value).setScale(size.small))
	tableInsert(callsArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY, "Average Calls", configArray.textColor.value).setScale(size.small))
	
	for i = 1, limit do
		tableInsert(callsArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].name, configArray.textColor.value).setScale(size.small))
		tableInsert(callsArray, bridge.addText(inputX + (125 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].time, configArray.textColor.value).setScale(size.small))
		tableInsert(callsArray, bridge.addText(inputX + (175 * configArray.textSize.value), inputY + (lineMultiplier * i), data[i].calls, configArray.textColor.value).setScale(size.small))
	end
	
	for i = 1, #callsArray do
		callsArray[i].setZIndex(5)
	end
end

local function drawSanta(inputX, inputY)
	local boxArray = {}
	--white parts
	tableInsert(boxArray, bridge.addBox(inputX, inputY-9, 2, 2, colors.white, 1))
	tableInsert(boxArray, bridge.addBox(inputX-9, inputY-1, 9, 2, colors.white, 1))
	
	--red parts
	tableInsert(boxArray, bridge.addBox(inputX-2, inputY-8, 2, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-3, inputY-7, 4, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-4, inputY-6, 5, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-5, inputY-5, 5, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-6, inputY-4, 5, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-7, inputY-3, 6, 1, colors.red, 1))
	tableInsert(boxArray, bridge.addBox(inputX-8, inputY-2, 8, 1, colors.red, 1))
	
	--set zindexes
	for key, value in pairs(boxArray) do
		value.setZIndex(7)
	end
end

local function drawData()
	drawEntities(positionArray[currentDisplay].x + 5, positionArray[currentDisplay].y + headerHeight + 5)
	drawChunks(positionArray[currentDisplay].x + 5, positionArray[currentDisplay].y + headerHeight + 5 + ((limit + 2) * lineMultiplier))
	drawTypes(positionArray[currentDisplay].x + 5, positionArray[currentDisplay].y + headerHeight + 5 + ((limit + 2) * 2 * lineMultiplier))
	drawCalls(positionArray[currentDisplay].x + 5, positionArray[currentDisplay].y + headerHeight + 5 + ((limit + 2) * 3 * lineMultiplier))
end

local function drawRss(inputX, inputY)
	rssUpdatedText.setText(rssParser.convertDate(rssParser.getPubDate()))
	
	local data = rssParser.getItems()
	local rssArray = {}
	
	tableInsert(rssArray, bridge.addText(inputX, inputY, "Title", configArray.textColor.value).setScale(size.small))
	tableInsert(rssArray, bridge.addText(inputX + (150 * configArray.textSize.value), inputY, "Date", configArray.textColor.value).setScale(size.small))
	
	local j = 1
	for key, value in pairs(data) do
		local title, link, desc, pubDate, guid = rssParser.parseItem(value)
		tableInsert(rssArray, bridge.addText(inputX, inputY + (lineMultiplier * j), functions.truncate(title, 50), configArray.textColor.value).setScale(size.small))
		tableInsert(rssArray, bridge.addText(inputX + (150 * configArray.textSize.value), inputY + (lineMultiplier * j), rssParser.convertDate(pubDate), configArray.textColor.value).setScale(size.small))
		j = j + 1
	end
	
	for i = 1, #rssArray do
		rssArray[i].setZIndex(5)
	end
end

local function drawOptions(inputX, inputY)
	local optionsArray = {}
	
	tableInsert(optionsArray, bridge.addText(inputX, inputY, "Option Name", configArray.textColor.value).setScale(size.small))
	tableInsert(optionsArray, bridge.addText(inputX + (100 * configArray.textSize.value), inputY, "Keyword", configArray.textColor.value).setScale(size.small))
	tableInsert(optionsArray, bridge.addText(inputX + (150 * configArray.textSize.value), inputY, "Value", configArray.textColor.value).setScale(size.small))
	
	local j = 1
	for key, value in pairs(configArray) do
		tableInsert(optionsArray, bridge.addText(inputX, inputY + (lineMultiplier * j), value.name, configArray.textColor.value).setScale(size.small))
		tableInsert(optionsArray, bridge.addText(inputX + (100 * configArray.textSize.value), inputY + (lineMultiplier * j), value.keyword, configArray.textColor.value).setScale(size.small))
		
		if (value.type == "color") then
			tableInsert(optionsArray, bridge.addText(inputX + (150 * configArray.textSize.value), inputY + (lineMultiplier * j), functions.decToHex(value.value), configArray.textColor.value).setScale(size.small))
		else
			tableInsert(optionsArray, bridge.addText(inputX + (150 * configArray.textSize.value), inputY + (lineMultiplier * j), tostring(value.value), configArray.textColor.value).setScale(size.small))
		end
		j = j + 1
	end
	
	j = j + 1
	tableInsert(optionsArray, bridge.addText(inputX, inputY + (lineMultiplier * j), "To change the options, type $$<keyword> <value> in chat.", configArray.textColor.value).setScale(size.small))
	j = j + 1
	tableInsert(optionsArray, bridge.addText(inputX, inputY + (lineMultiplier * j), "To reset all the options, type $$reset all", configArray.textColor.value).setScale(size.small))
	j = j + 1
	tableInsert(optionsArray, bridge.addText(inputX, inputY + (lineMultiplier * j), "To reset specific options, type $$reset <keyword>", configArray.textColor.value).setScale(size.small))
	
	for i = 1, #optionsArray do
		optionsArray[i].setZIndex(5)
	end
end

local function drawScreen()
	local xPos = positionArray[currentDisplay].x
	local yPos = positionArray[currentDisplay].y
	local width = positionArray[currentDisplay].width
	local height = positionArray[currentDisplay].height
	
	bridge.clear()
	local check = switch {
		[1] = function()
			-- draw main, header and tps
			drawMain(xPos, yPos, width, height)
			drawHeader(xPos, yPos, width)
			drawTps(xPos, yPos)
			drawSanta(xPos + 10, yPos - 1)
			end,
		[2] = function()
			-- draw main, header, tps and data
			drawMain(xPos, yPos, width, height)
			drawHeader(xPos, yPos, width)
			drawTps(xPos, yPos)
			drawData()
			drawSanta(xPos + 10, yPos - 1)
			end,
		[3] = function()
			drawMain(xPos, yPos, width, height)
			drawHeader(xPos, yPos, width)
			drawTps(xPos, yPos)
			drawRss(xPos + 5, yPos + headerHeight + 5)
			drawSanta(xPos + 10, yPos - 1)
			end,
		[4] = function()
			drawMain(xPos, yPos, width, height)
			drawHeader(xPos, yPos, width)
			drawOptions(xPos + 5, yPos  + headerHeight + 5)
			drawSanta(xPos + 10, yPos - 1)
			end,
		[5] = function()
			drawMain(xPos, yPos, width, height)
			drawHeader(xPos, yPos, width)
			drawSanta(xPos + 10, yPos - 1)
			end,
	}
	
	check:case(currentDisplay)
end

-- Data Retrieval
local function getRssData()
	local xmlString
	local data = http.get(rssLink)
	if (data) then
    	functions.debug("XML file successfully retrieved.")
		xmlString = data.readAll()
		rssParser.parseData(xmlString)
		return true
	else
		functions.debug("Could not retrieve xml file.")
		return false
	end
end

local function getTickData()
	local file = fs.open(jsonFile, "r")
	local text = file.readAll()
	file.close()
	
	-- reset the updated time and the new file size
	currentFileSize = fs.getSize(jsonFile)
	functions.debug("Setting the current file size to: ", currentFileSize)
	lastUpdated = 0
	
	-- re-parse the data
	tickParser.parseData(text)
end

-- Loops
local tickRefreshLoop = function()
	lastUpdated = 0
	while true do
		if (fs.getSize(jsonFile) ~= currentFileSize) then
			-- Get the new data
			functions.debug("File size of profile.txt has changed. Assuming new data.")
			getTickData()
			
			-- redraw the new data
			functions.debug("Current display is: ", currentDisplay)
			drawScreen()
		else
			if (currentDisplay == 2) then
				lastUpdatedText.setText(lastUpdated .. "s")
			end
		end
		
		lastUpdated = lastUpdated + 1
		sleep(1)
	end
end

local rssRefreshLoop = function()
	while true do
		getRssData()
		if (currentDisplay == 3) then
			rssUpdatedText.setText(rssParser.convertDate(rssParser.getPubDate()))
		end
		sleep(60)
	end
end

local clockRefreshLoop = function()
	while true do
		-- no currentDisplay checks because clock will be on all of them
		local nTime = os.time()
		clockText.setText(textutils.formatTime(nTime, false))
		sleep(1)
	end
end

-- User config functions
-- Update the text size
local function updateSize(newSize)
	functions.debug("Updating the text size from ", configArray.textSize.value, " to ", newSize)
	-- update the size array with the new sizes
	size.small = constSizeSmall * newSize
	size.normal = constSizeNormal * newSize
	size.large = constSizeLarge * newSize
	
	-- update the header, tpsHeights and lineMultiplier as the sizes changed
	headerHeight = (size.small * 10)
	tpsHeight = (size.normal * 10)
	lineMultiplier = headerHeight

	positionArray = {
		{x = 10, y = 65, width = 95 * newSize, height = (size.normal * 10) + (size.large * 10) + 12.5}, -- small
		{x = 10, y = 65, width = 260 * newSize, height = (28 * lineMultiplier) + 10}, -- large
		{x = 10, y = 65, width = 225 * newSize, height = (12 * lineMultiplier) + 10}, -- rss
		{x = 10, y = 65, width = 200 * newSize, height = ((functions.getTableCount(configArray) + 6) * lineMultiplier)  + 10}, -- options
		{x = 10, y = 65, width = 250 * newSize, height = (20 * lineMultiplier) + 10} -- help
	}
	
	configArray.textSize.value = newSize
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

-- Update the opacity of the main box
local function updateOpacity(newOpacity)
	functions.debug("Updating the opacity from ", configArray.opacity.value, " to ", newOpacity)
	configArray.opacity.value = newOpacity
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

local function updateTextColor(newColor)
	newColor = tonumber("0x" .. newColor)
	functions.debug("Updating the text color from ", functions.decToHex(configArray.textColor.value), " to ", functions.decToHex(newColor))
	configArray.textColor.value = newColor
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

local function updateWindowStartColor(newColor)
	newColor = tonumber("0x" .. newColor)
	functions.debug("Updating the text color from ", functions.decToHex(configArray.windowStartColor.value), " to ", functions.decToHex(newColor))
	configArray.windowStartColor.value = newColor
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

local function updateWindowEndColor(newColor)
	newColor = tonumber("0x" .. newColor)
	functions.debug("Updating the text color from ", functions.decToHex(configArray.windowEndColor.value), " to ", functions.decToHex(newColor))
	configArray.windowEndColor.value = newColor
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

local function resetConfig(specificKey)
	functions.debug("Resetting the configuration for: ", specificKey)
	local defaultConfig = getDefaultConfig(specificKey)
	configArray[specificKey] = defaultConfig
	
	if (specificKey == "textSize") then
		updateSize(configArray.textSize.value)
	end
	
	functions.debug("Writing data to disk")
	functions.writeTable(configArray, configFile)
end

-- Event handler for chat commands
local eventHandler = function()
	while true do
		local event, message = os.pullEvent("chat_command")
		
		local args = functions.explode(" ", message)
		if (args[1] == "show") then
			if (args[2] == nil) then
				-- show with no args means show the interface
				drawScreen()
			else
				local screenId = 0
				local check = switch {
					["mini"] = function()
							screenId = 1
						end,
					["tps"] = function()
							screenId = 2
						end,
					["rss"] = function()
							screenId = 3
						end,
					["options"] = function()
							screenId = 4
						end,
					default = function()
							screenId = 0
						end
				}
				
				check:case(tostring(args[2]))
				
				-- only change the screen if screenId is not 0
				if (screenId > 0) then
					functions.debug("Changing screen to: ", screenId)
					currentDisplay = tonumber(screenId)
					drawScreen()
				end
			end
		elseif (args[1] == "hide") then
			bridge.clear()
			drawHeader(positionArray[currentDisplay].x, positionArray[currentDisplay].y, positionArray[currentDisplay].width)
			drawSanta(positionArray[currentDisplay].x + 10, positionArray[currentDisplay].y - 1)
		else
			local check = switch {
				[1] = function()
						-- tick and clock
						functions.debug("Message was retrieved by the event [1]: ", message)
					end,
				[2] = function()
						-- full tick
						functions.debug("Message was retrieved by the event [2]: ", message)
					end,
				[3] = function()
						-- rss
						functions.debug("Message was retrieved by the event [3]: ", message)
					end,
				[4] = function()
						-- options
						functions.debug("Message was retrieved by the event [4]: ", message)
						if (args[2] ~= nil) then
							local option = switch {
							["size"] = function()
									updateSize(tonumber(args[2]))
								end,
							["opacity"] = function()
									updateOpacity(tonumber(args[2]))
								end,
							["color"] = function()
									updateTextColor(args[2])
								end,
							["window"] = function()
									if (args[3] ~= nil) then
										if (args[2] == "start") then
											updateWindowStartColor(args[3])
										elseif (args[2] == "end") then
											updateWindowEndColor(args[3])
										end
									end
								end,
							["reset"] = function()
									if (args[2] == "all") then
										functions.debug("Resetting configuration back to factory defaults")
										configArray = getDefaultConfig()
										updateSize(configArray.textSize.value)
										functions.debug("Writing the config file to disk")
										functions.writeTable(configArray, configFile)
									else
										local configKey = ""
										local configReset = switch {
											["size"] = function()
													configKey = "textSize"
												end,
											["opacity"] = function()
													configKey = "opacity"
												end,
											["color"] = function()
													configKey = "textColor"
												end,
											["window"] = function()
													if (args[3] ~= nil) then
														if (args[3] == "start") then
															configKey = "windowStartColor"
														elseif (args[3] == "end") then
															configKey = "windowEndColor"
														end
													end
												end,
											default = function()
												configKey = ""
											end,
										}
										
										configReset:case(tostring(args[2]))
										if (configKey ~= "") then
											resetConfig(configKey)
										end
									end
								end
							}
							
							option:case(tostring(args[1]))
							drawScreen()
						end
					end,
				[5] = function()
						-- help
						functions.debug("Message was retrieved by the event [5]:", message)
					end,
			}
			
			check:case(currentDisplay)
		end
	end
end

local function init()
	local hasBridge, bridgeDir = functions.locatePeripheral("glassesbridge")
	if (hasBridge ~= true) then
		functions.debug("Terminal glasses bridge peripheral required.")
	else
		functions.debug("Found terminal bridge peripheral at: ", bridgeDir)
		bridge = peripheral.wrap(bridgeDir)
		bridge.clear()
	end
	
	getTickData()
	drawScreen()
	
	parallel.waitForAll(tickRefreshLoop, clockRefreshLoop, rssRefreshLoop, eventHandler)
end

init()
