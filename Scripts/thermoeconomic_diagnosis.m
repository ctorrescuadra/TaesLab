% thermoeconomic_diagnosis
% Script to launch function ThermoeconomicDiagnosis
% Compare a thermoeconomic state with the reference state
% Select the data file model as <folder>_model.<ext>
% Prompt input parameters interactively
% Output:
%	res - cResultInfo containing thermoconomic diagnosis info
%
% Select data model file
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.isValid
    data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define function paramaters
param=struct();
param.DiagnosisMethod=cType.DEFAULT_DIAGNOSIS;
if data.isDiagnosis
	states=data.States;
	[~,param.State]=optionChoice('Select State:',states(2:end));
else
	data.printError('An Operation State is required');
	return
end
doptions=cType.DiagnosisOptions;
[~,param.DiagnosisMethod]=optionChoice('Select Diagnosis Method:',doptions(2:end));
% Solve and show results
res=ThermoeconomicDiagnosis(data,param);
if res.isValid
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
