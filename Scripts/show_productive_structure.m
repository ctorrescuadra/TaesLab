% show_productive_structure
% Script to launch function ShowProductiveStructure
% Show information about productive structure
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data file model
model=selectDataModel();
if model.isError
	model.printLogger;
	model.printError('Invalid data model. See error log');
	return
end
% Show results
options.VarMode=cType.VarMode.CELL;
options.VarFormat=false;
res=ShowProductiveStructure(model);
if ~res.isError
	tbl=outputResults(obj,options);
end
