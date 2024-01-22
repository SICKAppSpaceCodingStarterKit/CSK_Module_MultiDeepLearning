---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}

-- Get SIM type / firmware to adapt device specific parameters
local typeName = Engine.getTypeName()
local firmware = Engine.getFirmwareVersion()
local deviceType

if typeName == 'AppStudioEmulator' or typeName == 'SICK AppEngine' then
  deviceType = 'AppStudioEmulator'
else
  deviceType = string.sub(typeName, 1, 7)
end

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Providing standard JSON functions
funcs.json = require('ImageProcessing/MultiDeepLearning/helper/Json')

--- Function to create a list with numbers
---@param size number Size of the list
---@return string list List of numbers
local function createStringListBySize(size)
  local list = "["
  if size >= 1 then
    list = list .. '"' .. tostring(1) .. '"'
  end
  if size >= 2 then
    for i=2, size do
      list = list .. ', ' .. '"' .. tostring(i) .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySize = createStringListBySize

--- Function to convert a table into a Container object
---@param content auto[] Lua Table to convert to Container
---@return Container cont Created Container
local function convertTable2Container(content)
  local cont = Container.create()
  for key, value in pairs(content) do
    if type(value) == 'table' then
      cont:add(key, convertTable2Container(value), nil)
    else
      cont:add(key, value, nil)
    end
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

--- Function to convert a Container into a table
---@param cont Container Container to convert to Lua table
---@return auto[] data Created Lua table
local function convertContainer2Table(cont)
  local data = {}
  local containerList = Container.list(cont)
  local containerCheck = false
  if tonumber(containerList[1]) then
    containerCheck = true
  end
  for i=1, #containerList do

    local subContainer

    if containerCheck then
      subContainer = Container.get(cont, tostring(i) .. '.00')
    else
      subContainer = Container.get(cont, containerList[i])
    end
    if type(subContainer) == 'userdata' then
      if Object.getType(subContainer) == "Container" then

        if containerCheck then
          table.insert(data, convertContainer2Table(subContainer))
        else
          data[containerList[i]] = convertContainer2Table(subContainer)
        end

      else
        if containerCheck then
          table.insert(data, subContainer)
        else
          data[containerList[i]] = subContainer
        end
      end
    else
      if containerCheck then
        table.insert(data, subContainer)
      else
        data[containerList[i]] = subContainer
      end
    end
  end
  return data
end
funcs.convertContainer2Table = convertContainer2Table

--- Function to get content list out of table
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as string, internally seperated by ','
local function createContentList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return table.concat(sortedTable, ',')
end
funcs.createContentList = createContentList

--- Function to get content list as JSON string
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as JSON string
local function createJsonList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return funcs.json.encode(sortedTable)
end
funcs.createJsonList = createJsonList

--- Function to create a list from table
---@param content string[] Table with data entries
---@return string list String list
local function createStringListBySimpleTable(content)
  local list = "["
  if #content >= 1 then
    list = list .. '"' .. content[1] .. '"'
  end
  if #content >= 2 then
    for i=2, #content do
      list = list .. ', ' .. '"' .. content[i] .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySimpleTable = createStringListBySimpleTable

-- Function to split string by dot e.g. "a.bbc.d" == {"a", "bbc", "d"}
---@param str string String to separate
---@return splitString string[1+] Splitted version parts
local function splitByDot(str)
  str = str or ""
  local splitString, count = {}, 0
  str:gsub("([^%.]+)", function(c)
    count = count + 1
    splitString[count] = c
  end)
  return splitString
end
funcs.splitByDot = splitByDot

--- Function to check if firmware supports modules feature
---@param checkMajor string Major version
---@param checkMinor string Minor version
---@param checkPatch string Patch version
---@return firmwareOK bool Status if firmware matches
local function checkFirmware(checkDevice, checkMajor, checkMinor, checkPatch)

  local firmwareOK = false
  if checkDevice == deviceType then
    local fwComponents = splitByDot(firmware)

    if #fwComponents == 3 then

      local major = tonumber(fwComponents[1])
      local minor = tonumber(fwComponents[2])
      local patch = tonumber(fwComponents[3])

      -- Check if version is valid
      if major > checkMajor then
        firmwareOK = true
      elseif major == checkMajor then
        if minor > checkMinor then
          firmwareOK = true
        elseif minor == checkMinor and patch >= checkPatch then
            firmwareOK = true
        end
      end
    end
  else
    firmwareOK = true
  end

  return firmwareOK
end
funcs.checkFirmware = checkFirmware

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************