% show_thermoeconomic_state
% Script to launch function ThermoeconomicState
% Show information about productive structure an exergy of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data file model
model=selectDataModel();
if ~model.isValid
    model.printLogger;
	model.printError('Invalid data model. See error log');
	return
end
% Assign function paramater
param=struct();
if model.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',model.States);
end
% Show results
options.VarMode=cType.VarMode.CELL;
options.VarFormat=false;
res=ThermoeconomicState(model,param);
if res.isValid
	tbl=outputResults(res,options);
end
