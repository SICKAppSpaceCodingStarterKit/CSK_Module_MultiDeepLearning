-- Block namespace
local BLOCK_NAMESPACE = 'MultiDeepLearning_FC.Process'
local nameOfModule = 'CSK_MultiDeepLearning'

--*************************************************************
--*************************************************************

-- Required to keep track of already allocated resource
local instanceTable = {}

local function process(handle, imageSource)

  local instance = Container.get(handle, 'Instance')

  -- Check if amount of instances is valid
  -- if not: add multiple additional instances
  while true do
    local amount = CSK_MultiDeepLearning.getInstancesAmount()
    if amount < instance then
      CSK_MultiDeepLearning.addInstance()
    else
      CSK_MultiDeepLearning.setInstance(instance)
      CSK_MultiDeepLearning.setRegisterEvent(imageSource)
      break
    end
  end

  local mode = Container.get(handle, 'Mode')
  if mode == 'CLASS_VALID' then
    return 'CSK_MultiDeepLearning.OnNewResult' .. tostring(instance)
  else
    return 'CSK_MultiDeepLearning.OnNewMeasuredClass' .. tostring(instance)
  end

end
Script.serveFunction(BLOCK_NAMESPACE .. '.process', process)

--*************************************************************
--*************************************************************

local function create(instance, mode)

  local fullInstanceName = tostring(instance) .. tostring(mode)

  -- Check if same instance is already configured
  if instance < 1 or instanceTable[fullInstanceName] ~= nil then
    _G.logger:warning(nameOfModule .. "Instance invalid or already in use, please choose another one")
    return nil
  else
    -- Otherwise create handle and store the restriced resource
    local handle = Container.create()
    instanceTable[fullInstanceName] = fullInstanceName
    Container.add(handle, 'Instance', instance)
    Container.add(handle, 'Mode', mode)
    Container.add(handle, "CB_Function", "")
    return handle
  end
end
Script.serveFunction(BLOCK_NAMESPACE .. '.create', create)

--- Function to reset instances if FlowConfig was cleared
local function handleOnClearOldFlow()
  Script.releaseObject(instanceTable)
  instanceTable = {}
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)
