model=ThermoeconomicTool('orcvcr_model.xlsx');
st=model.StateNames;
SaveResults(model,'orcvcr_results.xlsx');
model.DiagnosisMethod='WASTE_INTERNAL';
for i=2:numel(st)
    model.State=st{i};
    res=model.thermoeconomicDiagnosis;
    filename=['orcvcr_',model.State,'.xlsx'];
    printTable(res,'dgn')
    model.summaryDiagnosis;
    SaveResults(res,filename);
end