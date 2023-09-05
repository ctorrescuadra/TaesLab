data=ReadDataModel('orcvcr_model.json');
model=cThermoeconomicModel(data,'Debug',false);
table=readmatrix("TableWN.TXT");
N=size(table,1);
x=zeros(N,1);
y=zeros(N,1);
for i=1:size(table,1)
    model.setExergyData('Operation',table(i,:));
    x(i)=table(i,14);
    y(i)=model.thermoeconomicDiagnosis.Info.TotalMalfunctionCost;
end
disp([x,y])
% Plot graphic
figure1 = figure('Name','Operation Diagnosis Demo');
axes1 = axes('Parent',figure1);
hold(axes1,'on');
plot(x,y);
ylabel('Malfunction Cost (kW)');
xlabel('Net Work (kW)');
title('Operation Diagnosis');
box(axes1,'on');
hold(axes1,'off');

