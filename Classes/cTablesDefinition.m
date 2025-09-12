classdef cTablesDefinition < cMessageLogger
%cTablesDefinition - Read and store the tables format configuration file. 
%   This class is use for two purposes:
%   - This class is defined as base class of cFormatData reading the printformat.json
%   - Provide information of the result tables of the application (TablesDirectory)
%
%   cTableDefinition Constructor
%     obj = cTablesDefinition

%   cTablesDefinition Methods:
%     getTableProperties  - Get the properties of a table
%     getTablesDirectory  - Get the a cTableData with the tables index
%     showTablesDirectory - Show the Table Directory
%     saveTablesDirectory - Save the Table Directory into a file
%     getTableId          - Get the TableId of a table
%     getResultIdTables   - Get the Tables of a ResultId
%     getSummaryTables    - Get the Summary Tables Info
%
%   See also cFormatData, printconfig.json
%
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
            obj.cfgTables=config.tables;
            obj.cfgMatrices=config.matrices;
            obj.cfgSummary=config.summary;
            obj.cfgTypes=config.format;
            obj.buildTablesDictionary;
            if obj.status
                obj.buildTablesDirectory;
            end
        end

        function res=getTableDefinition(obj,name)
        %getTableDefinition - Get the properties of a table
        %   Syntax:
        %     res = obj.getTableProperties(name)
        %   Input Argument:
        %     name - Name of the table
        %   Output Argument:
        %     res - structure containing the table definition
        %
            res=obj.tDictionary.getValues(name);   
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
            [idx,missing]=cType.checkDirColumns(cols);
            if isempty(idx)
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
        end

        function saveTablesDirectory(obj,filename)
        %saveTablesDirectory - Save the full tables directory in different file formats depending on file extension
        %   Valid extension are: *.json, *.xml, *.csx, *.xlsx, *.txt, *.html, *.tex
        %   Syntax:
        %     log=obj.saveTablesDirectory(filename)
        %   Input Argument:
        %     filename - File name with extension
        %   Output Arguments:
        %     log - cMessageLogger object with error messages
            fullcols=fieldnames(cType.DirCols);
            tbl=obj.getTablesDirectory(fullcols);
            log=saveTable(tbl,filename);
            log.printLogger;
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
            rid=[obj.tableIndex.resultId];
            idx=find(rid==id);
            res={obj.tableIndex(idx).name};
        end

        function res=getSummaryTables(obj,option,rsc)
        %getSummaryTables - Get Summary Tables properties
        %   Syntax: 
        %     res=obj.getSummaryTables(option,rsc)
        %   Input Arguments:
        %     option - type of summary tables
        %     rsc    - Resource tables (true/false)
        %   Output Arguments:
        %     res - struct array with the tables properties
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
            stbl=[obj.cfgSummary.stable];
            drt=~[obj.cfgSummary.rsc];
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
            obj.tDictionary=td;
            obj.tableIndex=cell2mat(cIndex);
        end
 
        function buildTablesDirectory(obj)
        %buildTablesDirectory - Store the tables index data info in a cell array
        %   Tables index data info is stored in obj.tDirectory
        %   This info is used to build the Tables Directory
        %   
        %   Syntax:
        %     res = obj.buildTablesDirectory(col)
        %   
            N=numel(obj.tableIndex);
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