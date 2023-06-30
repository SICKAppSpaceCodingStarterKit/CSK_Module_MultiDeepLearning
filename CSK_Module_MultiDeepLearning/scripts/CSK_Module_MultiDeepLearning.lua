--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
_G.availableAPIs = require('ImageProcessing.MultiDeepLearning.helper.checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
_G.logHandle = Log.Handler.create()
_G.logHandle:attachToSharedLogger('ModuleLogger')
_G.logHandle:setConsoleSinkEnabled(false) --> Set to TRUE if CSK_Logger module is not used
_G.logHandle:setLevel("ALL")
_G.logHandle:applyConfig()
-----------------------------------------------------------

-- Loading script regarding MultiDeepLearning_Model
-- Check this script regarding MultiDeepLearning_Model parameters and functions
local multiDeepLearning_Model = require('ImageProcessing/MultiDeepLearning/MultiDeepLearning_Model')

local multiDeepLearning_Instances = {} -- Handle all instances

  -- Add other DNN instances during runtime e.g. via 
  --CSK_MultiDeepLearning.addInstance()

-- Load script to communicate with the MultiDeepLearning_Model UI
-- Check / edit this script to see/edit functions which communicate with the UI
local multiDeepLearningController = require('ImageProcessing/MultiDeepLearning/MultiDeepLearning_Controller')

if availableAPIs.specific then
  _G.logger:info("MachineLearning API Support = true")
  table.insert(multiDeepLearning_Instances, multiDeepLearning_Model.create(1)) -- create(deepLearningInstanceNo:int)
  multiDeepLearningController.setMultiDeepLearning_Instances_Handle(multiDeepLearning_Instances) -- share handle of instances
else
  _G.logger:warning("CSK_MultiDeepLearning: Features of this module are not supported on this device. Missing APIs.")
end

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************
--[[
--- Function to show how this module could be used
--@startProcessing()
local function startProcessing()
  -- TESTDATA for TRIAL MODE
  local testModel = 'Cornflakes.json'
  local model = Object.load('resources/CSK_Module_MultiDeepLearningSampleData/' .. testModel)
  Object.save(model, _G.deepLearningObjects[1].parameters.modelPath .. testModel)
  CSK_MultiDeepLearning.uploadFinished(true)

  CSK_MultiDeepLearning.setInstance(1)
  CSK_MultiDeepLearning.setModelByName('Cornflakes.json')
  --CSK_MultiDeepLearning.setInstance(2)
  --CSK_MultiDeepLearning.setModelByName('Cornflakes.json')

  -- Option A --> prepare an event to trigger processing via this one
  -- Following event is already served inside of the Controler script
  -- --Script.serveEvent("CSK_MultiDeepLearning.TestImage", "TestImage") --> Create event to listen to receive a image to process
  --CSK_MultiDeepLearning.setRegisterEvent('CSK_MultiDeepLearning.TestImage') --> Register processing to the event

  for i = 1, 2 do
    local imgOK = Image.load('resources/CSK_Module_MultiDeepLearningSampleData/OK_' .. tostring(i) .. '.bmp')
    local imgNOK = Image.load('resources/CSK_Module_MultiDeepLearningSampleData/NOK_' .. tostring(i) .. '.bmp')

    -- Option A --> trigger processing via event
    --Script.notifyEvent('TestImage', imgOK)
    --Script.notifyEvent('TestImage', imgNOK)

    -- Option B --> trigger processing via function call
    local valid, score, class = Script.callFunction('CSK_MultiDeepLearning.processImage1', imgOK)
    print(string.format("Valid: %s, Score: %0.1f Classname: %s", tostring(valid), score, class))
    Script.sleep(2000)
    valid, score, class = CSK_MultiDeepLearning.processImage1(imgNOK)
    print(string.format("Valid: %s, Score: %0.1f Classname: %s", tostring(valid), score, class))
    Script.sleep(2000)
  end
end
-- Call processing function after persistent data was loaded
--Script.register("CSK_MultiDeepLearning.OnDataLoadedOnReboot", startProcessing)
]]

--- Function to react on startup event of the app
local function main()

  multiDeepLearningController.setMultiDeepLearning_Model_Handle(multiDeepLearning_Model) -- share handle of model

  ----------------------------------------------------------------------------------------
  -- INFO: Please check if module will eventually load inital configuration triggered via
  --       event CSK_PersistentData.OnInitialDataLoaded
  --       (see internal variable parameterLoadOnReboot of multiDeepLearning_Instances)
  --       If so, the app will trigger the "OnDataLoadedOnReboot" event if ready after loading parameters
  --
  -- Could be used e.g. like this:
  ----------------------------------------------------------------------------------------

  --startProcessing() --> see above
  CSK_MultiDeepLearning.setInstance(1)
  CSK_MultiDeepLearning.pageCalled() -- Update UI
end
Script.register("Engine.OnStarted", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************