% thermoeconomic_analysis
% Script to launch function ThermoeconomicAnalysis
% Compute the exergy cost and FP tables of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data model file
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
	[oct,param.CostTables]=optionChoice('Select Output Tables:',cType.CostTablesOptions);
    if bitget(oct,cType.GENERALIZED) && data.NrOfResourceSamples>1
		[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.ResourceSamples);
	else
		param.ResourceSample=data.ResourceSamples{1};
    end
end
% Solve and show results
options.VarMode=cType.VarMode.NONE;
options.VarFormat=false;
res=ThermoeconomicAnalysis(data,param);
if res.isValid
	tbl=outputResults(res,options);
end
