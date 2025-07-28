--*****************************************************************
-- Here you will find all the required content to provide specific
-- features of this module via the 'CSK FlowConfig'.
--*****************************************************************

require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_ImageSource')
require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_OnNewResult')
require('ImageProcessing.MultiDeepLearning.FlowConfig.MultiDeepLearning_Process')

--- Function to react if FlowConfig was updated
local function handleOnClearOldFlow()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    CSK_MultiDeepLearning.clearFlowConfigRelevantConfiguration()
  end
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)
