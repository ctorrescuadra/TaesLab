classdef cTablesDefinition < cMessageLogger
%cTablesDefinition - Get the results tables properties. 
%   The printformat.json file, contains the results tables properties
%   This function reads the file and provides information about it.
%
%   cTablesDefinition constructor:
%     obj = cTablesDefinition()
%
%   cTablesDefinition methods:
%     getTablesDirectory - Get the a cTableData with the tables index
%     getTableDefinition - Get configurarion properties of a table
%     getTableInfo       - Get info about the a table definition
%     getTableId         - Get the TableId of a table
%     getResultIdTables  - Get the tables configuration of a ResultId
%     getCellTables      - Get the Cell tables configuration
%     getMatrixTables    - Get the Matrix tables configuration     
%     getSummaryTables   - Get the Summary tables configuration
%
%   See also cFormatData, printconfig.json
%
    properties (Access=protected)
        cfgDataModel    % Data model tables configurarion
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
        %cTablesDefinition - Create an instance of the object
        % Syntax:
        %   obj = cTablesDefinition();
        % Output Argument:
        %   obj - cTableDefinition object
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
        %getTablesDirectory - Get the tables directory
        %   Syntax: 
        %     res=obj.getTablesDirectory(cols)
        %   Input Arguments
        %     cols - cell array with the column names to show
        %       'DESCRIPTION': Table Description
        %       'RESULT_NAME': Result Info
        %       'GRAPH': true | false
        %       'TYPE':  type of table
        %       'CODE':  table code name
        %       'RESULT_CODE': Result Info code name
        %     if cols parameter is missing cType.DIR_COLS_DEFAULT is used
        %   Output Arguments:
        %     res - cTableData containing the tables directory
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
		%getTableInfo - Get the properties of a table
		%   Syntax:
		%     res = obj.getTableInfo(name)
		%   Input Arguments:
		%     name - Name of the table
		%   Output Arguments:
		%     res - Struct with the properties of the table
		%
			res=cType.EMPTY;
            if nargin<2 || ~ischar(name)
                return
            end
			idx=obj.getTableId(name);
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
        %getTableDefinition - Get the properties of a table
        %   Syntax:
        %     res = obj.getTableDefinition(name)
        %   Input Argument:
        %     name - Name of the table
        %   Output Argument:
        %     res - structure containing the table definition
        %
            res=cType.EMPTY;
            if nargin<2 || ~ischar(name)
                return
            end
            idx=obj.tDictionary.getIndex(name);
            if idx
                res=obj.tDictionary.getValues(idx);
            end 
        end

        function res=getTableId(obj,name)
        %getTableId - Get tableId from dictionary. Internal use
        %   Syntax:
        %     res = obj.getTableId(name)
        %   Input Argument:
        %     name - Table name
        %   Output Argument:
        %     res - Internal table id
        %
            res=cType.EMPTY;
            if nargin<2 || ~ischar(name)
                return
            end
            res=getIndex(obj.tDictionary,name);
        end

        function res=getResultIdTables(obj,id)
        %getResultIdTables - Get the tables of an specific resultId
        %   Syntax:
        %     res = obj.getResultIdTables(id)
        %   Input Argument:
        %     id - ResultId
        %   Output Argument
        %     res - cell array with the ResultId tables
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
        %getDataModelProperties - Get the data model properties
        %   Syntax:
        %     res = obj.getDataModelProperties()
        %     res = obj.getDataModelProperties(idx)
        %   Input Argument:
        %     idx - Table index. Optional
        %   Output Argument:
        %     res - struct with the table(s) properties
        %           If idx is not provided, get and array structure with all tables
            if nargin==2
                res=obj.cfgDataModel(idx);
            else
                res=obj.cfgDataModel;
            end
        end

        function res=getMatrixTables(obj,idx)
        %getMatrixTables - Get the matrix tables configuration
        %   Syntax:
        %     res = obj.getMatrixTables(idx);
        %   Input Argument:
        %     idx - Table index. Optional
        %   Output Argument
        %     res - structed array with the configuration
        %
            if nargin==2
                res=obj.cfgMatrices(idx);
            else
                res=obj.cfgMatrices;
            end
        end

        function res=getCellTables(obj,idx)
        %getMatrixTables - Get the matrix tables configuration
        %   Syntax:
        %     res = obj.getCellTables(idx);
        %   Input Argument:
        %     idx - Table index. Optional
        %   Output Argument;
        %     res - structed array with the tables configuration
        %
            if nargin==2
                res=obj.cfgTables(idx);
            else
                res=obj.cfgTables;
            end
        end

        function res=getSummaryTables(obj,option,rsc)
        %getSummaryTables - Get the summary tables configuration
        %   Syntax: 
        %     res=obj.getSummaryTables(option,rsc)
        %   Input Arguments:
        %     option - type of summary tables
        %     rsc    - Resource tables (true/false)
        %   Output Arguments:
        %     res - struct array with the tables configuration
        %   
            % Get optional arguments
            res=cType.EMPTY_CELL;
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
        %buildTablesDictionary - build the tables dictionary
        %   Tables dictionary is stored in obj.tDictionary
        %   Syntax:
        %     obj.buildTablesDictionary
        %
            % Create the index dataset
            tCodes=fieldnames(cType.Tables);
            tNames=struct2cell(cType.Tables);
            td=cDataset(tNames);
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
                td.setValues(idx,val);
                cIndex{idx}=struct('name',val.key,...
                            'description',val.description,...
                            'code',tCodes{idx},...
                            'resultId',val.resultId,...
                            'graph',val.graph,...
                            'type',cType.TableType.TABLE,...
                            'tableId',i);
            end
            % Retrive information for matrix tables
            for i=1:NM
                val=obj.cfgMatrices(i);
                idx=td.getIndex(val.key);
                if ~idx
                    obj.messageLog(cType.ERROR,cMessages.TableNotAvailable,key);
                    continue
                end
                td.setValues(idx,val);
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
                td.setValues(idx,val);
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
        %buildTablesDirectory - Store the tables index data info in a cell array
        %   Tables index data info is stored in obj.tDirectory
        %   This info is used to build the Tables Directory cTable
        %   
        %   Syntax:
        %     res = obj.buildTablesDirectory(col)
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