classdef cGraphDiagnosis < cGraphResults
%cGraphDiagnosis - Plot the thermoeconomic diagnosis stacked bar graph.
%   Builds a stacked bar chart from a diagnosis table where each bar represents
%   a process (or component malfunction) and each coloured segment shows the
%   exergy malfunction contribution from one process.
%   Positive and negative malfunction values are displayed on the same bar
%   through separate Octave-compatible rendering.
%
%   cGraphDiagnosis Methods:
%     cGraphDiagnosis - Construct a cGraphDiagnosis from a diagnosis table
%     showGraph       - Display the bar graph in a standalone figure window
%     showGraphUI     - Display the bar graph in an App Designer graph panel
%
%   See also cGraphResults, cDiagnosis
%
    methods
        function obj=cGraphDiagnosis(tbl,info,option)
        %cGraphDiagnosis - Construct a cGraphDiagnosis from a diagnosis table
        %
        %   Syntax:
        %     obj = cGraphDiagnosis(tbl, info)
        %     obj = cGraphDiagnosis(tbl, info, option)
        %   Input Arguments:
        %     tbl    - cTable containing the diagnosis malfunction data
        %     info   - cDiagnosis object providing method and state metadata
        %     option - Logical flag controlling whether the last bar (Demand Variation)
        %              is included (default: true; forced true for WASTE_EXTERNAL method)
        %   Output Arguments:
        %     obj - cGraphDiagnosis object (check obj.status before use)
        %
            % Check input arguments
            if nargin==2
				option=true;
            end
            if info.Method==cType.DiagnosisMethod.WASTE_EXTERNAL
				option=true;
            end
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description,' [',tbl.State,']'];
            obj.Style=cType.GraphStyles.STACK;
            % Build graph data
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
        %showGraph - Display the diagnosis bar graph in a standalone figure window
        %   Dispatches to graphDiagnosis_OC on Octave or graphDiagnosis_ML on MATLAB.
        %
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
        %showGraphUI - Display the diagnosis bar graph in an App Designer graph panel
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph
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
        %graphDiagnosis_OC - Render the diagnosis stacked bar graph under Octave
        %   Plots positive and negative values as two separate overlapping bar
        %   series because Octave does not support the BarLayout stacked mode
        %   with mixed-sign values.
        %
        %   Syntax:
        %     obj.graphDiagnosis_OC
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
        %graphDiagnosis_ML - Render the diagnosis stacked bar graph under MATLAB
        %   Uses the built-in BarLayout stacked mode with a zero baseline
        %   to display both positive and negative malfunction contributions.
        %
        %   Syntax:
        %     obj.graphDiagnosis_ML
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