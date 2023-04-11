% Draw a graph of the cost recycling saving as function of gases temparature
% Check Input
model_file='gturbo_model.xlsx';
if ~exist(model_file,'file')
	fprintf('ERROR: Config file %s not found\n',model_file);
	return
end 
model=ReadDataModel(model_file);
if ~model.isValid
    error('Invalid data model')
end
% Read Exergy and waste definition
state=model.getStateName(1);
rex=model.readExergy;
if rex.isValid
	sol=cFlowExergyCost(rex);
else	
	error('Invalid exergy values');
end
wt=model.readWaste;
if ~wt.isValid
    error('Invalid Waste Definition');
end
t=(360:-20:20);
TK=273.15;T0=20;TK0=TK+T0;
b=arrayfun(@(t) t-T0-TK0*log((t+TK)/TK0),t);
x=1-b'/b(1);
NP=size(x,1);
y=zeros(NP,wt.NrOfWastes);
% Calculate cost of recycling saving
for i=1:NP
    wt.setRecycleRatio(2,x(i));
	sol.setWasteOperators(wt);
	c=sol.getDirectFlowsCost.c;
	y(i,1)=c(17);y(i,2)=c(19);
end
% Plot Result
res=[t',x,y];
disp(res);
hf=figure(); plot(t,y,"marker","diamond");
grid on;
ylim([1,3]);
xlim([50,350]);
title("Gas Turbine Recycling Costs");
xlabel('Temperature ({}^oC)');ylabel('Unit Cost (J/J)');
hl=legend({'Electricity','Gases'});
set(hl,'Orientation','horizontal','Location','southoutside',...
    'FontSize',9);