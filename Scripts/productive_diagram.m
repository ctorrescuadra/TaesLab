%productive_diagram - Script to launch function ProductiveDiagram
%   Generate the productive structure tables
%   Select the data file model as <folder>_model.<ext>
%   Prompt parameters interactively
% Output:
%	res - cResultInfo containing Productive Diagram info
%
% Select data file model
options=struct('Console','N','Save','Y');
data=selectDataModel();
if ~data.status
	data.printLogger;
	data.printError(cMessages.InvalidDataModel);
	return
end
% Show results
res=ProductiveDiagram(data);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
