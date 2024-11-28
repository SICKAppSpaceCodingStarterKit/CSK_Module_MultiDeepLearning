--*****************************************************************
-- Here you will find all the required content to provide specific
-- features of this module via the 'CSK FlowConfig'.
--*****************************************************************

require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_ImageSource')
require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_OnNewResult')
require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_Process')

-- Reference to the multiImageFilter_Instances handle
local multiDeepLearning_Instances

--- Function to react if FlowConfig was updated
local function handleOnClearOldFlow()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    for i = 1, #multiDeepLearning_Instances do
      if multiDeepLearning_Instances[i].parameters.flowConfigPriority then
        CSK_MultiDeepLearning.clearFlowConfigRelevantConfiguration()
        break
      end
    end
  end
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)

--- Function to get access to the multiDeepLearning_Instances
---@param handle handle Handle of multiDeepLearning_Instances object
local function setMultiDeepLearning_Instances_Handle(handle)
  multiDeepLearning_Instances = handle
end

return setMultiDeepLearning_Instances_Handle