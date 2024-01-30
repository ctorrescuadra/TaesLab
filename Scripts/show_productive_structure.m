% show_productive_structure
% Script to launch function ShowProductiveStructure
% Show information about productive structure
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data file model
data=selectDataModel();
if data.isError
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
res=ProductiveStructure(data);
if ~res.isError
	tbl=outputResults(res);
end
