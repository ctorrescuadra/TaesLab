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
if ~data.isValid
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define paramaters
param=struct();
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.States);
end
% Use Resources Cost
if data.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Output Tables:',cType.CostTablesOptions);
    if bitget(oct,cType.GENERALIZED) && data.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.ResourceSamples);
	else
		param.ResourceSample=data.ResourceSamples{1};
    end
end
% Solve and show results
ta=ThermoeconomicAnalysis(data,param);
if ta.isValid
	outputResults(ta,options);
	ta.printInfo('Results (ta) available in Workspace');
else
	printLogger(ta);
end
