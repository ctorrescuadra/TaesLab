classdef cGraphDiagnosis < cGraphResults
%cGraphDiagnosis - Plot the diagnosis graphs.
%
%   cGraphDiagnosis Constructor
%     obj=cGraphDiagnosis(tbl,info,option)
%
%   cGraphDiagnosis Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults
%
    methods
        function obj=cGraphDiagnosis(tbl,info,option)
		%cDigraph - Build an instance of the object
        %   Syntax:
        %     obj = cDigraph(tbl,info)
        %   Input Arguments:
        %     tbl    - cTable with the data to show graphically
        %     info   - cGraphDiagnosis object with additional info
        %     option - (true/false) plot last bar (Demand Variation)
            if nargin==2
				option=true;
            end
            if info.Method==cType.DiagnosisMethod.WASTE_EXTERNAL
				option=true;
            end
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description,' [',tbl.State,']'];
			if tbl.isTotalMalfunctionCost
                obj.Categories=tbl.RowNames(1:end-1);
				obj.xValues=(1:tbl.NrOfRows-1)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,1:end-1));
                obj.Legend=tbl.ColNames(2:end-1);
            elseif option
                obj.Categories=tbl.ColNames(2:end);
				obj.xValues=(1:tbl.NrOfCols-1)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,:))';
                obj.Legend=tbl.RowNames(1:end-1);
            else % does not plot last bar
                obj.Categories=tbl.ColNames(2:end-1);
				obj.xValues=(1:tbl.NrOfCols-2)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,1:end-1))';
                obj.Legend=tbl.RowNames(1:end-1);
			end
			obj.xLabel='Processes';
			obj.yLabel=['Exergy ',tbl.Unit];
			obj.BaseLine=0.0;
        end
        
        function showGraph(obj)
        %showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
            if isOctave
                graphDiagnosis_OC(obj)
            else
                graphDiagnosis_ML(obj)
            end
        end

        function showGraphUI(obj,app)
        %showGraph - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
        %	Input Parameter:
        %	  app - GUI app reference object
        %
        M=numel(obj.Legend);
        cm=turbo(M);
        if app.isColorbar
            delete(app.Colorbar);
        end
        % Plot the bar graph
        b=bar(obj.yValues,...
                'EdgeColor','none','BarWidth',0.5,...
                'BarLayout','stacked',...
                'BaseValue',obj.BaseLine,...
                'FaceColor','flat',...
                'Parent',app.UIAxes);
        for i=1:M, b(i).CData=cm(i,:); end
        bs=b.BaseLine;
        bs.BaseValue=0.0;
        bs.LineStyle='-';
        bs.Color=[0.6,0.6,0.6];
        setGraphParametersUI(obj,app);
        app.UIAxes.Visible='on';
        end
    end

    methods(Access=private)
        function graphDiagnosis_OC(obj)
        % Show the diagnosis graph (Octave Version)
        %
            M=numel(obj.Legend);
            cm=turbo(M);
            f=figure('name',obj.Name, 'visible','off','numbertitle','off','colormap',turbo,...
                     'units','normalized','position',[0.05 0.1 0.4 0.6]);
            ax=axes(f,'position', [0.1 0.1 0.75 0.8]);
            hold(ax,'on');
            zt=obj.yValues;
            zt(zt>0)=0; % Plot negative values
            b1=bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
            for i=1:M, set(b1(i),'facecolor',cm(i,:)); end
            zt=obj.yValues;
            zt(zt<0)=0; % Plot positive values
            b2=bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
            for i=1:M, set(b2(i),'facecolor',cm(i,:)); end
            obj.setGraphParameters(ax);
            set(f,'visible','on');
        end
        
        function graphDiagnosis_ML(obj)
        % Show the diagnosis graph (Matlab version)
        %
            M=numel(obj.Legend);
            cm=turbo(M);
            set(groot,'defaultTextInterpreter','none');
            f = figure('numbertitle','off',...
                'Name',obj.Name,...
                'colormap',turbo,...
                'units','normalized',...
                'position',[0.1 0.1 0.4 0.6],...
                'color',[1,1,1]);
            ax = axes(f,'Position',[0.1 0.1 0.85 0.8]);
            hold(ax,'on');
            b=bar(obj.yValues,...
                'EdgeColor','none','BarWidth',0.5,...
                'BarLayout','stacked',...
                'BaseValue',obj.BaseLine,...
                'Parent',ax);			
            for i=1:M, b(i).FaceColor=cm(i,:); end
            bs=b.BaseLine;
            bs.BaseValue=obj.BaseLine;
            bs.LineStyle='-';
            bs.Color=[0.6,0.6,0.6];
            obj.setGraphParameters(ax);
        end
    end
end