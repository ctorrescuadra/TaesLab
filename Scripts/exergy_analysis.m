%exergy_analysis
%   Script to launch function ThermoeconomicState
%   Show information about the exergy values of a thermoeconomic state
%   Select the data file model as <folder>_model.<ext>
%   Prompt parameters interactively
%  Output:
%	ea - cResultInfo containing the exergy analysis info
%
% Select data file model
param=struct();
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.isValid
  data.printLogger;
  data.printError('Invalid data model. See error log');
	return
end
% Assign function paramater
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Show results
ea=ExergyAnalysis(data,param);
if ea.isValid
	outputResults(ea,options);
	ea.printInfo('Results (ea) available in Workspace');
else
	printLogger(ea);
end
