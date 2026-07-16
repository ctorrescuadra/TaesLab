classdef cTablesDefinition < cMessageLogger
%cTablesDefinition - Registry of result-table definitions for TaesLab.
%   cTablesDefinition reads the toolbox configuration file (cType.CFGFILE)
%   from the Config directory and builds an internal registry that maps
%   every result table name to its properties and configuration struct.
%
%   The registry covers three categories of tables:
%     TABLE   - Cell tables   (mixed text/numeric columns, cTableCell)
%     MATRIX  - Matrix tables (square numeric matrices, cTableMatrix)
%     SUMMARY - Summary tables (multi-state/sample comparisons)
%
%   Two lookup layers are maintained:
%     1. tDictionary (cDictionary)  - maps table name → linear index
%     2. tableIndex  (struct array) - holds name, description, resultId,
%                                     type, tableId and graph flag per entry
%
%   In addition, a tables-directory cell array (tDirectory) is pre-built
%   for fast construction of the cTableData directory returned by
%   getTablesDirectory.
%
%   cTablesDefinition Properties (protected):
%     cfgDataModel  - Data-model table configuration structs
%     cfgTables     - Cell table configuration structs
%     cfgMatrices   - Matrix table configuration structs
%     cfgSummary    - Summary table configuration structs
%     cfgTypes      - Format-type configuration structs
%     tDictionary   - cDictionary mapping table names to indices
%     tableIndex    - Struct array with per-table metadata
%     tableNames    - Cell array of all registered table names
%     tDirectory    - Pre-built cell matrix used by getTablesDirectory
%
%   cTablesDefinition Methods:
%     cTablesDefinition      - Construct the registry by reading the config file
%     getTablesDirectory     - Return a cTableData listing all registered tables
%     getTableDefinition     - Return the raw config struct for a named table
%     getTableInfo           - Return a summary-info struct for a named table
%     getTableId             - Return the dictionary index of a table name
%     getResultIdTables      - Return the names of all tables for a ResultId
%     getDataModelProperties - Return the data-model table configuration(s)
%     getCellTables          - Return cell-table configuration struct(s)
%     getMatrixTables        - Return matrix-table configuration struct(s)
%     getSummaryTables       - Return summary-table configuration struct(s)
%
%   See also cFormatData, cType.ResultId, cType.TableType
%
    properties (Access=protected)
        cfgDataModel    % Data model tables configuration
        cfgTables 	    % Cell tables configuration
        cfgMatrices     % Matrix tables configuration
        cfgSummary      % Summary tables configuration
        cfgTypes        % Format types configuration
        tDictionary     % Tables dataset
        tableIndex      % Tables index struct
        tableNames      % Names of the tables
        tDirectory      % Tables data info
    end

    methods
        function obj=cTablesDefinition()
        %cTablesDefinition - Construct the registry by reading the config file
        %   Reads cType.CFGFILE from the Config directory, populates the six
        %   configuration struct arrays (cfgDataModel, cfgTables, cfgMatrices,
        %   cfgSummary, cfgTypes), then runs two internal build steps:
        %     1. buildTablesDictionary - creates tDictionary and tableIndex
        %     2. buildTablesDirectory  - pre-builds tDirectory for fast lookup
        %   Construction sets the object status to false when the config file
        %   cannot be read or the dictionary build step detects inconsistencies.
        %
        %   Syntax:
        %     obj = cTablesDefinition()
        %
        %   Output Arguments:
        %     obj - cTablesDefinition object.  Use isValid(obj) to confirm
        %           successful construction before calling other methods.
        %
              
			% load default configuration filename			
			cfgfile=fullfile(cType.ConfigPath,cType.CFGFILE);
            config=importJSON(obj,cfgfile);
            if isempty(config)
                return
            end
            % set the object properties
            obj.cfgDataModel=config.datamodel;
            obj.cfgTables=config.tables;
            obj.cfgMatrices=config.matrices;
            obj.cfgSummary=config.summary;
            obj.cfgTypes=config.format;
            obj.buildTablesDictionary;
            if obj.status
                obj.buildTablesDirectory;
            end
        end

        function res=getTablesDirectory(obj,cols)
        %getTablesDirectory - Return a cTableData listing all registered tables
        %   Builds a cTableData whose rows are the registered table names and
        %   whose columns are selected from the available directory columns.
        %   When called with no output argument, the table is printed to the
        %   console instead of being returned.
        %
        %   Available column identifiers (elements of cols):
        %     'DESCRIPTION'  - Human-readable table description
        %     'RESULT_NAME'  - Name of the associated ResultId
        %     'GRAPH'        - Whether a graph view is available ('true'/'false')
        %     'TYPE'         - Table category: 'TABLE', 'MATRIX', or 'SUMMARY'
        %     'CODE'         - Internal table code name (cType.Tables field)
        %     'RESULT_CODE'  - Internal ResultId code name (cType.ResultId field)
        %
        %   Syntax:
        %     res = obj.getTablesDirectory()         % uses default columns
        %     res = obj.getTablesDirectory(cols)     % custom column selection
        %     obj.getTablesDirectory(...)            % prints to console
        %
        %   Input Arguments:
        %     cols - (optional) Cell array of column identifier strings.
        %            Defaults to cType.DIR_COLS_DEFAULT when omitted.
        %
        %   Output Arguments:
        %     res  - cTableData with the selected columns, or a cMessageLogger
        %            with status false if any element of cols is invalid.
        %
            res=cMessageLogger();
            if nargin==1
                cols=cType.DIR_COLS_DEFAULT;
            end
            [tf,idx]=cType.checkDirColumns(cols);
            if ~tf
                missing=cols(idx);
                res.messageLog(cType.ERROR,cMessages.InvalidColumnNames,strjoin(missing,', '));
                return
            end
            data=obj.tDirectory(:,idx);
            tI=obj.tableIndex;
            rowNames={tI.name};
            colNames=['Table',cols];
            props.Name='tdir';props.Description='Tables Directory';
            props.State='SUMMARY';props.Sample=cType.EMPTY_CHAR;
            res=cTableData(data,rowNames,colNames,props);
            res.setStudyCase(props);
            if nargout==0
                printTable(res);
            end
        end
 
        function res=getTableInfo(obj,name)
		%getTableInfo - Return a summary-info struct for a named table
        %   Looks up name in the registry and returns a struct with the
        %   six directory-level properties of the table.  This is the
        %   presentation-oriented counterpart of getTableDefinition, which
        %   returns the raw configuration struct from the JSON file.
        %   When called with no output argument, the struct is displayed
        %   in the console via disp.
        %
        %   Syntax:
        %     res = obj.getTableInfo(name)   % returns struct
        %     obj.getTableInfo(name)          % displays struct in console
        %
        %   Input Arguments:
        %     name - Table name string to look up.
        %
        %   Output Arguments:
        %     res  - Struct with fields: Name, Description, TableCode,
        %            ResultId, TableType, Graph.  Returns cType.EMPTY when
        %            name is not a string or is not registered.
        %
			res=cType.EMPTY;
            % Check input arguments
            if nargin<2 || ~ischar(name)
                return
            end
            % Get table index
			idx=obj.getTableId(name);
            % Get table properties
            if idx
			    td=obj.tDirectory(idx,:);
				res=struct();
				res.Name=obj.tableNames{idx};
				res.Description=td{cType.DirCols.DESCRIPTION};
				res.TableCode=td{cType.DirCols.CODE};
				res.ResultId=td{cType.DirCols.RESULT_CODE};
				res.TableType=td{cType.DirCols.TYPE};
				res.Graph=td{cType.DirCols.GRAPH};
                if nargout==0
                    disp(cType.BLANK)
                    disp(res)
                end
            end 
		end

        function res=getTableDefinition(obj,name)
        %getTableDefinition - Return the raw configuration struct for a named table
        %   Looks up name in the registry and returns the configuration struct
        %   exactly as read from the JSON config file.  The struct fields
        %   vary by table type:
        %     TABLE   - fields from cfgTables  (e.g. key, description, cols)
        %     MATRIX  - fields from cfgMatrices (e.g. key, header, rows)
        %     SUMMARY - fields from cfgSummary  (e.g. key, header, stable)
        %   For presentation-oriented metadata use getTableInfo instead.
        %
        %   Syntax:
        %     res = obj.getTableDefinition(name)
        %
        %   Input Arguments:
        %     name - Table name string to look up.
        %
        %   Output Arguments:
        %     res  - Configuration struct for the table, or cType.EMPTY when
        %            name is not a string, is not registered, or has an
        %            unrecognised table type.
        %
            res=cType.EMPTY;
            if nargin<2 || ~ischar(name)
                return
            end
            idx=obj.tDictionary.getIndex(name);
            if ~idx
                return
            end
            tmp=obj.tableIndex(idx);
            switch tmp.type
                case cType.TableType.TABLE
                    res=obj.cfgTables(tmp.tableId);
                case cType.TableType.MATRIX
                    res=obj.cfgMatrices(tmp.tableId);
                case cType.TableType.SUMMARY
                    res=obj.cfgSummary(tmp.tableId);
                otherwise
                    res=cType.EMPTY;
            end
        end

        function res=getTableId(obj,name)
        %getTableId - Return the dictionary index for a table name
        %   Wraps cDictionary.getIndex on the internal tDictionary.
        %   Intended for internal use by other methods that need a fast
        %   numeric handle into tableIndex or tDirectory.
        %
        %   Syntax:
        %     res = obj.getTableId(name)
        %
        %   Input Arguments:
        %     name - Table name string to look up.
        %
        %   Output Arguments:
        %     res  - Positive integer index if name is registered;
        %            0 if name is unknown; cType.EMPTY if name is not
        %            a string or is missing.
        %
            res=cType.EMPTY;
            if nargin<2 || ~ischar(name)
                return
            end
            res=getIndex(obj.tDictionary,name);
        end

        function res=getResultIdTables(obj,id)
        %getResultIdTables - Return the names of all tables for a given ResultId
        %   Scans the tableIndex for entries whose resultId field matches id
        %   and returns their names as a cell array of strings.
        %
        %   Syntax:
        %     res = obj.getResultIdTables(id)
        %
        %   Input Arguments:
        %     id  - Numeric ResultId value (see cType.ResultId).
        %
        %   Output Arguments:
        %     res - Cell array of table name strings associated with id.
        %           Returns cType.EMPTY_CELL when id is not numeric or
        %           no tables are registered for that ResultId.
        %
            res=cType.EMPTY_CELL;
            if nargin<2 || ~isnumeric(id)
                return
            end
            rid=[obj.tableIndex.resultId];
            idx=find(rid==id);
            res={obj.tableIndex(idx).name};
        end

        function res=getDataModelProperties(obj,idx)
        %getDataModelProperties - Return data-model table configuration struct(s)
        %   Provides access to the cfgDataModel array, which defines the
        %   tables used to present the input data (flows, processes, exergy
        %   states, resources, waste definitions, format).
        %
        %   Syntax:
        %     res = obj.getDataModelProperties()      % all entries
        %     res = obj.getDataModelProperties(idx)   % single entry
        %
        %   Input Arguments:
        %     idx - (optional) Positive integer index into cfgDataModel.
        %           When omitted, the entire struct array is returned.
        %
        %   Output Arguments:
        %     res - Configuration struct (scalar when idx is provided) or
        %           struct array (when idx is omitted).
        %
            if nargin==2
                res=obj.cfgDataModel(idx);
            else
                res=obj.cfgDataModel;
            end
        end

        function res=getMatrixTables(obj,idx)
        %getMatrixTables - Return matrix-table configuration struct(s)
        %   Provides access to the cfgMatrices array, which defines the
        %   square numeric tables (adjacency matrices, cost allocation
        %   matrices, FP tables) used throughout the toolbox.
        %
        %   Syntax:
        %     res = obj.getMatrixTables()       % all entries
        %     res = obj.getMatrixTables(idx)    % single entry
        %
        %   Input Arguments:
        %     idx - (optional) Positive integer index into cfgMatrices.
        %           When omitted, the entire struct array is returned.
        %
        %   Output Arguments:
        %     res - Configuration struct (scalar when idx provided) or
        %           struct array (when idx is omitted).
        %
            if nargin==2
                res=obj.cfgMatrices(idx);
            else
                res=obj.cfgMatrices;
            end
        end

        function res=getCellTables(obj,idx)
        %getCellTables - Return cell-table configuration struct(s)
        %   Provides access to the cfgTables array, which defines the
        %   mixed text/numeric tables (process descriptions, efficiency
        %   tables, cost summaries) used throughout the toolbox.
        %
        %   Syntax:
        %     res = obj.getCellTables()       % all entries
        %     res = obj.getCellTables(idx)    % single entry
        %
        %   Input Arguments:
        %     idx - (optional) Positive integer index into cfgTables.
        %           When omitted, the entire struct array is returned.
        %
        %   Output Arguments:
        %     res - Configuration struct (scalar when idx provided) or
        %           struct array (when idx is omitted).
        %
            if nargin==2
                res=obj.cfgTables(idx);
            else
                res=obj.cfgTables;
            end
        end

        function res=getSummaryTables(obj,option,rsc)
        %getSummaryTables - Return summary-table configuration struct(s)
        %   Filters the cfgSummary array according to the requested summary
        %   type and the resource-tables flag.
        %
        %   Syntax:
        %     res = obj.getSummaryTables()             % all summary tables
        %     res = obj.getSummaryTables(option)       % filtered by option
        %     res = obj.getSummaryTables(option, rsc)  % filtered by option and rsc
        %
        %   Input Arguments:
        %     option - (optional) Summary type selector (cType.SummaryId value):
        %                cType.SummaryId.ALL       - all summary tables (default)
        %                cType.SummaryId.STATES    - tables for multi-state comparison
        %                cType.SummaryId.RESOURCES - tables for multi-sample comparison
        %     rsc    - (optional) Logical flag used only with STATES option.
        %              When true (default for ALL), includes resource-cost tables.
        %              When false, excludes resource-cost tables from STATES results.
        %
        %   Output Arguments:
        %     res    - Struct array of summary-table configuration entries,
        %              or cType.EMPTY_CELL if no matching entries are found.
        %
            res=cType.EMPTY_CELL;
             % Get optional arguments
            switch nargin
                case 1
                    option=cType.SummaryId.ALL;
                    rsc=true;
                case 2
                    rsc=false;
            end
            % Get summary properties
            tsummary=obj.cfgSummary;
            stbl=[tsummary.stable];
            drt=~[tsummary.rsc];
            % Select tables depending of option
            switch option
                case cType.SummaryId.ALL
                    res=tsummary;
                case cType.SummaryId.RESOURCES
                    idx=find(stbl==cType.RESOURCES);
                    res=obj.cfgSummary(idx);
                case cType.SummaryId.STATES
                    if rsc
                        idx=find(stbl==cType.STATES);
                    else
                        idx=find(drt);
                    end
                    res=obj.cfgSummary(idx);
            end
        end
    end

    methods(Access=private)
		function buildTablesDictionary(obj)
        %buildTablesDictionary - Build the tDictionary and tableIndex from config arrays
        %   Iterates over cfgTables, cfgMatrices and cfgSummary, resolves each
        %   table key against the cType.Tables enumeration, and fills the
        %   tableIndex struct array with metadata (name, description, code,
        %   resultId, graph, type, tableId).  Sets the object status to false
        %   if any key cannot be resolved.
        %   Results are stored in obj.tDictionary, obj.tableIndex, obj.tableNames.
        %
            % Create the index dataset
            tCodes=fieldnames(cType.Tables);
            tNames=struct2cell(cType.Tables);
            td=cDictionary(tNames);
            if ~td.status
                td.printLogger;
                obj.messageLog(cType.ERROR,cMessages.InvalidTableDict);
                return
            end
            NT=numel(obj.cfgTables);
            NM=numel(obj.cfgMatrices);
            NS=numel(obj.cfgSummary);
            N=NT+NM+NS;
            cIndex=cell(N,1);
            % Retrieve information for cell tables
            for i=1:NT
                val=obj.cfgTables(i);
                idx=td.getIndex(val.key);
                if ~idx
                    obj.messageLog(cType.ERROR,cMessages.TableNotAvailable,key);
                    return
                end
                cIndex{idx}=struct('name',val.key,...
                            'description',val.description,...
                            'code',tCodes{idx},...
                            'resultId',val.resultId,...
                            'graph',val.graph,...
                            'type',cType.TableType.TABLE,...
                            'tableId',i);
            end
            % Retrieve information for matrix tables
            for i=1:NM
                val=obj.cfgMatrices(i);
                idx=td.getIndex(val.key);
                if ~idx
                    obj.messageLog(cType.ERROR,cMessages.TableNotAvailable,key);
                    continue
                end
                cIndex{idx}=struct('name',val.key,...
                            'description',val.header,...
                            'code',tCodes{idx},...
                            'resultId',val.resultId,...
                            'graph',val.graph,...
                            'type',cType.TableType.MATRIX,...
                            'tableId',i);  
            end
            % Retrieve information for summary tables
            for i=1:NS
                val=obj.cfgSummary(i);
                idx=td.getIndex(val.key);
                if ~idx
                    obj.messageLog(cType.ERROR,cMessages.TableNotAvailable,key);
                    continue
                end
                cIndex{idx}=struct('name',val.key,...
                            'description',val.header,...
                            'code',tCodes{idx},...
                            'resultId',val.resultId,...
                            'graph',val.graph,...
                            'type',cType.TableType.SUMMARY,...
                            'tableId',i); 
            end
            % Assign class properties
            obj.tableNames=tNames;
            obj.tDictionary=td;
            obj.tableIndex=cell2mat(cIndex);
        end
 
        function buildTablesDirectory(obj)
        %buildTablesDirectory - Pre-build the tDirectory cell matrix from tableIndex
        %   Converts the tableIndex struct array into a plain N×M cell matrix
        %   (N tables × M directory columns) for fast column-selection in
        %   getTablesDirectory.  Column order follows cType.DirCols indices.
        %   Result is stored in obj.tDirectory.
        %
            N=numel(obj.tableNames);
            M=numel(cType.DirColNames);
            % fill table data
            data=cell(N,M);
            tI=obj.tableIndex;
            resultCode=fieldnames(cType.ResultId);
            data(:,cType.DirCols.DESCRIPTION)={tI.description};
            data(:,cType.DirCols.RESULT_NAME)=[cType.Results([tI.resultId])];
            data(:,cType.DirCols.GRAPH)=arrayfun(@(x) mat2str(logical(x)),[tI.graph],'UniformOutput',false);
            data(:,cType.DirCols.TYPE)=[cType.TypeTables([tI.type])];
            data(:,cType.DirCols.CODE)={tI.code};
            data(:,cType.DirCols.RESULT_CODE)=[resultCode([tI.resultId])];
            obj.tDirectory=data;
        end
	end
end