% show_table_fp
% Script to launch function ShowTableFP
% Generates the adjacency matrix of the Fuel-Product table
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
% If SaveResult is selected, it generates a XLS file
% to use with graph aplications as yED
% Select data model
data=selectDataModel();
if ~data.isValid
    data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define aprameters
param=struct();
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.States);
end
% Get TableFP
options.VarMode=cType.VarMode.NONE;
options.VarFormat=false;
res=DiagramFP(data,param);
if ~res.isError
	tbl=outputResults(res,options);
end
