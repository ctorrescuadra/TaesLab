classdef cTablesDefinition < cMessageLogger
% cTablesDefinition reads the tables format configuration file 
%   This class is use for two purposes:
%   - This class is defined as base class of cFormatData reading the printformat.json
%   - Provide information of the result tables of the application (TablesDirectory)
%   Methods:
%       obj=cTablesDirectory;
%       res=obj.getTableProperties(name)
%       res=obj.getTablesDirectory(varmode)
%       res=obj.showTablesDirectory(options)
%       res=obj.saveTablesDirectory(filename)
%       res=obj.getResultIdTables(id)
%   See also cFormatData
    properties(GetAccess=public,SetAccess=private)
        TablesDefinition  % Tables properties struct
    end
    properties (Access=protected)
        cfgTables 	    % Cell tables configuration
        cfgMatrices     % Matrix tables configuration
        cfgSummary      % Summary tables configuration
        cfgTypes        % Format types configuration
        tDictionary     % Tables dictionary
        tDirectory      % cTableData containig the tables directory info
        tableIndex      % Tables index
    end
    methods
        function obj=cTablesDefinition()
        % Create an instance of the object
        % Syntax:
        %   obj = cTablesDefinition();
        %      
			% load default configuration filename			
			path=fileparts(mfilename('fullpath'));
			cfgfile=fullfile(path,cType.CFGFILE);
			try		
				config=jsondecode(fileread(cfgfile));
			catch err
				obj.messageLog(cType.ERROR,err.message);
				obj.messageLog(cType.ERROR,cMessages.InvalidConfigFile,cfgfile);
				return
			end
            % set the object properties
            obj.cfgTables=config.tables;
            obj.cfgMatrices=config.matrices;
            obj.cfgSummary=config.summary;
            obj.cfgTypes=config.format;
            obj.buildTablesDictionary;
            obj.buildTablesDirectory;
        end

        function res=get.TablesDefinition(obj)
        % Get a struct with the tables properties
            res=struct();
            if obj.status
                res=struct('CellTables',obj.cfgTables,'MatrixTables',obj.cfgMatrices,...
                    'SummaryTables',obj.cfgSummary,'Format',obj.cfgTypes);
            end
        end

        function res=getTableProperties(obj,name)
        % Get the properties of a table
        % Syntax:
        %   res = obj.getTableProperties(name)
        % Input Argument:
        %   name - Name of the table
        % Output Argument:
        %   res - structure containing table properties
        %
            res=cType.EMPTY;
            idx=obj.getTableId(name);
            if isempty(idx)
                return
            end
            tIndex=obj.tableIndex(idx);
            switch tIndex.type
                case cType.TableType.TABLE
                    res=obj.cfgTables(tIndex.tableId);
                case cType.TableType.MATRIX
                    res=obj.cfgMatrices(tIndex.tableId);
                case cType.TableType.SUMMARY
                    res=obj.cfgSummary(tIndex.tableId);
            end
        end

        function res=getTablesDirectory(obj,varargin)
        % Get the tables directory
        % Syntax: 
        %   res=getTablesDirectory(cols)
        % Input Arguments
        %   cols - cell array with the column names to show
        %     'DESCRIPTION': Table Description
        %     'RESULT_NAME': Result Info
        %     'GRAPH': true | false
        %     'TYPE':  type of table
        %     'CODE':  table code name
        %     'RESULT_CODE': Result Info code name
        % Output Arguments:
        %   res - cTableData containing the tables directory
        %
            if nargin==1
                res=obj.tDirectory;
            else
                res=obj.buildTablesDirectory(varargin{:});
            end
        end

        function saveTablesDirectory(obj,filename)
        % Save result tables in different file formats depending on file extension
        %   Valid extension are: *.json, *.xml, *.csx, *.xlsx, *.txt, *.html, *.tex
        % Syntax:
        %   log=obj.saveTablesDirectory(filename)
        % Input Argument:
        %   filename - File name with extension
        % Output Arguments:
        %   log - cMessageLogger object with error messages
            log=saveTable(obj.tDirectory,filename);
            log.printLogger;
        end

        function res=getTableId(obj,name)
        % Get tableId from dictionary. Internal use
        % Syntax:
        %   res = obj.getTableId(name)
        % Input Argument:
        %   name - Table name
        % Output Argument:
        %   res - Internal table id
        %
            res=getIndex(obj.tDictionary,name);
        end

        function res=getResultIdTables(obj,id)
        % Get the tables of an specific resultId
        % Syntax:
        %   res = obj.getResultIdTables(id)
        % Input Argument:
        %   id - ResultId
        % Output Argument
        %   res - cell array with id tables
        %
            rid=[obj.tableIndex.resultId];
            idx=find(rid==id);
            res={obj.tableIndex(idx).name};
        end

        function res=getSummaryTables(obj,option,rsc)
        % Get Summary Tables
            res=cType.EMPTY_CELL;
            tsummary={obj.cfgSummary.key};
            tbl=[obj.cfgSummary.table];
            drt=~[obj.cfgSummary.rsc];
            switch option
                case cType.SummaryId.ALL
                    res=tsummary;
                case cType.SummaryId.RESOURCES
                    idx=find(tbl==cType.RESOURCES);
                    res={obj.cfgSummary(idx).key};
                case cType.SummaryId.STATES
                    if rsc
                        idx=find(tbl==cType.STATES);
                    else
                        idx=find(drt);
                    end
                    res={obj.cfgSummary(idx).key};
            end
        end
    end

    methods(Access=protected)
        function res=getCellTableProperties(obj,name)
        % Get the properties of a cell table
        % Input:
        %   name - table key name 
            res=cType.EMPTY;
            idx=getIndex(obj.tDictionary,name);
            if isempty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgTables(tId);
        end
    
        function res=getMatrixTableProperties(obj,name)
        % Get the properties of a matrix table
        % Input:
        %   name - table key name 
            res=cType.EMPTY;
            idx=getIndex(obj.tDictionary,name);
            if isempty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgMatrices(tId);
        end    
    
        function res=getSummaryTableProperties(obj,name)
        % Get the properties of a summary table
        % Input:
        %   name - table key name 
            res=cType.EMPTY;
            idx=getIndex(obj.tDictionary,name);
            if isempty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgSummary(tId);
        end
    end

    methods(Access=private)
		function buildTablesDictionary(obj)
        % Build the table dictionary
            % Create the index dictionary
            tCodes=fieldnames(cType.Tables);
            tNames=struct2cell(cType.Tables);
            td=cDictionary(tNames);
            if ~td.status
                td.printLogger;
                obj.printError(cMessages.InvalidTableDict);
                return
            end
            NT=numel(obj.cfgTables);
            NM=numel(obj.cfgMatrices);
            NS=numel(obj.cfgSummary);
            N=NT+NM+NS;
            tIndex(N)=struct('name',cType.EMPTY_CHAR,'description',cType.EMPTY_CHAR,'code',cType.EMPTY_CHAR,...
                'resultId',0,'graph',0,'type',0,'tableId',0);
            % Retrieve information for cell tables
            for i=1:NT
                key=obj.cfgTables(i).key;
                idx=td.getIndex(key);
                tIndex(idx).name=key;
                tIndex(idx).description=obj.cfgTables(i).description;
                tIndex(idx).code=tCodes{idx};
                tIndex(idx).resultId=obj.cfgTables(i).resultId;
                tIndex(idx).graph=obj.cfgTables(i).graph;
                tIndex(idx).type=cType.TableType.TABLE;
                tIndex(idx).tableId=i;
            end
            % Retrive information for matrix tables
            for i=1:NM
                key=obj.cfgMatrices(i).key;
                idx=td.getIndex(key);
                tIndex(idx).name=key;
                tIndex(idx).description=obj.cfgMatrices(i).header;
                tIndex(idx).code=tCodes{idx};
                tIndex(idx).resultId=obj.cfgMatrices(i).resultId;
                tIndex(idx).graph=obj.cfgMatrices(i).graph;
                tIndex(idx).type=cType.TableType.MATRIX;
                tIndex(idx).tableId=i;
            end
            % Retrieve information for summary tables
            for i=1:NS
                key=obj.cfgSummary(i).key;
                idx=td.getIndex(key);
                tIndex(idx).name=key;
                tIndex(idx).description=obj.cfgSummary(i).header;
                tIndex(idx).code=tCodes{idx};
                tIndex(idx).resultId=cType.ResultId.SUMMARY_RESULTS;
                tIndex(idx).graph=obj.cfgSummary(i).graph;
                tIndex(idx).type=cType.TableType.SUMMARY;
                tIndex(idx).tableId=i;
            end
            % Create the dictionary (name,id)
            obj.tDictionary=td;
            obj.tableIndex=tIndex;
        end
 
        function res=buildTablesDirectory(obj,cols)
        % Get the tables directory as cTableData
            res=cMessageLogger;
            if nargin==1
                cols=cType.DIR_COLS_DEFAULT;
            end
            tI=obj.tableIndex;
            N=numel(tI);
            M=numel(cols);
            rowNames={tI.name};
            colNames=cell(1,M+1);
            colNames{1}='Table';
            data=cell(N,M);
            resultCode=fieldnames(cType.ResultId);
            for i=1:M
                colId=cType.getDirColumns(cols{i});
                if isempty(colId)
                    res.messageLog(cType.ERROR,cMessages.InvalidArgument,cols{i});
                    return
                end
                colNames{i+1}=cType.DirColNames{colId};
                switch colId
                    case cType.DirCols.DESCRIPTION
                        data(:,i)={tI.description};
                    case cType.DirCols.RESULT_NAME
                        data(:,i)=[cType.Results([tI.resultId])];
                    case  cType.DirCols.GRAPH
                        data(:,i)=log2str([tI.graph]);
                    case  cType.DirCols.TYPE
                        data(:,i)=[cType.TypeTables([tI.type])];
                    case cType.DirCols.CODE
                        data(:,i)={tI.code};
                    case cType.DirCols.RESULT_CODE
                        data(:,i)=[resultCode([tI.resultId])];
                end
            end
            props.Name='tdir';props.Description='Tables Directory';
            props.State='SUMMARY';props.Sample=cType.EMPTY_CHAR;
            res=cTableData(data,rowNames,colNames,props);
            res.setStudyCase(props);
            if isempty(obj.tDirectory)
                obj.tDirectory=res;
            end
        end
	end
end