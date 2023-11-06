---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
-----------------------------------------------------------
local nameOfModule = 'CSK_MultiDeepLearning'
-- If App property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
local availableAPIs = require('ImageProcessing/MultiDeepLearning/helper/checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')

local scriptParams = Script.getStartArgument() -- Get parameters from model

local deepLearningInstanceNumber = scriptParams:get('deepLearningInstanceNumber') -- number of this instance
local deepLearningInstanceNumberString = tostring(deepLearningInstanceNumber) -- number as string
local viewerID = scriptParams:get('viewerID') -- Viewer ID
local dnn = MachineLearning.DeepNeuralNetwork.create()

Script.serveEvent("CSK_MultiDeepLearning.OnNewValueToForward" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewValueToForward" .. deepLearningInstanceNumberString, 'string:1, auto:1')

Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredClass" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewMeasuredClass" .. deepLearningInstanceNumberString, 'string:1')
Script.serveEvent("CSK_MultiDeepLearning.OnNewResult" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewResult" .. deepLearningInstanceNumberString, 'bool:1')
Script.serveEvent("CSK_MultiDeepLearning.OnNewFullResultWithImage" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewFullResultWithImage" .. deepLearningInstanceNumberString, 'bool:1, string:[1+], float:[1+], object:1:Image')
Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredScore" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewMeasuredScore" .. deepLearningInstanceNumberString, 'string:1')

local imageProcessingParams = {}
imageProcessingParams.fullModelPath = scriptParams:get('fullModelPath')
imageProcessingParams.validScore = scriptParams:get('validScore')
imageProcessingParams.showImage = scriptParams:get('showImage')
imageProcessingParams.registeredEvent = scriptParams:get('registeredEvent')
imageProcessingParams.activeInUI = false
imageProcessingParams.forwardResultWithImage = scriptParams:get('forwardResultWithImage')
imageProcessingParams.processWithScores = scriptParams:get('processWithScores')
imageProcessingParams.sortResultByIndex = scriptParams:get('sortResultByIndex')

local viewer = View.create(viewerID)

-- Get SIM type
local typeName = Engine.getTypeName() -- Full device typename of current used device
local  firmwareVersion =  Engine.getFirmwareVersion() -- Firmware version of current used device
local deviceType = '' -- Reduced device typename of current used device

if typeName == 'AppStudioEmulator' or typeName == 'SICK AppEngine' then
  deviceType = 'AppStudioEmulator'
else
  deviceType = string.sub(typeName, 1, 7)
end

local function firmwareNotAllowed (firmware)
  if firmware == "2.1.0" or firmware == "2.2.0" or firmware == "2.2.1" then
    return false
  else
    return true
  end
end
--- Function to sort results by class index instead of highest score
---@param input any Results
---@param idx any Index
---@return output Results sorted by Index
local function sortResultByIndex(input, idx)
  local output = { }
  for i=1, #input do
    local key = idx[i]+1
    local value = input[i]
    output[key] = value
  end
  return output
end

--- Function to process incoming images with DNN
local function handleOnNewImageProcessing(image)

  _G.logger:info(nameOfModule .. ": Check DeepLearning image on instance No." .. deepLearningInstanceNumberString)
  if imageProcessingParams.showImage and imageProcessingParams.activeInUI then
    viewer:addImage(image)
    viewer:present("LIVE")
  end

  dnn:setInputImage(image)
  local result = dnn:predict()

  if result then
    local index, score, class = result:getAsClassification(true)
    score = score*100
    _G.logger:info(string.format("Image on DeepLearning" .. deepLearningInstanceNumberString .. " was classified as class number %i: %s with %0.1f %% confidence", index, class, score))
    Script.notifyEvent('MultiDeepLearning_OnNewMeasuredClass'.. deepLearningInstanceNumberString, class)
    Script.notifyEvent('MultiDeepLearning_OnNewMeasuredScore'.. deepLearningInstanceNumberString, string.format('%0.1f', score))

    if imageProcessingParams.activeInUI then
      Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewMeasuredClass', class)
      Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewMeasuredScore', string.format('%0.1f', score))
    end

    if score >= imageProcessingParams.validScore then
      Script.notifyEvent('MultiDeepLearning_OnNewResult'.. deepLearningInstanceNumberString, true)
      if imageProcessingParams.forwardResultWithImage then
        Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, true, class, score, image)
      end
      if imageProcessingParams.activeInUI then
        Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewResult', true)
      end
      return true, score, class

    else
      Script.notifyEvent('MultiDeepLearning_OnNewResult'.. deepLearningInstanceNumberString, false)
      if imageProcessingParams.forwardResultWithImage then
        Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, false, class, score, image)
      end
      if imageProcessingParams.activeInUI then
        Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewResult', false)
      end
      return false, score, class
    end
  else
    Script.notifyEvent('MultiDeepLearning_OnNewResult'.. deepLearningInstanceNumberString, false)
    if imageProcessingParams.forwardResultWithImage then
        Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, false, 'noClass', 0.0, image)
      end
    if imageProcessingParams.activeInUI then
      Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewResult', false)
    end
    _G.logger:info(nameOfModule .. ": No results available")
    return false, nil, nil
  end
end
Script.serveFunction("CSK_MultiDeepLearning.processImage"..deepLearningInstanceNumberString, handleOnNewImageProcessing, 'object:1:Image', 'bool:?, float:?,string:?')

-- Function to process incoming images with DNN (returns all scores)
local function handleOnNewImageProcessingScores(image)

  -- Return here if we are running on SIM1012 and any firmware other than the allowed ones, otherwise the SIM will crash!
  if deviceType == "SIM1012" and firmwareNotAllowed(firmwareVersion) then
    _G.logger:info(nameOfModule .. ': Can not run handleOnNewImageProcessingScores() with this firmware. Please change to [2.1.0, 2.2.0, 2.2.1].' )
    return false, nil, nil
  end

  _G.logger:info(nameOfModule .. ": Check DeepLearning image on instance No." .. deepLearningInstanceNumberString)
  if imageProcessingParams.showImage and imageProcessingParams.activeInUI then
    viewer:addImage(image)
    viewer:present("LIVE")
  end

  local model = dnn:getModel()
  local noClasses = #model:getOutputNodeLabels()
  _G.logger:info(nameOfModule .. ': Number of result classes:' .. noClasses)
  dnn:setInputImage(image)
  local result = dnn:predict()


  if result then
    local index, score, class = result:getAsClassification(noClasses,true)

    for i=1, noClasses do
      score[i] = score[i]*100
    end

    _G.logger:info(string.format("Image on DeepLearning" .. deepLearningInstanceNumberString .. " best class was number %i: %s with %0.1f %% confidence", index[1], class[1], score[1]))
    Script.notifyEvent('MultiDeepLearning_OnNewMeasuredClass'.. deepLearningInstanceNumberString, class[1])
    Script.notifyEvent('MultiDeepLearning_OnNewMeasuredScore'.. deepLearningInstanceNumberString, string.format('%0.1f', score[1]))


    if imageProcessingParams.activeInUI then
      Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewMeasuredClass', class[1])
      Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewMeasuredScore', string.format('%0.1f', score[1]))
    end

    if score[1] >= imageProcessingParams.validScore then
      Script.notifyEvent('MultiDeepLearning_OnNewResult'.. deepLearningInstanceNumberString, true)
      if imageProcessingParams.forwardResultWithImage then
        if imageProcessingParams.sortResultByIndex then
          score = sortResultByIndex(score, index)
          class = sortResultByIndex(class, index)
        end
        Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, true, class, score, image)
      end
      if imageProcessingParams.activeInUI then
        Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewResult', true)
      end
      return true, score, class

    else
      Script.notifyEvent('MultiDeepLearning_OnNewResult'.. deepLearningInstanceNumberString, false)
      if imageProcessingParams.forwardResultWithImage then
        if imageProcessingParams.sortResultByIndex then
          score = sortResultByIndex(score, index)
          class = sortResultByIndex(class, index)
        end
        Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, false, class, score, image)
      end
      if imageProcessingParams.activeInUI then
        Script.notifyEvent('MultiDeepLearning_OnNewValueToForward' .. deepLearningInstanceNumberString, 'MultiDeepLearning_OnNewResult', false)
      end
      return false, score, class
    end

  else
    _G.logger:info(nameOfModule .. ": No results available")
    Script.notifyEvent('MultiDeepLearning_OnNewFullResultWithImage'.. deepLearningInstanceNumberString, false, 'noClass', 0.0, image)
    return false, nil, nil
  end
end
Script.serveFunction("CSK_MultiDeepLearning.processImageWithScores"..deepLearningInstanceNumberString, handleOnNewImageProcessingScores, 'object:1:Image, bool:1', 'bool:?,float:[?*],string:[?*]')

--- Function to handle updates of processing parameters from Controller
---@param deepLearningNo int Number of instance to update
---@param parameter string Parameter to update
---@param value auto Value of parameter to update
local function handleOnNewImageProcessingParameter(deepLearningNo, parameter, value)

  if deepLearningNo == deepLearningInstanceNumber then -- set parameter only in selected script
    _G.logger:info(nameOfModule .. ": Update parameter '" .. parameter .. "' of deepLearningNo." .. tostring(deepLearningNo) .. " to value = " .. tostring(value))

    if parameter == 'registeredEvent' then
      _G.logger:info(nameOfModule .. ": Register DNN instance " .. deepLearningInstanceNumberString .. " on event " .. value)
      if imageProcessingParams.registeredEvent ~= '' then
        if imageProcessingParams.processWithScores then
          Script.deregister(imageProcessingParams.registeredEvent, handleOnNewImageProcessingScores)
        else
          Script.deregister(imageProcessingParams.registeredEvent, handleOnNewImageProcessing)
        end
      end
      imageProcessingParams.registeredEvent = value
      if imageProcessingParams.processWithScores then
        Script.register(value, handleOnNewImageProcessingScores)
      else
        Script.register(value, handleOnNewImageProcessing)
      end
    elseif parameter == 'fullModelPath' then

      -- Setting new model for DNN
      imageProcessingParams.fullModelPath = value
      local model = Object.load(imageProcessingParams.fullModelPath)
      local suc = dnn:setModel(model)
      _G.logger:info(nameOfModule .. ": Success of setting new model = " .. tostring(suc))

    else
      imageProcessingParams[parameter] = value
      if  parameter == 'showImage' and value == false then
        viewer:clear()
        viewer:present()
      end
    end
  elseif parameter == 'activeInUI' then
    imageProcessingParams[parameter] = false
  end
end
Script.register("CSK_MultiDeepLearning.OnNewImageProcessingParameter", handleOnNewImageProcessingParameter)
