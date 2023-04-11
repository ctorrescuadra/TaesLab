% Example of aplicacition of ExIoLab to calculate recycling saving
% Check Input
model=ReadDataModel('cgamr_model.json');
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
t=(440:-20:20)';
TK=273.15;T0=20;TK0=TK+T0;
b=arrayfun(@(t) t-T0-TK0*log((t+TK)/TK0),(440:-20:20));
x=1-b'/b(1);
y=zeros(numel(x),2);
s=zeros(numel(x),1);
sol=cModelFPR(pm);
sol.getDirectProcessUnitCost.cP;
% Calculate cost of recycling saving
for i=1:size(x,1)
	wt.setRecycleRatio(1,x(i));
	sol.setWasteOperators(wt);
	c=sol.getDirectProcessUnitCost.cP;
	y(i,1)=c(3);y(i,2)=c(5);
    s(i)=sol.WasteOperators.opR.mValues(1,5);
end
% Plot Result
res=[t,x,y,s];
disp(res)
hf=figure(); 
hp=plot(t,y,'Marker','diamond');
grid on;
ylim([1,3]);
xlim([0,450]);
title('CGAM Recicling Cost');
xlabel('Temperature ({}^oC)');ylabel('Unit Cost (J/J)');
xticks((0:50:450));
yticks((1:0.5:3));
hl=legend({'Electricity','Gases'});
set(hl,'Orientation','horizontal','Location','southoutside',...
    'FontSize',9);
