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
%   See also cFormatData
    properties(GetAccess=public,SetAccess=private)
        TablesDefinition  % Tables properties struct
        tDictionary  % Tables dictionnary
        tableIndex   % Tables index
    end
    properties (Access=protected)
        cfgTables 	    % Cell tables configuration
        cfgMatrices     % Matrix tables configuration
        cfgSummary      % Summary tables configuration
        cfgTypes        % Format types configuration
        tDirectory=[]   % cTableData containig the tables directory info
    end
    methods
        function obj=cTablesDefinition()      
			% load default configuration filename			
			path=fileparts(mfilename('fullpath'));
			cfgfile=fullfile(path,cType.CFGFILE);
			try		
				config=jsondecode(fileread(cfgfile));
			catch err
				obj.messageLog(cType.ERROR,err.message);
				obj.messageLog(cType.ERROR,'Invalid %s config file',cfgfile);
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
            if obj.isValid
                res=struct('CellTables',obj.cfgTables,'MatrixTables',obj.cfgMatrices,...
                    'SummaryTables',obj.cfgSummary);
            end
        end

        function res=getTableProperties(obj,name)
        % Get the properties of a table
            res=[];
            idx=getIndex(obj.tDictionary,name);
            if cType.isEmpty(idx)
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
        % Get the tables directory in diferent formats
        %   Usage:
        %       res=getTablesDirectory(cols)
        %   Input:
        %       cols - cell array with the columns to show
        %   Output:
        %       res - cTableData containing the tables directory
            if nargin==1
                res=obj.tDirectory;
            else
                res=obj.buildTablesDirectory(varargin{:});
            end
        end

        function saveTablesDirectory(obj,filename)
        % Save result tables in different file formats depending on file extension
        %   Valid extension are: *.json, *.xml, *.csx, *.xlsx, *.txt, *.html, *.tex
        %   Usage:
        %       log=obj.saveTablesDirectory(filename)
        %   Input:
        %       filename - File name. Extension is used to determine the save mode.
        %   Output:
        %       log - cMessageLogger object with error messages
            log=saveTable(obj.tDirectory,filename);
            log.printLogger;
        end
    end

    methods(Access=protected)
        function res=getCellTableProperties(obj,name)
        % Get the properties of a cell table
        %   Input:
        %     name - table key name 
            res=[];
            idx=getIndex(obj.tDictionary,name);
            if cType.isEmpty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgTables(tId);
        end
    
        function res=getMatrixTableProperties(obj,name)
        % Get the properties of a matrix table
        %   Input:
        %     name - table key name 
            res=[];
            idx=getIndex(obj.tDictionary,name);
            if cType.isEmpty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgMatrices(tId);
        end    
    
        function res=getSummaryTableProperties(obj,name)
        % Get the properties of a summary table
        %   Input:
        %     name - table key name 
            res=[];
            idx=getIndex(obj.tDictionary,name);
            if cType.isEmpty(idx)
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
            if ~isValid(td)
                obj.printError('Invalid tables dictionary');
                return
            end
            NT=numel(obj.cfgTables);
            NM=numel(obj.cfgMatrices);
            NS=numel(obj.cfgSummary);
            N=NT+NM+NS;
            tIndex(N)=struct('name','','description','','code','',...
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
                if cType.isEmpty(colId)
                    res.messageLog(cType.ERROR,'Invalid column name %s',col);
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
            res=cTableData(data,rowNames,colNames);
            res.setProperties('tdir','Tables Directory');
            res.setState('SUMMARY');
            if isempty(obj.tDirectory)
                obj.tDirectory=res;
            end
        end
	end
end