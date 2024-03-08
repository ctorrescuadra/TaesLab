model=ThermoeconomicTool('NH3_model.xlsx','Debug',false,'CostTables','GENERALIZED');
rs=model.SampleNames;
for i=1:numel(rs)
  rfile=strcat('NH3_',rs{i},'.xlsx');
  model.ResourceSample=rs{i};
  SaveResults(model,rfile);
end
model.CostTables='DIRECT';
SaveResults(model,'NH3_base.xlsx');