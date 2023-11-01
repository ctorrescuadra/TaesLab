% show_thermoeconomic_state
% Script to launch function ThermoeconomicState
% Show information about productive structure an exergy of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data file model
data=selectDataModel();
if ~data.isValid
  data.printLogger;
  data.printError('Invalid data model. See error log');
	return
end
% Assign function paramater
param=struct();
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.States);
end
% Show results
options.VarMode=cType.VarMode.NONE;
options.VarFormat=false;
res=ThermoeconomicState(data,param);
if res.isValid
	tbl=outputResults(res,options);
end
