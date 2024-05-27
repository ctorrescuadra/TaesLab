% productive_structure
% Script to launch function ProductiveStructure
% Show information about productive structure
% Select the data file model as <folder>_model.<ext>
% Prompt input parameters interactively
% Output:
%	res - cResultInfo containing Productive Structure info
%
% Select data file model
options=struct('Console','Y','Save','N');
data=selectDataModel();
if data.isError
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
res=ProductiveStructure(data);
if ~res.isError
	outputResults(res);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
