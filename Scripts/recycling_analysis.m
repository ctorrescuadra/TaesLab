% recycling_analysis
% Script to launch function RecyclingAnalysis
% Generates the adjacency matrix of the Fuel-Product table
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
% Select data model
model=selectDataModel();
if ~model.isValid
    model.printLogger;
	model.printError('Invalid data model. See error log');
	return
end
% Define parameters
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
% Select Waste Flows
if model.NrOfWastes>1
    [~,param.WasteFlow]=optionChoice('Select Waste Flow:',model.WasteData.Flows);
end
% Get Results
options.VarMode=cType.VarMode.CELL;
options.VarFormat=false;
res=RecyclingAnalysis(model,param);
if ~res.isError
	tbl=outputResults(res,options);
end
