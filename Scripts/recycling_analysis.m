%recycling_analysis - Script to launch function WasteAnalysis
%   Generates waste recycling analysis results
%   Select the data file model as <folder>_model.<ext>
%   Prompt input parameters interactively
% Output:
%	wa - cResultInfo containing waste analysis info
%
% Select data model
options=struct('Console','Y','Save','N');
param=struct();
data=selectDataModel();
if ~data.isValid
    data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define parameters
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Use Resources Cost
if data.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Cost Tables', cType.CostTablesOptions);
	if bitget(oct,cType.GENERALIZED) && data.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.getSampleNames);
	else
		param.ResourceSample=data.getSampleNames(1);
	end
end
% Select Waste Flows
if data.NrOfWastes>1
    [~,param.ActiveWaste]=optionChoice('Select Waste Flow:',data.gWasteNames);
end
% Get Results
wa=WasteAnalysis(data,param);
if wa.isValid
	outputResults(wa,options);
	wa.printInfo('Results (wa) available in Workspace');
else
	printLogger(wa);
end
