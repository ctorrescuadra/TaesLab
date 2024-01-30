% exergy_cost_calculator
% Script to launch function ExergyCostCalculator
% Compute the exergy cost of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data model
data=selectDataModel();
if ~data.isValid
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define application paramaters
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
% Solve and show results
res=ExergyCostCalculator(data,param);
if res.isValid
	tbl=outputResults(res);
end
