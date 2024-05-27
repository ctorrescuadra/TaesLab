% show_table_fp
% Script to launch function ShowTableFP
% Generates the adjacency matrix of the Fuel-Product table
% If SaveResult is selected, it generates a XLS file
% to use with graph aplications as yED
% Select the data file model as <folder>_model.<ext>
% Prompt input parameters interactively
% Output:
%	res - cResultInfo containing TableFP info
%
% Select data model
options=struct('Console','N','Save','Y');
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
% Get TableFP
res=DiagramFP(data,param);
if ~res.isError
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
