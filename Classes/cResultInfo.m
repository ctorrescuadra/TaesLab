classdef cResultInfo < cResultSet
%cResultInfo - Class to manage the result information and tables.
%   It stores the tables and the application class info, and provide methods to show them
%   The diferent types (ResultId) of cResultInfo objects are defined in cType.ResultId
%
%   cResultInfo properties:
%     NrOfTables   - Number of tables
%     Tables       - Struct containing the tables
%     Info         - cResultId object containing the results
%
%   cResultInfo methods:
%     cResultInfo      - Construct an instance of this class
%     getResultInfo    - Get the result set object
%     getTable         - Get a table of the result set
%     getTableIndex    - Get the summary table of th results
%     summaryDiagnosis - Get the summary diagnosis info
%     summaryTables    - Get the available summary tables
%     isStateSummary   - Check if States Summary is available
%     isSampleSummary  - Check if Samples Summary is available
%
%   cResultInfo methods (inherited from cResultSet):
%     StudyCase      - Get the study case value names
%     ListOfTables   - get the table names from a result set
%     printResults   - Print results on console
%     showResults    - Show results in different interfaces
%     showGraph      - Show the graph associated to a table
%     showTableIndex - Show the table index in different interfaces
%     exportResults  - Export all the result Tables to another format
%     saveResults    - Save all the result tables in an external file
%     saveTable      - Save the results in an external file 
%     exportTable    - Export a table to another format
%
%   See also cResultSet, cResultTableBuilder, cTable
%
    properties (GetAccess=public, SetAccess=private)
        Tables       % Struct containing the tables
        NrOfTables   % Number of tables
        Info         % cResultId object containing the results
    end

    properties (Access=private)
        tableIndex   % cTableIndex object with tables information
    end

    methods
        function obj=cResultInfo(info,tables)
        %cResultInfo - Construct an instance of this class
        %   Syntax:
        %     obj = cResultInfo(info,tables)
        %   Input Arguments:
        %     info - cResultId containing the results
        %     tables - struct containig the result tables
        %   Output Arguments:
        %     obj - cResultInfo object
        
            % Check parameters
            if ~info.status
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(info));
                return
            end
            if ~isstruct(tables)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            if ~obj.checkTables(tables)
                obj.messageLog(cType.ERROR,cMessages.InvalidResultTables);
                return
            end
            % Fill the class values
            props=struct('State',info.State,'Sample',info.Sample);
            obj.Info=info;
            obj.Tables=tables;
            obj.ClassId=cType.ClassId.RESULT_INFO;
            obj.ResultId=info.ResultId;
            obj.tableIndex=cTableIndex(obj);
            obj.NrOfTables=obj.tableIndex.NrOfRows;
            obj.ModelName=info.ModelName;
            obj.setDefaultGraph(info.DefaultGraph);
            obj.setStudyCase(props);
            obj.status=info.status;
        end

        function res=getResultInfo(obj)
        %getResultInfo - Get cResultInfo object for cResultSet
        %   Syntax:
        %     res=obj.getResultInfo
        %   Output Arguments:
        %     res - cResultInfo associated to the result set
        %
            res=obj;
        end

        function res=getTable(obj,name)
        %getTable - Get the table called name
        %   Syntax:
        %     res=obj.getTable(name)
        %   Input Arguments:
        %     name - Name of the table
        %   Output Arguments:
        %     res - cTable object
        %
            res = cMessageLogger();
            if nargin<2 || ~ischar(name) || isempty(name)
                res.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            if strcmp(name,cType.TABLE_INDEX)
                res=obj.getTableIndex;
            elseif obj.existTable(name)
                res=obj.Tables.(name);
            else
                res.messageLog(cType.ERROR,cMessages.TableNotFound,name);
                return
            end
        end

        function res=getTableIndex(obj,varargin)
        %getTableIndex - Get the Table Index
        %   Syntax:
        %     res=obj.getTableIndex(options)
        %   Input Arguments:
        %     options - VarMode options
        %       cType.VarMode.NONE: cTable object (default)
        %       cType.VarMode.CELL: cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarModel.TABLE: Matlab table
        %   Output Arguments:
        %     res - Table Index info in the format selected
        %
            if nargin==1
                res=obj.tableIndex;
            else
                res=exportTable(obj.tableIndex,varargin{:});
            end
        end

        function showGraph(obj,graph)
        %showGraph - Show graph with default options
        %   Syntax:
        %     obj.showGraph(graph, options)
        %   Input Arguments:
        %     graph - graph table name [optional]
        %   See also cGraphResults
        %
            tbl = cTaesLab();
            res=getResultInfo(obj);
            if nargin==1
                graph=res.Info.DefaultGraph;
            end
            if isempty(graph) || ~ischar(graph)
                tbl.printError(cMessages.InvalidArgument);
                return;
            end
            tbl=getTable(res,graph);
            if ~tbl.status
                tbl.printLogger;
                return
            end
            if ~tbl.isGraph
		        tbl.printError(cMessages.InvalidGraph,graph);
		        return
            end
            % build graph using default parameters
            switch tbl.GraphType
                case cType.GraphType.COST
                    gr=cGraphCost(tbl);
                case cType.GraphType.DIAGNOSIS
                    gr=cGraphDiagnosis(tbl,obj.Info);
                case cType.GraphType.WASTE_ALLOCATION
                    gr=cGraphWaste(tbl,obj.Info,true);
                case cType.GraphType.RECYCLING
                    gr=cGraphRecycling(tbl);
                case cType.GraphType.DIGRAPH
                    gr=cDigraph(tbl,obj.Info);
                case cType.GraphType.DIAGRAM_FP
                    gr=cGraphDiagramFP(tbl);
                case cType.GraphType.SUMMARY
                    gr=cGraphSummary(tbl,obj.Info);
            end
            % Show Graph
            if gr.status
                gr.showGraph;
            else
                gr.printLogger;
            end
        end 

        function res=summaryDiagnosis(obj)
        %summaryDiagnosis - Get the Fuel Impact/Malfunction Cost as a string including format and unit
        %   If no output argument values are displayed on console
        % 
        %   Syntax:
        %     obj.summaryDiagnosis
        %     res=obj.summaryDiagnosis
        %   Output Arguments:
        %     res - Struct with diagnosis summary results
        %  
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.dit.Format;
                unit=obj.Tables.dit.Unit;
                tfmt=['Fuel Impact:     ',format,' ',unit];
                res.FuelImpact=sprintf(tfmt,obj.Info.FuelImpact);
                tfmt=['Technical Saving:',format,' ',unit];
                res.TechnicalSaving=sprintf(tfmt,obj.Info.TechnicalSaving);
                if nargout==0
                    fprintf('\n%s\n%s\n\n',res.FuelImpact,res.TechnicalSaving);
                end
            end
        end

        function res=summaryTables(obj)
        %summaryTable - Get/Display available summary tables
        %   If no output argument, the value is displayed in console
        %
        %   Syntax:
        %     obj.summaryTables
        %     res=obj.summaryTables;
        %   Output Arguments:
        %     res - Default Summary Option
        %
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.defaultSummaryTables;
                if nargout==0
                    fprintf('Summary Tables: %s\n\n',res);
                end
            end
        end

        function res=isStateSummary(obj)
        %isStatesSummary - Check if the States Summary results are available
        %   Syntax:
        %     res = obj.isStateSummary
        %   Output Arguments:
        %     res - true | false
        %
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isStateSummary;
            end
        end

        function res=isSampleSummary(obj)
        %isSampleSummary - Check if the Samples Summary results are available
        %   Syntax:
        %     res = obj.isStateSummary
        %   Output Arguments:
        %     res - true | false
        %
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isSampleSummary;
            end
        end
    end

    methods(Access=private)
        function setStudyCase(obj,info)
        %setStudyCase - Set state and resource sample properties for all result set tables
        %   Syntax:
        %     obj.setStudyCase(info)
        %   Input Arguments:
        %     info - struct with fields State and Sample
        %
            if ~isstruct(info) || ~all(isfield(info,{'State','Sample'})) || ...
                    ~ischar(info.State) || ~ischar(info.Sample)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            cellfun(@(x) setStudyCase(x,info),obj.tableIndex.Content);
            obj.State=info.State;
            obj.Sample=info.Sample;
        end

        function status=existTable(obj,name)
        %existTable - Check if there is a table called name available on the result set
        %   Syntax:
        %     status=obj.existTable(name)
        %   Input Arguments:
        %     name - Name of the table
        %   Output Arguments:
        %     status - true | false
        %
            status=false;
            if nargin<2 || ~ischar(name) || isempty(name)
                return
            end
            status=isfield(obj.Tables,name);
        end

        function status=checkTables(obj,tables)
        %checkTables - Check if the results set tables are valid
        %   Syntax:
        %     status=obj.checkTables(tables)
        %   Input Arguments:
        %     tables - struct containig the result tables
        %   Output Arguments:
        %     status - true | false
        %
            names=fieldnames(tables);
            test=cellfun(@(x) isValid(tables.(x)),names);
            status=all(test);
            if ~status
                cellfun(@(x) obj.addLogger(tables.(x)),names);
            end
        end

    end
end
