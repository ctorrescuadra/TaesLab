classdef cResultInfo < cResultSet
%cResultInfo - Concrete result container that stores tables produced by a computation module.
%   Each cResultInfo wraps a cResultId subclass (the computation result) together with
%   the set of cTable objects it produced, and exposes the full cResultSet interface
%   for display, export, and persistence.
%   The different result types (ResultId) are defined in cType.ResultId.
%
%   cResultInfo Properties:
%     NrOfTables - Number of tables in the result set
%     Tables     - Struct whose fields are the cTable result objects, keyed by table name
%     Info       - cResultId subclass object that produced the results
%
%   cResultInfo Methods:
%     cResultInfo      - Construct a cResultInfo from a cResultId and a tables struct
%     getResultInfo    - Return this object (satisfies the cResultSet contract)
%     getTable         - Retrieve a named cTable from the result set
%     getTableIndex    - Get the table index in the selected format
%     showGraph        - Show the default or named graph for these results
%     summaryDiagnosis - Display or return the Fuel Impact and Technical Saving values
%     summaryTables    - Display or return the available summary table options
%     isStateSummary   - True when state-comparison summary tables are available
%     isSampleSummary  - True when resource-sample summary tables are available
%
%   cResultInfo Methods (inherited from cResultSet):
%     StudyCase      - Get the current state and sample names
%     ListOfTables   - Get the names of all available tables
%     ListOfGraphs   - Get the names of all graph-capable tables
%     printResults   - Print all result tables on the console
%     showResults    - Display a named table in the selected view
%     showTableIndex - Display the table index in the selected view
%     exportResults  - Export all result tables to a MATLAB variable
%     saveResults    - Save all result tables to an external file
%     saveTable      - Save a single named table to an external file
%     exportTable    - Export a single named table to a MATLAB variable
%
%   See also cResultSet, cResultTableBuilder, cTable
%
    properties (GetAccess=public, SetAccess=private)
        Tables       % Struct of cTable objects keyed by table name
        NrOfTables   % Number of tables in the result set
        Info         % cResultId subclass object that produced these results
    end

    properties (Access=private)
        tableIndex   % cTableIndex object that organises the tables for display
    end

    methods
        function obj=cResultInfo(info,tables)
        %cResultInfo - Construct a cResultInfo from a computation result and its tables
        %   Validates both arguments before storing them.  Sets ClassId, ResultId,
        %   ModelName, State, Sample, and DefaultGraph from the supplied cResultId.
        %
        %   Syntax:
        %     obj = cResultInfo(info, tables)
        %   Input Arguments:
        %     info   - Valid cResultId subclass object produced by a computation module
        %     tables - Struct containing the cTable result objects, keyed by table name
        %   Output Arguments:
        %     obj - cResultInfo object (check obj.status before use)
        
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
        %getResultInfo - Return this cResultInfo (satisfies the cResultSet abstract contract)
        %   Called internally by cResultSet methods to obtain the cResultInfo instance.
        %
        %   Syntax:
        %     res = obj.getResultInfo
        %   Output Arguments:
        %     res - This cResultInfo object
        %
            res=obj;
        end

        function res=getTable(obj,name)
        %getTable - Retrieve a named table from the result set
        %   Accepts the special name cType.TABLE_INDEX to return the table index.
        %   Returns a cMessageLogger with an error if the name is not found.
        %
        %   Syntax:
        %     res = obj.getTable(name)
        %   Input Arguments:
        %     name - Name of the table (character vector)
        %   Output Arguments:
        %     res - cTable object, or cMessageLogger on error
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
        %showGraph - Show the graph associated with a graph-capable table
        %   When called without arguments the DefaultGraph table is used.
        %   The appropriate graph class (cGraphCost, cGraphDiagnosis, cDigraph, etc.)
        %   is selected automatically based on the table's GraphType property.
        %
        %   Syntax:
        %     obj.showGraph
        %     obj.showGraph(graph)
        %   Input Arguments:
        %     graph - Name of a graph-capable table (optional, defaults to DefaultGraph)
        %   See also cGraphCost, cGraphDiagnosis, cDigraph, cGraphDiagramFP, cGraphSummary
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
                    gr=cGraphDiagramFP(tbl,obj.Info);
                case cType.GraphType.SUMMARY
                    gr=cGraphSummary(tbl,obj.Info);
                case cType.GraphType.RESOURCE_COST
                    gr=cGraphCostRSC(tbl,obj.Info);
            end
            % Show Graph
            if gr.status
                gr.showGraph;
            else
                gr.printLogger;
            end
        end 

        function res=summaryDiagnosis(obj)
        %summaryDiagnosis - Return or display the Fuel Impact and Technical Saving for a diagnosis result
        %   Only meaningful when ResultId is cType.ResultId.THERMOECONOMIC_DIAGNOSIS.
        %   Returns an empty value for any other result type.
        %   When called without an output argument the values are printed to the console.
        %
        %   Syntax:
        %     obj.summaryDiagnosis
        %     res = obj.summaryDiagnosis
        %   Output Arguments:
        %     res - Struct with fields FuelImpact and TechnicalSaving (formatted strings)
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
        %summaryTables - Return or display the available summary table options
        %   Only meaningful when ResultId is cType.ResultId.SUMMARY_RESULTS.
        %   Returns an empty value for any other result type.
        %   When called without an output argument the value is printed to the console.
        %
        %   Syntax:
        %     obj.summaryTables
        %     res = obj.summaryTables
        %   Output Arguments:
        %     res - Character vector describing the default summary table selection
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
        %isStateSummary - True when state-comparison summary tables are available
        %   Only meaningful when ResultId is cType.ResultId.SUMMARY_RESULTS;
        %   returns an empty value for any other result type.
        %
        %   Syntax:
        %     res = obj.isStateSummary
        %   Output Arguments:
        %     res - Logical true/false, or empty for non-summary result types
        %
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isStateSummary;
            end
        end

        function res=isSampleSummary(obj)
        %isSampleSummary - True when resource-sample summary tables are available
        %   Only meaningful when ResultId is cType.ResultId.SUMMARY_RESULTS;
        %   returns an empty value for any other result type.
        %
        %   Syntax:
        %     res = obj.isSampleSummary
        %   Output Arguments:
        %     res - Logical true/false, or empty for non-summary result types
        %
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isSampleSummary;
            end
        end
    end

    methods(Access=private)
        function setStudyCase(obj,info)
        %setStudyCase - Propagate State and Sample names to all tables in the result set
        %   Called once during construction; propagates the study case context to every
        %   table in the tableIndex so that display methods can show the correct context.
        %
        %   Syntax:
        %     obj.setStudyCase(info)
        %   Input Arguments:
        %     info - Struct with character-vector fields State and Sample
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
        %existTable - True when a table with the given name exists in this result set
        %   Syntax:
        %     status = obj.existTable(name)
        %   Input Arguments:
        %     name - Table name to look up (character vector)
        %   Output Arguments:
        %     status - Logical true if the table exists, false otherwise
        %
            status=false;
            if nargin<2 || ~ischar(name) || isempty(name)
                return
            end
            status=isfield(obj.Tables,name);
        end

        function status=checkTables(obj,tables)
        %checkTables - Validate all cTable objects in the tables struct
        %   Returns false and logs errors if any table is invalid.
        %
        %   Syntax:
        %     status = obj.checkTables(tables)
        %   Input Arguments:
        %     tables - Struct containing the cTable result objects
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
