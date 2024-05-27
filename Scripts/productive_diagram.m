% productive_diagram
% Script to launch function ProductiveDiagram
% Generate the productive structure tables
% Select the data file model as <folder>_model.<ext>
% Prompt parameters interactively
% Output:
%	res - cResultInfo containing Productive Diagram info
%
% Select data file model
options=struct('Console','N','Save','Y');
data=selectDataModel();
if data.isError
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
res=ProductiveDiagram(data);
if ~res.isError
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
