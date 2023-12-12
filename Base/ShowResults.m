classdef ShowResults < handle
    properties(Access=private)
        status
        showTable_button
        showGraph_button
        result_label
        table_control
    end
    methods
        function app=ShowResults(res)
            log=cStatus();
            if nargin~=1
                log.printError('Values to show are required');
                log.printError('Usage: ViewModelResuls(res)');
                delete(app);
                return
            end
            if isa(res,'cResultInfo')
                val=res;
            elseif isa(res,'cThermoeconomicModel')
                val=res.getModelInfo;
            else
                log.printError('Results must be a cResultInfo object');
                delete(app);
                return
            end
            tbl=val.getTableIndex;
        % Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4;
            ysize=ss(4)/1.8;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;
            cw=0.85*ss(3);
            hf=figure('visible','off','menubar','none',...
                'name','Show Results',...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize]);
        % Put the Widgets
            app.status=1;
            app.showTable_button = uicontrol (hf,'style', 'pushbutton',...
            'units', 'normalized',...
            'fontname','Verdana','fontsize',9,...
            'string','Show Table',....
            'callback', @(src,evt) app.showTable(src,evt),...
            'position', [0.03 0.02 0.2 0.05]);
            app.showTable_button = uicontrol (hf,'style', 'pushbutton',...
            'units', 'normalized',...
            'fontname','Verdana','fontsize',9,...
            'string','Show Graph',....
            'callback', @(src,evt) app.showTable(src,evt),...
            'position', [0.77 0.02 0.2 0.05]);
            app.result_label = uicontrol (hf,'style', 'text',...
            'units', 'normalized',...
            'fontname','Verdana','fontsize',10,'fontweight','bold',...
            'string', val.ResultName,...
            'backgroundcolor',[0.94 0.94 0.94],...
            'horizontalalignment', 'center',...
            'position', [0.03 0.96 0.94 0.03]);
            app.table_control = uitable (hf,'Data',tbl.Data,...
            'ColumnName',tbl.ColNames(2:end),'RowName',tbl.RowNames,...
            'ColumnWidth',{cw},'ColumnFormat',{'char'},...
            'FontName','Consolas','FontSize',10,...
            'units', 'normalized','position',[0.03 0.1 0.94 0.86]);
            set(hf,'visible','on');
        end

        function showTable(obj,src,evt)
            display(obj.status);
            display(src);
            display(evt);
        end

        function showGraph(obj,src,evt)
            display(obj.status);
            display(src);
            display(evt);
        end
    end
end