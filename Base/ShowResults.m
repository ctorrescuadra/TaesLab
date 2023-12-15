classdef ShowResults < handle
    properties(Access=private)
        status
        showTable_button
        showGraph_button
        result_label
        table_control
        tableIndex
        activeTable
        Figure
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
            % Menus
            hf=figure('visible','off','menubar','none',...
                'name','Show Results',...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize]);
            f=uimenu (hf,'label', '&File', 'accelerator', 'f');
            uimenu (f, 'label', 'Close', 'accelerator', 'q',...
				'callback', 'close(gcf)');
            % Put the Widgets
            app.status=1;
            app.showTable_button = uicontrol (hf,'style', 'pushbutton',...
                'units', 'normalized',...
                'fontname','Verdana','fontsize',9,...
                'string','Show Table',...
                'backgroundcolor',[1 0.98 0.98],...
                'callback', @(src,evt) app.showTable(src,evt),...
                'enable','off',...
                'position', [0.03 0.02 0.24 0.05]);
            app.showGraph_button = uicontrol (hf,'style', 'pushbutton',...
                'units', 'normalized',...
                'fontname','Verdana','fontsize',9,...
                'string','Show Graph',...
                'backgroundcolor',[1 0.98 0.98],...
                'callback', @(src,evt) app.showGraph(src,evt),...
                'enable','off',...
                'position', [0.73 0.02 0.24 0.05]);
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
                'CellSelectionCallback',@(src,evt) app.setActiveTable(src,evt),...
                'units', 'normalized','position',[0.03 0.1 0.94 0.85]);
            set(hf,'visible','on');
            app.tableIndex=tbl;
            app.Figure=hf;
        end

        function showTable(app,~,~)
            viewTable(app.activeTable);
        end

        function showGraph(app,~,~)
            showGraph(app.activeTable);
        end

        function setActiveTable(app,~,evt)
            idx=evt.Indices(1);
            app.activeTable=app.tableIndex.Content{idx};
            set(app.showTable_button,'Enable','on');
            if isGraph(app.activeTable)
                set(app.showGraph_button,'Enable','on');
            else
                set(app.showGraph_button,'Enable','off');
            end
        end

        function closeApp(app,src,evt)
            display(src);
            display(evt);
            delete(app.Figure);
        end


    end
end