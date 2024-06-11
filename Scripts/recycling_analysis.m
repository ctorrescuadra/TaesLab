% recycling_analysis
% Script to launch function RecyclingAnalysis
% Generates waste recycling analysis
% Select the data file model as <folder>_model.<ext>
% Prompt input parameters interactively
% Output:
%	res - cResultInfo containing waste analysis info
%
% Select data model
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.isValid
    data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define parameters
param=struct();
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.States);
end
% Use Resources Cost
if data.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Cost Tables', cType.CostTablesOptions);
	if bitget(oct,cType.GENERALIZED) && data.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.ResourceSamples);
	else
		param.ResourceSample=data.ResourceSamples{1};
	end
end
% Select Waste Flows
if data.NrOfWastes>1
    [~,param.WasteFlow]=optionChoice('Select Waste Flow:',data.WasteData.Flows);
end
% Get Results
res=WasteAnalysis(data,param);
if res.isValid
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
