% exergy_cost_calculator
% Script to launch function ExergyCostCalculator
% Compute the exergy cost of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data model
model=selectDataModel();
if ~model.isValid
	model.printLogger;
	model.printError('Invalid data model. See error log');
	return
end
% Define application paramaters
param=struct();
if model.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',model.States);
end
% Use Resources Cost
if model.isResourceCost
	[oct,param.CostTables]=optionChoice('Select Cost Tables', cType.CostTablesOptions);
	if bitget(oct,cType.GENERALIZED) && model.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',model.ResourceSamples);
	else
		param.ResourceSample=model.ResourceSamples{1};
	end
end
% Solve and show results
options.VarMode=cType.VarMode.NONE;
options.VarFormat=false;
res=ExergyCostCalculator(model,param);
if res.isValid
	tbl=outputResults(res,options);
end
