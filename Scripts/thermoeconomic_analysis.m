% thermoeconomic_analysis
% Script to launch function ThermoeconomicAnalysis
% Compute the exergy cost and FP tables of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data model file
model=selectDataModel();
if ~model.isValid
	model.printLogger;
	model.printError('Invalid Data Model. See error log');
	return
end
% Define application paramaters
param=struct();
if model.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',model.States);
end
% Use Resources Cost
if model.isResourceCost
	[idx,param.CostTables]=optionChoice('Select Output Tables:',cType.CostTablesOptions);
    if (idx>1) && model.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',model.ResourceSamples);
	else
		param.ResourceSample=model.ResourceSamples{1};
    end
end
% Solve and show results
options.VarMode=cType.VarMode.CELL;
options.VarFormat=false;
res=ThermoeconomicAnalysis(model,param);
if res.isValid
	tbl=outputResults(res,options);
end
