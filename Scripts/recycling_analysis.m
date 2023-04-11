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
if model.NrOfWastes>1
    [~,param.WasteFlow]=optionChoice('Select Waste Flow:',model.getWasteFlows);
end
% Get Results
options.VarMode=cType.VarMode.CELL;
options.VarFormat=false;
res=RecyclingAnalysis(model,param);
if ~res.isError
	tbl=outputResults(res,options);
end
