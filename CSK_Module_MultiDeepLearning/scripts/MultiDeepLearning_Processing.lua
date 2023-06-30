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
Script.serveEvent("CSK_MultiDeepLearning.OnNewFullResultWithImage" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewFullResultWithImage" .. deepLearningInstanceNumberString, 'bool:1, string:1, float:1, object:1:Image')
Script.serveEvent("CSK_MultiDeepLearning.OnNewMeasuredScore" .. deepLearningInstanceNumberString, "MultiDeepLearning_OnNewMeasuredScore" .. deepLearningInstanceNumberString, 'string:1')

local imageProcessingParams = {}
imageProcessingParams.fullModelPath = scriptParams:get('fullModelPath')
imageProcessingParams.validScore = scriptParams:get('validScore')
imageProcessingParams.showImage = scriptParams:get('showImage')
imageProcessingParams.registeredEvent = scriptParams:get('registeredEvent')
imageProcessingParams.activeInUI = false
imageProcessingParams.forwardResultWithImage = scriptParams:get('forwardResultWithImage')

local viewer = View.create(viewerID)

--- Function to sort result by index
---@param t any Content
---@param idx any Index
---@return table Sorted table
local function sortResultsByIndex(t, idx)
  local u = { }
  for i=1, #t do
    local k = idx[i]+1
    local v = t[i]
    u[k] = v
  end
  return u
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
-- Currently event based usage of this function is not implemented
-- SIM1012 firmware must be at least FW2.1.0 otherwise the device crahses without errors!
local function handleOnNewImageProcessingScores(image, sorted)

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
  Script.releaseObject(image)


  if result then
    local index, score, class = result:getAsClassification(noClasses,true)

    for i=1, noClasses do
      score[i] = score[i]*100
    end

    _G.logger:info(string.format("Image on DeepLearning" .. deepLearningInstanceNumberString .. " best class was number %i: %s with %f %% confidence", index[1], class[1], score[1]))

    if not sorted then
      score = sortResultsByIndex(score, index)
      class = sortResultsByIndex(class, index)
    end
      return true, score, class
  else
    _G.logger:info(nameOfModule .. ": No results available")
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
        Script.deregister(imageProcessingParams.registeredEvent, handleOnNewImageProcessing)
      end
      imageProcessingParams.registeredEvent = value
      Script.register(value, handleOnNewImageProcessing)
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
