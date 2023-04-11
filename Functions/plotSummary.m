function log = plotSummary(ms, graph, var)
% graphSummary plot summary graphs
%   Input:
%       ms - cResultInfo object with Model Summary info and tables
%      tbl - Data to plot
%      var - Variables to plot
%
    %Check input arguments
    log=cStatusLogger(true);
    if ~isa(ms,'cResultInfo') || ~isValid(ms)
        log.messageLog(cType.ERROR,'Invalid cResultInfo object');
        return
    end
    if ms.Id ~= cType.ResultId.SUMMARY_RESULTS
        log.messageLog(cType.ERROR,'Invalid cResultInfo object %s',ms.Name);
        return
    end
    info=ms.Info;
    if nargin==1
        graph=cType.SummaryTables.FLOW_DIRECT_UNIT_COST;
        var=info.getDefaultFlowVariables;
    end
    tbl=ms.getTable(graph);
    if ~isValid(tbl) || ~tbl.isGraphTable
        log.messageLog(cType.ERROR,'Invalid graph type: %s',graph);
        return
    end
    if (nargin==2) && ~bitget(type,2)
        log.messageLog(cType.ERROR,'Variables are required for this type: %s',graph);
        return
    end
    if nargin==2
        var=info.getDefaultFlowVariables;
    end
    if bitget(type,2)
        idx=info.getFlowIndex(var);
    else
        idx=info.getProcessIndex(var);
    end
    if cType.isEmpty(idx)
        log.messageLog(cType.ERROR,'Invalid Variable Names');
        return
    end
    % Set bar variables
    label=['Unit Cost ',tbl.Unit];
    if bitget(type,3)
        yl1=0.0;
    else
        yl1=1.0;
    end
    x=(1:info.NrOfStates);
    y=cell2mat(tbl.Data(idx,:));
    % Plot Graph
    f=figure('name','Cost Summary', 'numbertitle','off','Position',[100,100,840,640]);
    ax=axes(f);
    bar(x',y','edgecolor','none','barwidth',0.8,'parent',ax);
    title(ax,tbl.Description,'fontsize',14);
    tmp=ylim;yl(1)=yl1;yl(2)=tmp(2);ylim(yl);
    set(ax,'xtick',x,'xticklabel',info.StateNames,'fontsize',12);
    xlabel(ax,'States','fontsize',12);
    ylabel(ax,label,'fontsize',12);
    set(ax,'ygrid','on');
    set(ax,'xgrid','off')
    box(ax,'on');
    hl=legend(var);
    set(hl,'Orientation','horizontal','Location','southoutside');
end
