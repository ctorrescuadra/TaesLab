%productive_structure - Script to launch function ProductiveStructure
% 	Show information about productive structure
% 	Select the data file model as <folder>_model.<ext>
% 	Prompt input parameters interactively
% Output:
%	ps - cResultInfo containing Productive Structure info
%
% Select data file model
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.isValid
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
ps=ProductiveStructure(data);
if ps.isValid
	outputResults(ps,options);
	ps.printInfo('Results (ps) available in Workspace');
else
	printLogger(ps);
end
