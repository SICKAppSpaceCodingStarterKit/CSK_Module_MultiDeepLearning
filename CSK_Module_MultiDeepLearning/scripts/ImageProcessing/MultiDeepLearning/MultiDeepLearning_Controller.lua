---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the multiDeepLearning_Model and multiDeepLearning_Instances
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_MultiDeepLearning'

local funcs = {}

-- Timer to update UI via events after page was loaded
local tmrMultiDeepLearning = Timer.create()
tmrMultiDeepLearning:setExpirationTime(300)
tmrMultiDeepLearning:setPeriodic(false)

local multiDeepLearning_Model -- Reference to model handle
local multiDeepLearning_Instances -- Reference to instances handle
local selectedInstance = 1 -- Which DNN instance is currently selected
local helperFuncs = require('ImageProcessing/MultiDeepLearning/helper/funcs') -- general helper functions

-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------
local function emptyFunction()
end
Script.serveFunction("CSK_MultiDeepLearning.processImageNUM", emptyFunction)
Script.serveFunction("CSK_MultiDeepLearning.processImageWithScoresNUM", emptyFunction)

Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredClassNUM", "MultiDeepLearning_OnNewMeasuredClassNUM")
Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredScoreNUM", "MultiDeepLearning_OnNewMeasuredScoreNUM")
Script.serveEvent("CSK_MultiDeepLearning.OnNewResultNUM", "MultiDeepLearning_OnNewResultNUM")
Script.serveEvent("CSK_MultiDeepLearning.OnNewFullResultWithImageNUM", "MultiDeepLearning_OnNewFullResultWithImageNUM")
Script.serveEvent("CSK_MultiDeepLearning.OnNewValueToForwardNUM", "MultiDeepLearning_OnNewValueToForwardNUM")
-- Demo event, see CSK_Module_MultiDeepLearning.lua
Script.serveEvent("CSK_MultiDeepLearning.TestImage", "TestImage") --> Create event to listen to receive a image to process
----------------------------------------------------------------

-- Real events
--------------------------------------------------
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusModuleVersion', 'MultiDeepLearning_OnNewStatusModuleVersion')
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusCSKStyle', 'MultiDeepLearning_OnNewStatusCSKStyle')
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusModuleIsActive', 'MultiDeepLearning_OnNewStatusModuleIsActive')

Script.serveEvent("CSK_MultiDeepLearning.OnNewImageProcessingParameter", "MultiDeepLearning_OnNewImageProcessingParameter")
Script.serveEvent("CSK_MultiDeepLearning.OnNewModelList", "MultiDeepLearning_OnNewModelList")
Script.serveEvent("CSK_MultiDeepLearning.OnNewInstanceList", "MultiDeepLearning_OnNewInstanceList")
Script.serveEvent("CSK_MultiDeepLearning.OnNewSelectedModel", "MultiDeepLearning_OnNewSelectedModel")
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusRegisteredEvent', 'MultiDeepLearning_OnNewStatusRegisteredEvent')
Script.serveEvent("CSK_MultiDeepLearning.OnNewModelFilename", "MultiDeepLearning_OnNewModelFilename")
Script.serveEvent("CSK_MultiDeepLearning.OnNewModelLabels", "MultiDeepLearning_OnNewModelLabels")
Script.serveEvent("CSK_MultiDeepLearning.OnNewValidScore", "MultiDeepLearning_OnNewValidScore")
Script.serveEvent("CSK_MultiDeepLearning.OnNewStatusShowImage", "MultiDeepLearning_OnNewStatusShowImage")
Script.serveEvent("CSK_MultiDeepLearning.OnNewViewerID", "MultiDeepLearning_OnNewViewerID")
Script.serveEvent("CSK_MultiDeepLearning.OnNewSelectedInstance", "MultiDeepLearning_OnNewSelectedInstance")
Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredScore", "MultiDeepLearning_OnNewMeasuredScore")
Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredClass", "MultiDeepLearning_OnNewMeasuredClass")
Script.serveEvent("CSK_MultiDeepLearning.OnNewResult", "MultiDeepLearning_OnNewResult")
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusForwardImage', 'MultiDeepLearning_OnNewStatusForwardImage')

Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusFlowConfigPriority', 'MultiDeepLearning_OnNewStatusFlowConfigPriority')
Script.serveEvent("CSK_MultiDeepLearning.OnNewParameterName", "MultiDeepLearning_OnNewParameterName")
Script.serveEvent("CSK_MultiDeepLearning.OnPersistentDataModuleAvailable", "MultiDeepLearning_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_MultiDeepLearning.OnNewStatusLoadParameterOnReboot", "MultiDeepLearning_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_MultiDeepLearning.OnDataLoadedOnReboot", "MultiDeepLearning_OnDataLoadedOnReboot")
Script.serveEvent("CSK_MultiDeepLearning.OnNewUploadPath", "MultiDeepLearning_OnNewUploadPath")
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusProcessWithScores', 'MultiDeepLearning_OnNewStatusProcessWithScores')
Script.serveEvent('CSK_MultiDeepLearning.OnNewStatusSortResultByIndex', 'MultiDeepLearning_OnNewStatusSortResultByIndex')

Script.serveEvent("CSK_MultiDeepLearning.OnUserLevelOperatorActive", "MultiDeepLearning_OnUserLevelOperatorActive")
Script.serveEvent("CSK_MultiDeepLearning.OnUserLevelMaintenanceActive", "MultiDeepLearning_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_MultiDeepLearning.OnUserLevelServiceActive", "MultiDeepLearning_OnUserLevelServiceActive")
Script.serveEvent("CSK_MultiDeepLearning.OnUserLevelAdminActive", "MultiDeepLearning_OnUserLevelAdminActive")

Script.serveEvent('CSK_MultiDeepLearning.OnNewNumberOfInstances', 'MultiDeepLearning_OnNewNumberOfInstances')

-- ************************ UI Events End **********************************
--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("MultiDeepLearning_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("MultiDeepLearning_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("MultiDeepLearning_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("MultiDeepLearning_OnUserLevelAdminActive", status)
end

--- Function to forward data updates from instance threads to Controller part of module
---@param eventname string Eventname to use to forward value
---@param value auto Value to forward
local function handleOnNewValueToForward(eventname, value)
  Script.notifyEvent(eventname, value)
end

--- Function to get access to the multiDeepLearning_Model
---@param handle handle Handle of multiDeepLearning_Model object
local function setMultiDeepLearning_Model_Handle(handle)
  multiDeepLearning_Model = handle
  Script.releaseObject(handle)
end
funcs.setMultiDeepLearning_Model_Handle = setMultiDeepLearning_Model_Handle

--- Function to get access to the multiDeepLearning_Instances
---@param handle handle Handle of multiDeepLearning_Instances object
local function setMultiDeepLearning_Instances_Handle(handle)
  multiDeepLearning_Instances = handle
  if multiDeepLearning_Instances[selectedInstance].userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)

  for i = 1, #multiDeepLearning_Instances do
    Script.register("CSK_MultiDeepLearning.OnNewValueToForward" .. tostring(i) , handleOnNewValueToForward)
  end

end
funcs.setMultiDeepLearning_Instances_Handle = setMultiDeepLearning_Instances_Handle

--- Function to update user levels
local function updateUserLevel()
  if multiDeepLearning_Instances[selectedInstance].userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("MultiDeepLearning_OnUserLevelOperatorActive", true)
    Script.notifyEvent("MultiDeepLearning_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("MultiDeepLearning_OnUserLevelServiceActive", true)
    Script.notifyEvent("MultiDeepLearning_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrMultiDeepLearning()

  Script.notifyEvent('MultiDeepLearning_OnNewStatusModuleVersion', multiDeepLearning_Model.version)
  Script.notifyEvent('MultiDeepLearning_OnNewStatusCSKStyle', multiDeepLearning_Model.styleForUI)
  Script.notifyEvent("MultiDeepLearning_OnNewStatusModuleIsActive", _G.availableAPIs.default and _G.availableAPIs.specific)

  if _G.availableAPIs.default and _G.availableAPIs.specific then

    updateUserLevel()

    Script.notifyEvent('MultiDeepLearning_OnNewSelectedInstance', selectedInstance)

    Script.notifyEvent("MultiDeepLearning_OnNewStatusFlowConfigPriority", multiDeepLearning_Instances[selectedInstance].parameters.flowConfigPriority)
    Script.notifyEvent('MultiDeepLearning_OnNewParameterName', multiDeepLearning_Instances[selectedInstance].parametersName)
    Script.notifyEvent('MultiDeepLearning_OnPersistentDataModuleAvailable', multiDeepLearning_Instances[selectedInstance].persistentModuleAvailable)
    Script.notifyEvent('MultiDeepLearning_OnNewStatusLoadParameterOnReboot', multiDeepLearning_Instances[selectedInstance].parameterLoadOnReboot)

    Script.notifyEvent("MultiDeepLearning_OnNewStatusRegisteredEvent", multiDeepLearning_Instances[selectedInstance].parameters.registeredEvent)
    Script.notifyEvent("MultiDeepLearning_OnNewModelList", multiDeepLearning_Instances[selectedInstance].modelList)

    Script.notifyEvent("MultiDeepLearning_OnNewInstanceList", helperFuncs.createStringListBySize(#multiDeepLearning_Instances))
    Script.notifyEvent("MultiDeepLearning_OnNewSelectedModel", multiDeepLearning_Instances[selectedInstance].parameters.modelName)
    Script.notifyEvent("MultiDeepLearning_OnNewModelFilename", multiDeepLearning_Instances[selectedInstance].parameters.modelPath .. multiDeepLearning_Instances[selectedInstance].parameters.modelName)
    if multiDeepLearning_Instances[selectedInstance].currentModel then
      Script.notifyEvent('MultiDeepLearning_OnNewModelLabels', table.concat(MachineLearning.DeepNeuralNetwork.Model.getOutputNodeLabels(multiDeepLearning_Instances[selectedInstance].currentModel), ','))
    else
      Script.notifyEvent('MultiDeepLearning_OnNewModelLabels', '-')
    end
    Script.notifyEvent("MultiDeepLearning_OnNewMeasuredClass", '-')
    Script.notifyEvent("MultiDeepLearning_OnNewMeasuredScore", '-')
    Script.notifyEvent("MultiDeepLearning_OnNewValidScore", multiDeepLearning_Instances[selectedInstance].parameters.validScore)
    Script.notifyEvent("MultiDeepLearning_OnNewResult", false)
    Script.notifyEvent("MultiDeepLearning_OnNewStatusShowImage", multiDeepLearning_Instances[selectedInstance].parameters.showImage)
    Script.notifyEvent("MultiDeepLearning_OnNewViewerID", 'multiDeepLearningViewer' .. tostring(selectedInstance))
    Script.notifyEvent("MultiDeepLearning_OnNewStatusForwardImage", multiDeepLearning_Instances[selectedInstance].parameters.forwardResultWithImage)
    Script.notifyEvent("MultiDeepLearning_OnNewStatusProcessWithScores", multiDeepLearning_Instances[selectedInstance].parameters.processWithScores)
    Script.notifyEvent("MultiDeepLearning_OnNewStatusSortResultByIndex", multiDeepLearning_Instances[selectedInstance].parameters.sortResultByIndex)

    Script.notifyEvent("MultiDeepLearning_OnNewValidScore", multiDeepLearning_Instances[selectedInstance].parameters.validScore)
    Script.notifyEvent("MultiDeepLearning_OnNewUploadPath", multiDeepLearning_Instances[selectedInstance].parameters.modelPath)
    Script.notifyEvent("MultiDeepLearning_OnNewNumberOfInstances", tostring(#multiDeepLearning_Instances))
  end
end
Timer.register(tmrMultiDeepLearning, "OnExpired", handleOnExpiredTmrMultiDeepLearning)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    updateUserLevel() -- try to hide user specific content asap
  end
  tmrMultiDeepLearning:start()
  return ''
end
Script.serveFunction("CSK_MultiDeepLearning.pageCalled", pageCalled)

local function setInstance(dnnInstance)
  if #multiDeepLearning_Instances >= dnnInstance then
    selectedInstance = dnnInstance
    _G.logger:fine(nameOfModule .. ": New selected instance = " .. tostring(selectedInstance))
    multiDeepLearning_Instances[selectedInstance].activeInUI = true
    Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'activeInUI', true)
    pageCalled()
  else
    _G.logger:warning(nameOfModule .. ": Selected instance does not exist.")
  end
end
Script.serveFunction("CSK_MultiDeepLearning.setInstance", setInstance)

local function getInstancesAmount ()
  return #multiDeepLearning_Instances
end
Script.serveFunction("CSK_MultiDeepLearning.getInstancesAmount", getInstancesAmount)

local function addInstance()
  _G.logger:fine(nameOfModule .. ": Add instance")
  table.insert(multiDeepLearning_Instances, multiDeepLearning_Model.create(#multiDeepLearning_Instances+1))
  Script.deregister("CSK_MultiDeepLearning.OnNewValueToForward" .. tostring(#multiDeepLearning_Instances) , handleOnNewValueToForward)
  Script.register("CSK_MultiDeepLearning.OnNewValueToForward" .. tostring(#multiDeepLearning_Instances) , handleOnNewValueToForward)
  pageCalled()
end
Script.serveFunction('CSK_MultiDeepLearning.addInstance', addInstance)

local function resetInstances()
  _G.logger:info(nameOfModule .. ": Reset instances.")
  setInstance(1)
  local totalAmount = #multiDeepLearning_Instances
  while totalAmount > 1 do
    Script.releaseObject(multiDeepLearning_Instances[totalAmount])
    multiDeepLearning_Instances[totalAmount] =  nil
    totalAmount = totalAmount - 1
  end
  pageCalled()
end
Script.serveFunction('CSK_MultiDeepLearning.resetInstances', resetInstances)

local function setModelByName(modelName)
  local model = Object.load(multiDeepLearning_Instances[selectedInstance].parameters.modelPath .. modelName)

  if model then
    _G.logger:fine(nameOfModule .. ": Set new model = " ..  modelName)
    multiDeepLearning_Instances[selectedInstance].parameters.modelName = modelName
    multiDeepLearning_Instances[selectedInstance].currentModel = model
    Script.notifyEvent("MultiDeepLearning_OnNewModelFilename", multiDeepLearning_Instances[selectedInstance].parameters.modelPath .. modelName)
    Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'fullModelPath', multiDeepLearning_Instances[selectedInstance].parameters.modelPath .. modelName)

    local labels = MachineLearning.DeepNeuralNetwork.Model.getOutputNodeLabels(model)
    _G.logger:fine(nameOfModule .. ': Labels of model = ' .. table.concat(labels, ','))
    Script.notifyEvent('MultiDeepLearning_OnNewModelLabels', table.concat(labels, ','))
    Script.notifyEvent("MultiDeepLearning_OnNewSelectedModel", modelName)

  else
    _G.logger:warning(nameOfModule .. ": Loading of model did not work")
  end
end
Script.serveFunction("CSK_MultiDeepLearning.setModelByName", setModelByName)

local function uploadFinished(status)
  if status == true then
    _G.logger:info(nameOfModule .. ': New model was uploaded to the device.')
    local fileList = File.list(multiDeepLearning_Instances[selectedInstance].parameters.modelPath)
    if fileList ~= nil and #fileList ~= 0 then
      multiDeepLearning_Instances[selectedInstance].modelList = fileList
    else
      multiDeepLearning_Instances[selectedInstance].modelList = {'-'}
    end
    Script.notifyEvent("MultiDeepLearning_OnNewModelList", fileList)
  else
    _G.logger:warning(nameOfModule .. ': Error during upload of new model.')
  end
end
Script.serveFunction("CSK_MultiDeepLearning.uploadFinished", uploadFinished)

local function downloadFromDevice(status)
  _G.logger:fine(nameOfModule .. ': Downloading model from device = ' .. tostring(status))
end
Script.serveFunction("CSK_MultiDeepLearning.downloadFromDevice", downloadFromDevice)

local function setValidScore(value)
  _G.logger:fine(nameOfModule .. ": Set valid score to = " ..  tostring(value))
  multiDeepLearning_Instances[selectedInstance].parameters.validScore = value
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'validScore', multiDeepLearning_Instances[selectedInstance].parameters.validScore)
end
Script.serveFunction("CSK_MultiDeepLearning.setValidScore", setValidScore)

local function setViewerActive(status)
  _G.logger:fine(nameOfModule .. ": Set viewer active = " ..  tostring(status))
  multiDeepLearning_Instances[selectedInstance].parameters.showImage = status
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'showImage', multiDeepLearning_Instances[selectedInstance].parameters.showImage)
end
Script.serveFunction("CSK_MultiDeepLearning.setViewerActive", setViewerActive)

local function setRegisterEvent(event)
  _G.logger:fine(nameOfModule .. ": Set registeredEvent to = " ..  event)
  multiDeepLearning_Instances[selectedInstance].parameters.registeredEvent = event
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'registeredEvent', event)
end
Script.serveFunction("CSK_MultiDeepLearning.setRegisterEvent", setRegisterEvent)

local function setForwardImage(status)
  _G.logger:fine(nameOfModule .. ": Set forwardImage to = " ..  tostring(status))
  multiDeepLearning_Instances[selectedInstance].parameters.forwardResultWithImage = status
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'forwardResultWithImage', status)
end
Script.serveFunction('CSK_MultiDeepLearning.setForwardImage', setForwardImage)

local function setProcessWithScores(status)
  local valid = true
  if status == true then
    valid = helperFuncs.checkFirmware('SIM1012', 2,4,1) -- Only available on SIM1012 with firmare version >= 2.4.1
  end

  if valid then
    _G.logger:fine(nameOfModule .. ": Set processWithScores to = " ..  tostring(status))
    multiDeepLearning_Instances[selectedInstance].parameters.processWithScores = status
    Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'processWithScores', status)
    return true
  else
    _G.logger:warning(nameOfModule .. ": Firmware of SIM1012 is not compatible with this feature. Set processWithScores to false. Please change to SIM1012 firmware version 2.1.0, 2.2.0, 2.2.1 or >= 2.4.1.")
    multiDeepLearning_Instances[selectedInstance].parameters.processWithScores = false
    Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'processWithScores', false)
    Script.notifyEvent("MultiDeepLearning_OnNewStatusProcessWithScores", false)
    return false
  end
end
Script.serveFunction('CSK_MultiDeepLearning.setProcessWithScores', setProcessWithScores)

local function setSortResultByIndex(status)
  _G.logger:fine(nameOfModule .. ": Set sortResultByIndex to = " ..  tostring(status))
  multiDeepLearning_Instances[selectedInstance].parameters.sortResultByIndex = status
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'sortResultByIndex', status)
end
Script.serveFunction('CSK_MultiDeepLearning.setSortResultByIndex', setSortResultByIndex)

--- Function to update processing parameters within the processing threads
local function updateProcessingParameters()
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'showImage', multiDeepLearning_Instances[selectedInstance].parameters.showImage)
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'validScore', multiDeepLearning_Instances[selectedInstance].parameters.validScore)
  setModelByName(multiDeepLearning_Instances[selectedInstance].parameters.modelName)
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'registeredEvent', multiDeepLearning_Instances[selectedInstance].parameters.registeredEvent)
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'forwardResultWithImage',  multiDeepLearning_Instances[selectedInstance].parameters.forwardResultWithImage)
  setProcessWithScores(multiDeepLearning_Instances[selectedInstance].parameters.processWithScores)
  Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', selectedInstance, 'sortResultByIndex',  multiDeepLearning_Instances[selectedInstance].parameters.sortResultByIndex)
end

local function getStatusModuleActive()
  return _G.availableAPIs.default and _G.availableAPIs.specific
end
Script.serveFunction('CSK_MultiDeepLearning.getStatusModuleActive', getStatusModuleActive)

local function clearFlowConfigRelevantConfiguration()
  for i = 1, #multiDeepLearning_Instances do
    multiDeepLearning_Instances[i].parameters.registeredEvent = ''
    Script.notifyEvent('MultiDeepLearning_OnNewImageProcessingParameter', i, 'deregisterFromEvent', '')
    Script.notifyEvent('MultiDeepLearning_OnNewStatusRegisteredEvent', '')
  end
end
Script.serveFunction('CSK_MultiDeepLearning.clearFlowConfigRelevantConfiguration', clearFlowConfigRelevantConfiguration)

local function getParameters(instanceNo)
  if instanceNo <= #multiDeepLearning_Instances then
    return helperFuncs.json.encode(multiDeepLearning_Instances[instanceNo].parameters)
  else
    return ''
  end
end
Script.serveFunction('CSK_MultiDeepLearning.getParameters', getParameters)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:fine(nameOfModule .. ": Set parameter name = " ..  tostring(name))
  multiDeepLearning_Instances[selectedInstance].parametersName = name
end
Script.serveFunction("CSK_MultiDeepLearning.setParameterName", setParameterName)

local function sendParameters(noDataSave)
  if multiDeepLearning_Instances[selectedInstance].persistentModuleAvailable then
    CSK_PersistentData.addParameter(helperFuncs.convertTable2Container(multiDeepLearning_Instances[selectedInstance].parameters), multiDeepLearning_Instances[selectedInstance].parametersName)

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiDeepLearning_Instances[selectedInstance].parametersName, multiDeepLearning_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance), #multiDeepLearning_Instances)
    else
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiDeepLearning_Instances[selectedInstance].parametersName, multiDeepLearning_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance))
    end

    _G.logger:fine(nameOfModule .. ": Send DeepLearning parameters with name '" .. multiDeepLearning_Instances[selectedInstance].parametersName .. "' to CSK_PersistentData module.")
    if not noDataSave then
      CSK_PersistentData.saveData()
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_MultiDeepLearning.sendParameters", sendParameters)

local function loadParameters()
  if multiDeepLearning_Instances[selectedInstance].persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(multiDeepLearning_Instances[selectedInstance].parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters for deepLearningInstance " .. tostring(selectedInstance) .. " from CSK_PersistentData module.")
      multiDeepLearning_Instances[selectedInstance].parameters = helperFuncs.convertContainer2Table(data)
      updateProcessingParameters()
      pageCalled()
      return true
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
      pageCalled()
      return false
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
    pageCalled()
    return false
  end
end
Script.serveFunction("CSK_MultiDeepLearning.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  multiDeepLearning_Instances[selectedInstance].parameterLoadOnReboot = status
  _G.logger:fine(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
  Script.notifyEvent("MultiDeepLearning_OnNewStatusLoadParameterOnReboot", status)
end
Script.serveFunction("CSK_MultiDeepLearning.setLoadOnReboot", setLoadOnReboot)

local function setFlowConfigPriority(status)
  multiDeepLearning_Instances[selectedInstance].parameters.flowConfigPriority = status
  _G.logger:fine(nameOfModule .. ": Set new status of FlowConfig priority: " .. tostring(status))
  Script.notifyEvent("MultiDeepLearning_OnNewStatusFlowConfigPriority", multiDeepLearning_Instances[selectedInstance].parameters.flowConfigPriority)
end
Script.serveFunction('CSK_MultiDeepLearning.setFlowConfigPriority', setFlowConfigPriority)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    _G.logger:fine(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
    -- Check if CSK_PersistentData version is > 1.x.x
    if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

      _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

      for j = 1, #multiDeepLearning_Instances do
        multiDeepLearning_Instances[j].persistentModuleAvailable = false
      end
    else
      -- Check if CSK_PersistentData version is >= 3.0.0
      if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
        local parameterName, loadOnReboot, totalInstances = CSK_PersistentData.getModuleParameterName(nameOfModule, '1')
        -- Check for amount if instances to create
        if totalInstances then
          local c = 2
          while c <= totalInstances do
            addInstance()
            c = c+1
          end
        end
      end

      if not multiDeepLearning_Instances then
        return
      end

      for i = 1, #multiDeepLearning_Instances do
        local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule, tostring(i))

        if parameterName then
          multiDeepLearning_Instances[i].parametersName = parameterName
          multiDeepLearning_Instances[i].parameterLoadOnReboot = loadOnReboot
        end

        if multiDeepLearning_Instances[i].parameterLoadOnReboot then
          setInstance(i)
          loadParameters()
          if multiDeepLearning_Instances[i].parameters.modelName ~= '-' then
            _G.logger:fine(nameOfModule .. ": Instantly setting a network for deepLearning object " .. tostring(i) .. " = " .. multiDeepLearning_Instances[i].parameters.modelName)
            setModelByName(multiDeepLearning_Instances[i].parameters.modelName)
          end
        end
      end
      Script.notifyEvent('MultiDeepLearning_OnDataLoadedOnReboot')
    end
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

local function resetModule()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    clearFlowConfigRelevantConfiguration()
    pageCalled()
  end
end
Script.serveFunction('CSK_MultiDeepLearning.resetModule', resetModule)
Script.register("CSK_PersistentData.OnResetAllModules", resetModule)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

