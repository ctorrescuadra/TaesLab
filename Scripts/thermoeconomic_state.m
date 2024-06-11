% thermoeconomic_state
% Script to launch function ThermoeconomicState
% Show information about the exergy values of a thermoeconomic state
% Select the data file model as <folder>_model.<ext>
% Prompt parameters interactively
% Output:
%	res - cResultInfo containing thermoconomic state info
%
% Select data file model
options=struct('Console','Y','Save','N');
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
res=ThermoeconomicState(data,param);
if res.isValid
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
