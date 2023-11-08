classdef cTablesDefinition < cStatusLogger
    properties(GetAccess=public,SetAccess=private)
        TablesDefinition
    end
    properties (Access=protected)
        cfgTables 	 % Tables configuration
        cfgMatrices  % Matrices configuration
        cfgSummary   % Summary configuration
        cfgTypes    % Format types configuration
        tDict        % Tables dictionnary
        tableIndex   % Index for tables properties
    end

    methods
        function obj=cTablesDefinition()
            obj=obj@cStatusLogger(cType.VALID);          
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
            obj.cfgTables=config.tables;
            obj.cfgMatrices=config.matrices;
            obj.cfgSummary=config.summary;
            obj.cfgTypes=config.format;
            obj.buildTablesDictionary;
        end

        function res=get.TablesDefinition(obj)
            res=struct('CellTables',obj.cfgTables,'MatrixTables',obj.cfgMatrices,...
                'SummaryTables',obj.cfgSummary);
        end

        function res=getCellTableProperties(obj,name)
            res=[];
            idx=getIndex(obj.tDict,name);
            if cType.isEmpty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgTables(tId);
        end

        function res=getMatrixTableProperties(obj,name)
            res=[];
            idx=getIndex(obj.tDict,name);
            if cType.isEmpty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgMatrices(tId);
        end

        function res=getSummaryTableProperties(obj,name)
            res=[];
            idx=getIndex(obj.tDict,name);
            if cType.isEmpty(idx)
                return
            end
            tId=obj.tableIndex(idx).tableId;
            res=obj.cfgSummary(tId);
        end

        function res=getTableProperties(obj,name)
        % Get the format table properties
            res=[];
            idx=getIndex(obj.tDict,name);
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

        function res=getTablesDirectory(obj,varmode)
        % Get the tables directory in diferent format
            if nargin==1
                varmode=cType.DEFAULT_VARMODE;
            end
            % Get tables directory as cTableData
            tI=obj.tableIndex;
            N=numel(tI);
            colNames={'Key','Description','ResultId','Type','Graph'};
            resId=[tI.resultId];
            [sId,idx]=sort(resId);
            rowNames={tI(idx).name};
            data=cell(N,4);
            data(:,1)={tI(idx).description};
            data(:,2)=[cType.Results(sId)];
            data(:,3)=[cType.TypeTables([tI(idx).type])];
            data(:,4)=arrayfun(@(x) log2str(x), [tI(idx).graph],'UniformOutput',false);
            tbl=cTableData(data,rowNames,colNames);
            tbl.setDescription(cType.TableDataIndex.DIRECTORY)
            % Convert to diferent formats
            switch varmode
                case cType.VarMode.CELL
                    res=tbl.Values;
                case cType.VarMode.STRUCT
                    entries=[tbl.RowNames',tbl.Data];
                    res=cell2struct(entries,colNames,2);
                case cType.VarMode.TABLE
                    if isMatlab
                        res=tbl.getMatlabTable;
                    else
                        res=tbl;
                    end
                otherwise
                    res=tbl;
            end
        end

        function printTablesDirectory(obj)
        % Print the tables directory
            res=getTablesDirectory(obj);
            lfmt='%-12s %-48s %-27s %-8s %-5s\n';
            header=sprintf(lfmt,res.ColNames{:});
            lines=repmat('—',1,length(header)+1);
            fprintf('\n')
            fprintf('%s',header);
            fprintf('%s\n',lines);
            for i=2:size(res,1)
                fprintf(lfmt,res.Values{i,:});
            end
            fprintf('\n');
        end
    end

    methods(Access=private)
		function buildTablesDictionary(obj)
        % Build the table dictionary
            id=0;
            NT=numel(obj.cfgTables);
            NM=numel(obj.cfgMatrices);
            NS=numel(obj.cfgSummary);
            N=NT+NM+NS;
            tIndex(N)=struct('id',N,'name','pI','description','Process Irreversibility','resultId',0,'graph',0,'type',0,'tableId',0);
            % Retrieve information for cell tables
            for i=1:NT
                id=id+1;
                tIndex(id).name=obj.cfgTables(i).key;
                tIndex(id).description=obj.cfgTables(i).description;
                tIndex(id).resultId=obj.cfgTables(i).resultId;
                tIndex(id).graph=cType.GraphType.NONE;
                tIndex(id).type=cType.TableType.TABLE;
                tIndex(id).tableId=i;
            end
            % Retrive information for matrix tables
            for i=1:NM
                id=id+1;
                tIndex(id).name=obj.cfgMatrices(i).key;
                tIndex(id).description=obj.cfgMatrices(i).header;
                tIndex(id).resultId=obj.cfgMatrices(i).resultId;
                tIndex(id).graph=obj.cfgMatrices(i).graph;
                tIndex(id).type=cType.TableType.MATRIX;
                tIndex(id).tableId=i;
            end
            % Retrieve information for summary tables
            for i=1:NS
                id=id+1;
                tIndex(id).name=obj.cfgSummary(i).key;
                tIndex(id).description=obj.cfgSummary(i).header;
                tIndex(id).resultId=cType.ResultId.SUMMARY_RESULTS;
                tIndex(id).graph=obj.cfgSummary(i).graph;
                tIndex(id).type=cType.TableType.SUMMARY;
                tIndex(id).tableId=i;
            end
            % Create the dictionary (name,id)
            obj.tDict=cDictionary({tIndex.name});
            obj.tableIndex=tIndex;
        end
	end
end