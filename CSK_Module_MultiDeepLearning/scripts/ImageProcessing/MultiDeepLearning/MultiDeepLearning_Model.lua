---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_MultiDeepLearning'

-- Create kind of "class"
local multiDeepLearning = {}
multiDeepLearning.__index = multiDeepLearning

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Function to create new instance
---@param deepLearningInstanceNo int Number of instance
---@return table[] self Instance of multiDeepLearning
function multiDeepLearning.create(deepLearningInstanceNo)

  local self = {}
  setmetatable(self, multiDeepLearning)

  -- Standard helper functions
  self.helperFuncs = require('ImageProcessing/MultiDeepLearning/helper/funcs')

  -- Check if CSK_UserManagement module can be used if wanted
  self.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

  -- Check if CSK_PersistentData module can be used if wanted
  self.persistentModuleAvailable = CSK_PersistentData ~= nil or false

  self.currentModel = nil -- of type MachineLearning.DeepNeuralNetwork.Model --> json
  self.modelList = {'-'} -- List of available DNN models
  self.deepLearningInstanceNo = deepLearningInstanceNo -- Instance no of this camera
  self.deepLearningInstanceNoString = tostring(self.deepLearningInstanceNo) -- Instance no of this camera as string

  self.activeInUI = false -- Is current camera selected via UI (see "setSelectedCam")

  -- Default values for persistent data
  -- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
  self.parametersName = 'CSK_MultiDeepLearning_Parameter' .. self.deepLearningInstanceNoString -- name of parameter dataset to be used for this module
  self.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

  -- Parameters to be saved permanently
  self.parameters = {}
  --self.parameters.eventName = '-' -- Event to register to get images to process
  self.parameters.modelPath = '/public/models/' -- Path to search for DNN models
  self.parameters.modelName = '-' -- Name of selected model
  self.parameters.validScore = 80 -- Score to decide if image is from a class
  self.parameters.showImage = false -- Show image on UI
  self.parameters.forwardResultWithImage = false -- Forward image incl. processing result
  self.parameters.registeredEvent = 'e.g. CSK_MultiRemoteCamera.OnNewImageCamera' .. self.deepLearningInstanceNoString -- Event to register to get images to process
  self.parameters.processingFile = 'MultiDeepLearning_Processing' -- Script to use for processing in thread

  -- Parameters to give to the image processing
  self.multiDeepLearningProcessingParams = Container.create()
  self.multiDeepLearningProcessingParams:add('deepLearningInstanceNumber', deepLearningInstanceNo, "INT")
  self.multiDeepLearningProcessingParams:add('viewerID', 'multiDeepLearningViewer' .. self.deepLearningInstanceNoString, "STRING")
  self.multiDeepLearningProcessingParams:add('fullModelPath', self.parameters.modelPath .. self.parameters.modelName, "STRING")
  self.multiDeepLearningProcessingParams:add('showImage', self.parameters.showImage, "BOOL")
  self.multiDeepLearningProcessingParams:add('validScore', self.parameters.validScore, "INT")
  self.multiDeepLearningProcessingParams:add('registeredEvent', self.parameters.registeredEvent, "STRING")
  self.multiDeepLearningProcessingParams:add('forwardResultWithImage', self.parameters.forwardResultWithImage, "BOOL")

  --Check if path of 'self.parameters.modelPath' is available on the device and if models are inside.
  if File.isdir(self.parameters.modelPath) then
    local fileList = File.list(self.parameters.modelPath)
    if fileList ~= nil and #fileList ~= 0 then
      _G.logger:info(nameOfModule .. ': Found available models on device.')
      self.modelList = fileList
    else
      _G.logger:info(nameOfModule .. ': No models available on device.')
    end
  else
    local suc = File.mkdir(self.parameters.modelPath)
    if suc then
      _G.logger:info(nameOfModule .. ': Created path "' .. self.parameters.modelPath .. '" on the device to store DNN models.')
    else
      _G.logger:info(nameOfModule .. ': Creation of path "' .. self.parameters.modelPath .. '" on the device to store DNN models was not possible.')
    end
  end

  -- Handle image processing
  Script.startScript(self.parameters.processingFile, self.multiDeepLearningProcessingParams)

  return self
end

return multiDeepLearning

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************