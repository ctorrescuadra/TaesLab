%productive_diagram - Script to launch function ProductiveDiagram
%   Generate the productive structure tables
%   Select the data file model as <folder>_model.<ext>
%   Prompt parameters interactively
% Output:
%	pd - cResultInfo containing Productive Diagram info
%
% Select data file model
options=struct('Console','N','Save','Y');
data=selectDataModel();
if ~data.isValid
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
pd=ProductiveDiagram(data);
if pd.isValid
	outputResults(pd,options);
	pd.printInfo('Results (pd) available in Workspace');
else
	printLogger(pd);
end
