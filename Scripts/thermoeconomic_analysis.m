%thermoeconomic_analysis - Script to launch function ThermoeconomicAnalysis
% 	Compute the exergy cost and FP tables of a thermoeconomic state
% 	Select the data file model as <folder>_model.<ext>
% 	Prompt input parameters interactively
% Output:
%	res - cResultInfo containing thermoconomic analysis info
%
% Select data model file
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.status
	data.printLogger;
	data.printError(cMessages.InvalidDataModel);
	return
end
% Define paramaters
param=struct();
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Use Resources Cost
if data.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Output Tables:',cType.CostTablesOptions);
    if bitget(oct,cType.GENERALIZED) && data.NrOfSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.SampleNames);
	else
		param.ResourceSample=data.SampleNames{1};
    end
end
% Solve and show results
res=ThermoeconomicAnalysis(data,param);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
