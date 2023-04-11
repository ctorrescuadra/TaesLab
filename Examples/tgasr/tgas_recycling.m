% Example of aplicacition of ExIoLab to calculate recycling saving
% Check Input
model=ReadDataModel('tgasr_model.xlsx');
if ~model.isValid
    error('Invalid data model')
end
% Read Exergy and waste definition
state=model.getStateName(1);
rex=model.readExergy(state);
if rex.isValid
	pm=cStreamProcessModel(rex);
else	
	error('Invalid exergy values');
end
wt=model.readWaste;
t=(600:-20:20)';
TK=273.15;T0=20;TK0=TK+T0;
b=arrayfun(@(t) t-T0-TK0*log((t+TK)/TK0),(600:-20:20));
x=1-b'/b(1);
y=zeros(numel(x),2);
s=zeros(numel(x),1);
sol=cModelFPR(pm);
% Calculate cost of recycling saving
for i=1:size(x,1)
	wt.setRecycleRatio(1,x(i));
	sol.setWasteOperators(wt);
	c=sol.getDirectProcessUnitCost.cP;
	y(i,1)=c(3);y(i,2)=c(4);
    s(i)=1+sol.WasteOperators.opR.mValues(1,4);
end
% Plot Result
res=[t,x,b',y,s];
disp(res)
hf=figure();
hp=plot(t,y,'Marker','diamond');
ylim([1,4]);
xlim([0,600]);
title('TGAS Recycling Cost');
xlabel('Temperature ({}^oC)');ylabel('Unit Cost (J/J)');
xticks((0:50:600));
yticks((1:0.5:4));
hl=legend({'Electricity','Gases'});
set(hl,'Orientation','horizontal','Location','southoutside',...
    'FontSize',10);
grid on;