classdef cResultInfo < cResultSet
% cResultInfo is a class container of the application results
%   It stores the tables and the application class info.
%   The diferent types (ResultId) of cResultInfo objects are defined in cType.ResultId
%
% cResultInfo constructor:
%   obj = cResultInfo(info,tables)
%
% cResultInfo properties:
%   NrOfTables   - Number of tables
%   Tables       - Struct containing the tables
%   Info         - cResultId object containing the results
%
% cResultInfo Methods:
%   getResultInfo    - Get the result set info
%   getTable         - Get a table of the result info
%   getTableIndex    - Get the summary table of th results
%   summaryDiagnosis - Get the summary diagnosis info
%   summaryTables    - Get the available summary tables
%   isStateSummary   - Check if States Summary is available
%   isSampleSummary  - Check if Samples Summary is available
%
% See also cResultSet, cResultTableBuilder, cTable
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
        % Construct an instance of this class
        %  Syntax:
        %   obj = cResultInfo(info,tables)
        %  Input Arguments:
        %   info - cResultId containing the results
        %   tables - struct containig the result tables
        %
            % Check parameters
            obj=obj@cResultSet(info.ResultId);
            if ~info.status
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(info));
                return
            end
            if ~isstruct(tables)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Fill the class values
            obj.Info=info;
            obj.Tables=tables;
            obj.tableIndex=cTableIndex(obj);
            obj.NrOfTables=obj.tableIndex.NrOfRows;
            obj.ModelName=info.ModelName;
            obj.setDefaultGraph(info.DefaultGraph);
            obj.setStudyCase(info);
            obj.status=info.status;
        end

        function res=getResultInfo(obj)
        % getResultInfo - get cResultInfo object for cResultSet
        % Syntax:
        %   res=obj.getResultInfo
        % Output Arguments
        %   res - cResultInfo associated to the result set
        %
            res=obj;
        end

        function res=getTable(obj,name)
        % Get the table called name
        % Syntax:
        %   res=obj.getTable(name)
        % Input Argument:
        %   name - Name of the table
        % Output Argument:
        %   res - cTable object
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
        % Get the Table Index
        % Syntax:
        %   res=obj.getTableIndex(options)
        % Input Arguments:
        %   options - VarMode options
        %     cType.VarMode.NONE: cTable object (default)
        %     cType.VarMode.CELL: cell array
        %     cType.VarMode.STRUCT: structured array
        %     cType.VarModel.TABLE: Matlab table
        % Output Argument:
        %   res - Table Index info in the format selected
        %
            if nargin==1
                res=obj.tableIndex;
            else
                res=exportTable(obj.tableIndex,varargin{:});
            end
        end

        function res=summaryDiagnosis(obj)
        % Get the Fuel Impact/Malfunction Cost as a string including format and unit
        %   If no output argument values are displayed on console
        % Syntax:
        %   obj.summaryDiagnosis
        %   res=obj.summaryDiagnosis
        % Output Arguments:
        %   res - Struct with diagnosis summary results
        %  
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.dit.Format;
                unit=obj.Tables.dit.Unit;
                tfmt=['Fuel Impact:     ',format,' ',unit];
                res.FuelImpact=sprintf(tfmt,obj.Info.FuelImpact);
                tfmt=['Malfunction Cost:',format,' ',unit];
                res.MalfunctionCost=sprintf(tfmt,obj.Info.TotalMalfunctionCost);
                if nargout==0
                    fprintf('%s\n%s\n\n',res.FuelImpact,res.MalfunctionCost);
                end
            end
        end

        function res=summaryTables(obj)
        % Get/Display available summary tables
        %   If no output argument, the value is displayed in console 
        % Syntax:
        %   obj.summaryTables
        %   res=obj.summaryTables;
        % Output Argument
        %   res - Default Summary Option
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.defaultSummaryTables;
                if nargout==0
                    fprintf('Summary Tables: %s\n\n',res);
                end
            end
        end

        function res=isStateSummary(obj)
        % Check if the States Summary results are available
        % Syntax:
        %   res = obj.isStateSummary
        % Output Arguments:
        %   res - true | false
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isStateSummary;
            end
        end

        function res=isSampleSummary(obj)
        % Check if the Samples Summary results are available
        % Syntax:
        %   res = obj.isStateSummary
        % Output Arguments:
        %   res - true | false
            res=cType.EMPTY;
            if obj.status && obj.ResultId==cType.ResultId.SUMMARY_RESULTS
                res=obj.Info.isSampleSummary;
            end
        end
    end

    methods(Access=private)
        function setStudyCase(obj,info)
        % Set model and state properties
            cellfun(@(x) setStudyCase(x,info),obj.tableIndex.Content);
            obj.State=info.State;
            obj.Sample=info.Sample;
        end

        function status=existTable(obj,name)
        % Check if there is a table called name
            status=isfield(obj.Tables,name);
        end
    end
end
