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
param=struct();
data=selectDataModel();
if ~data.status
    data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Define paramaters
param.DiagnosisMethod=cType.DEFAULT_DIAGNOSIS;
if data.isDiagnosis
	states=data.StateNames;
	[~,param.State]=optionChoice('Select State:',states(2:end));
else
	data.printError('An Operation State is required');
	return
end
doptions=cType.DiagnosisOptions;
[~,param.DiagnosisMethod]=optionChoice('Select Diagnosis Method:',doptions(2:end));
% Solve and show results
dgn=ThermoeconomicDiagnosis(data,param);
if dgn.status
	outputResults(dgn,options);
	dgn.printInfo('Results (dgn) available in Workspace');
else
	printLogger(dgn);
end
