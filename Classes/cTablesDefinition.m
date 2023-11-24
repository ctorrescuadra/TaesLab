classdef cTablesDefinition < cStatusLogger
    properties(GetAccess=public,SetAccess=private)
        TablesDefinition  % Tables properties
        TablesDirectory   % Tables directory
    end
    properties (Access=protected)
        cfgTables 	 % Cell tables configuration
        cfgMatrices  % Matrix tables configuration
        cfgSummary   % Summary tables configuration
        cfgTypes     % Format types configuration
        tDict        % Tables dictionnary
        tableIndex   % Tables index
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
            obj.TablesDirectory=[];
        end

        function res=get.TablesDefinition(obj)
        % Get a struct with the tables properties
            res=struct('CellTables',obj.cfgTables,'MatrixTables',obj.cfgMatrices,...
                'SummaryTables',obj.cfgSummary);
        end

        function res=getTableProperties(obj,name)
        % Get the properties of a table
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
            if nargin==1
                varmode=cType.VarMode.NONE;
            end
            if isempty(obj.TablesDirectory)
                obj.buildTablesDirectory;
            end
            tbl=obj.TablesDirectory;
            switch varmode
            case cType.VarMode.NONE
                res=tbl;
            case cType.VarMode.CELL
                res=tbl.Values;
            case cType.VarMode.STRUCT
                res=getStructData(tbl);
            case cType.VarMode.TABLE
                if isMatlab
                    res=getMatlabTable(tbl);
                else
                    res=tbl;
                end
            otherwise
                res=tbl;
            end
        end

        function printTable(obj,fid)
        % Print the tables directory
            if nargin==1
                fid=1;
            end
            if isempty(obj.TablesDirectory)
                obj.buildTablesDirectory;
            end
            tbl=obj.TablesDirectory;
            wcol=getColumnWidth(tbl);
            lfmt=arrayfun(@(x) ['%-',num2str(x),'s'],wcol,'UniformOutput',false);
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,tbl.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            for i=1:tbl.NrOfRows
                fprintf(fid,lformat,tbl.RowNames{i},tbl.Data{i,:});
            end
            fprintf(fid,'\n');
        end

        function viewTable(obj)
        % View the Tables Directory as GUI
            % Get the Tables Directory
            if isempty(obj.TablesDirectory)
                obj.buildTablesDirectory;
            end
            tbl=obj.TablesDirectory;
            % Define the uitable parameters
            if isOctave
				param=struct('xScale',8,'xOffset',-8,...
                    'RowWidth',23,'yScale',0.8,'yOffset',-10,...
					'FontName','Consolas','FontSize',10);
			else
				param=struct('xScale',8,'xOffset',-8,...
                    'RowWidth',23,'yScale',0.8,'yOffset',0,...
				    'FontName','FixedWidth','FontSize',12);
            end
            wcols=param.xScale*getColumnWidth(tbl);
            ColumnWidth=num2cell(wcols(2:end));
            ss=get(groot,'ScreenSize');
            xsize=sum(wcols)+param.xOffset;
			ysize=min(0.8*ss(4),(tbl.NrOfRows+1)*param.RowWidth)+param.yOffset;	
			xpos=(ss(3)-xsize)/2;
			ypos=(ss(4)-ysize)/2;
            % Show the table
            h=uifigure('menubar','none','toolbar','none','name',tbl.Description,...
				'numbertitle','off',...
				'position',[xpos,ypos,xsize,ysize]);
   			uitable (h, 'Data', tbl.Data,...
				'RowName', tbl.RowNames, 'ColumnName', tbl.ColNames(2:end),...
				'ColumnWidth',ColumnWidth,...
				'ColumnFormat',tbl.getColumnFormat,...
				'FontName',param.FontName,'FontSize',param.FontSize,...
				'Units', 'normalized','Position',[0,0,1,1]);
        end
    end

    methods(Access=protected)
        function res=getCellTableProperties(obj,name)
        % Get the properties of a cell table
        %   Input:
        %     name - table key name 
            res=[];
            idx=getIndex(obj.tDict,name);
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
            idx=getIndex(obj.tDict,name);
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
            idx=getIndex(obj.tDict,name);
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
            NT=numel(obj.cfgTables);
            NM=numel(obj.cfgMatrices);
            NS=numel(obj.cfgSummary);
            N=NT+NM+NS;
            tIndex(N)=struct('name','','code','','resultId',0,'graph',0,'type',0,'tableId',0);
            % Retrieve information for cell tables
            for i=1:NT
                key=obj.cfgTables(i).key;
                idx=td.getIndex(key);
                tIndex(idx).name=key;
                tIndex(idx).code=tCodes(idx);
                tIndex(idx).resultId=obj.cfgTables(i).resultId;
                tIndex(idx).graph=cType.GraphType.NONE;
                tIndex(idx).type=cType.TableType.TABLE;
                tIndex(idx).tableId=i;
            end
            % Retrive information for matrix tables
            for i=1:NM
                key=obj.cfgMatrices(i).key;
                idx=td.getIndex(key);
                tIndex(idx).name=key;
                tIndex(idx).code=tCodes(idx);
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
                tIndex(idx).code=tCodes(idx);
                tIndex(idx).resultId=cType.ResultId.SUMMARY_RESULTS;
                tIndex(idx).graph=obj.cfgSummary(i).graph;
                tIndex(idx).type=cType.TableType.SUMMARY;
                tIndex(idx).tableId=i;
            end
            % Create the dictionary (name,id)
            obj.tDict=td;
            obj.tableIndex=tIndex;
        end
 
        function buildTablesDirectory(obj)
        % Get the tables directory as cTableData
            tI=obj.tableIndex;
            N=numel(tI);
            colNames={'Table','Key','Results','Type','Graph'};
            rowNames={tI.name};
            %keys=[fieldnames(cType.Tables);fieldnames(cType.SummaryTables)];
            data=cell(N,4);
            data(:,1)=[tI.code];
            data(:,2)=[cType.Results([tI.resultId])];
            data(:,3)=[cType.TypeTables([tI.type])];
            data(:,4)=arrayfun(@(x) log2str(x), [tI.graph],'UniformOutput',false);
            tbl=cTableData(data,rowNames,colNames);
            tbl.setDescription(cType.TableDataIndex.DIRECTORY);
            obj.TablesDirectory=tbl;
        end
	end
end