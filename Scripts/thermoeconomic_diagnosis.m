% thermoeconomic_diagnosis
% Script to launch function ThermoeconomicDiagnosis
% Compare a thermoeconomic state with the reference state and show diagnosis tbl
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data model file
model=selectDataModel();
if ~model.isValid
    model.printLogger;
	model.printError('Invalid data model. See error log');
	return
end
% Define function paramaters
param=struct();
param.DiagnosisMethod=cType.DEFAULT_DIAGNOSIS;
if model.isDiagnosis
	states=model.States;
	[~,param.State]=optionChoice('Select State:',states(2:end));
else
	model.printError('An Operation State is required');
	return
end
if askQuestion('Compute Waste Diagnosis','Y')
	param.DiagnosisMethod='WASTE_INTERNAL';
end
% Solve and show results
options.VarMode=cType.VarMode.NONE;
options.VarFormat=false;
res=ThermoeconomicDiagnosis(model,param);
if res.isValid
	tbl=outputResults(res,options);
end
