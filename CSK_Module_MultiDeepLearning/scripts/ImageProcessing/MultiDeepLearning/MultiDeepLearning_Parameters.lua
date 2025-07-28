---@diagnostic disable: redundant-parameter, undefined-global

--***************************************************************
-- Inside of this script, you will find the relevant parameters
-- for this module and its default values
--***************************************************************

local functions = {}

local function getParameters()

  local multiDeepLearningParameters = {}

  multiDeepLearningParameters.flowConfigPriority = CSK_FlowConfig ~= nil or false -- Status if FlowConfig should have priority for FlowConfig relevant configurations
  multiDeepLearningParameters.modelPath = '/public/CSK_DeepLearning_Models/' -- Path to search for DNN models
  multiDeepLearningParameters.modelName = '-' -- Name of selected model
  multiDeepLearningParameters.validScore = 80 -- Score to decide if image is from a class
  multiDeepLearningParameters.showImage = false -- Show image on UI
  multiDeepLearningParameters.forwardResultWithImage = false -- Forward image incl. processing result
  multiDeepLearningParameters.processWithScores = false -- Return the scores for all classes in the processing result
  multiDeepLearningParameters.sortResultByIndex = false -- Sort processing result by class index instead of highest score
  multiDeepLearningParameters.registeredEvent = '' -- Event to register to get images to process
  multiDeepLearningParameters.processingFile = 'MultiDeepLearning_Processing' -- Script to use for processing in thread

  return multiDeepLearningParameters
end
functions.getParameters = getParameters

return functions