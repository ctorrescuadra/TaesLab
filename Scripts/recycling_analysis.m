%recycling_analysis - Script to launch function WasteAnalysis
%   Generates waste recycling analysis results
%   Select the data file model as <folder>_model.<ext>
%   Prompt input parameters interactively
% Output:
%	res - cResultInfo containing waste analysis info
%
% Select data model
options=struct('Console','Y','Save','N');
param=struct();
data=selectDataModel();
if ~data.status
    data.printLogger;
	data.printError(cMessages.InvalidObject,class(data));
	return
end
% Define parameters
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Use Resources Cost
if data.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Cost Tables', cType.CostTablesOptions);
	if bitget(oct,cType.GENERALIZED) && data.NrOfSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.SampleNames);
	else
		param.ResourceSample=data.SampleNames{1};
	end
end
% Select Waste Flows
if data.NrOfWastes>1
    [~,param.ActiveWaste]=optionChoice('Select Waste Flow:',data.gWasteNames);
end
% Get Results
res=WasteAnalysis(data,param);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
