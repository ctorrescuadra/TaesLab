%productive_structure - Script to launch function ProductiveStructure
% 	Show information about productive structure
% 	Select the data file model as <folder>_model.<ext>
% 	Prompt input parameters interactively
% Output:
%	productiveStructure - cResultInfo containing Productive Structure info
%
% Select data file model
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.status
	data.printLogger;
	data.printError(cMessages.InvalidDataModel);
	return
end
% Show results
res=ProductiveStructure(data);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
