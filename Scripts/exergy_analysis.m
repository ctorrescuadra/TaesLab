%exergy_analysis
%   Script to launch function ThermoeconomicState
%   Show information about the exergy values of a thermoeconomic state
%   Select the data file model as <folder>_model.<ext>
%   Prompt parameters interactively
%  Output:
%	res - cResultInfo containing the exergy analysis info
%
% Select data file model
param=struct();
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.status
  data.printLogger;
  data.printError(cMessages.InvalidObject,class(data));
	return
end
% Assign function paramater
if data.NrOfStates>1
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Show results
res=ExergyAnalysis(data,param);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
