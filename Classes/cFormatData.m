classdef cFormatData < cStatusLogger
% cFormatData gets the format configuration data used to display tables of results.
%	This class implements cResultTableBuilder
% 	Methods:
%		res=obj.getFormat(id)
%		res=obj.getUnit(id)
%		res=obj.getTableDescription(id)
%   	res=obj.getMatrixDescription(id)
%		res=obj.getTableHeader(id)
%		res=obj.getNumColumns(id)
%		res=obj.getFieldNames(id)
%		res=obj.getTableFormat(id)
%		res=obj.getMatrixFormat(id)
%		res=obj.getTableUnits(id)
%		res=obj.getMatrixUnit(id)
%		res=obj.getMatrixName(id)
%		[row,col]=obj.getMatrixTotal(id)
%   	res=obj.PrintConfig;
% See also printformat.json, cResultsTableBuilder
%
	properties(GetAccess=public,SetAccess=private)
		PrintConfig
    end

	properties (Access=private)
		cfgTables 	 % Tables configuration
		cfgMatrices  % Matrices configuration
		cfgSummary   % Summary configuration
		cfgTypes     % Format types configuration
		tDict        % Tables dictionnary
		tableIndex   % Index for tables properties
	end
	
	methods
		function obj=cFormatData(data)
		% Class Constructor
		%	data - format configuration data
			obj=obj@cStatusLogger(cType.VALID);          
            if ~isstruct(data)
				obj.messageLog(cType.ERROR,'Invalid format data provided');
				return
            end
			% load default configuration filename			
			path=fileparts(mfilename('fullpath'));
			cfgfile=fullfile(path,cType.CFGFILE);
			try		
				config=jsondecode(fileread(cfgfile));
			catch err
				obj.messageLog(cType.ERROR,err.message);
				obj.messageLog(cType.ERROR,'Invalid %s config file',cfgfile);
			end
            if isfield(data,'format') % Check format data	
                if ~all(isfield(data.format,{'key','width','precision','unit'}))
                    obj.messageLog(cType.ERROR,'Invalid format data.');
                end
                % Check and save each format definition
                for i=1:numel(data.format)
                    fmt=data.format(i);
					id=cType.getFormatId(fmt.key);
                    if cType.isEmpty(id)
						obj.messageLog(cType.ERROR,'Invalid Format Key %s',fmt.key);
                        continue
                    end
                    val1=isfloat(fmt.width) && isfloat(fmt.precision);
                    val2=(fmt.width>1) && (fmt.precision>0) && (fmt.width > fmt.precision );
                    if val1 && val2
                        cfmt=strcat('%',num2str(fmt.width),'.',num2str(fmt.precision),'f');
                        config.format(id).unit=fmt.unit;
                        config.format(id).format=cfmt;
                    else
                        obj.messageLog(cType.ERROR,'Bad format defined in %s',fmt.key);
                    end
                end
            else  % No data provided. Default configuration is taken
                obj.messageLog(cType.Error,'Invalid Format');
            end
			if isValid(obj)
		    	obj.cfgTables=config.tables;
				obj.cfgMatrices=config.matrices;
				obj.cfgSummary=config.summary;
				obj.cfgTypes=config.format;
			end
			obj.buildTablesDictionary;
		end

		function res=get.PrintConfig(obj)
		% show print configuration
			res=struct('Tables',obj.cfgTables,'Matrices',obj.cfgMatrices,'Summary',obj.cfgSummary,'Format',obj.cfgTypes);
        end

		function res=getTableInfo(obj,table)
		% get the dictionary information of a table
			res=[];
			idx=getIndex(obj.tDict,table);
			if cType.isEmpty(idx)
				return
			end
			res=obj.tableIndex(idx);
		end

		function res=getTableProperties(obj,table)
		% get the format table properties
			res=[];
			idx=getIndex(obj.tDict,table);
			if cType.isEmpty(idx)
				return
			end
			tIndex=obj.tableIndex(idx);
			switch tIndex.type
			case cType.TableType.TABLE
				res=obj.cfgTables(tIndex.tableId);
			case cType.TableType.MATRIX
				res=obj.cfgMatrices(tIndex.tableId);
			case cType.TableType.MATRIX
				res=obj.cfgSummary(tIndex.tableId);
			end
		end
    end

    methods(Access=protected)			
		function format=getFormat(obj,id)
		% get the format of a type of variable
		%  Input:
		%   id - Variable type
			format=obj.cfgTypes(id).format;
		end
			
		function unit=getUnit(obj,id)
		% get the variable unit of a type
		%  Input:
		%   id - Variable type
			unit=obj.cfgTypes(id).unit;
		end

		function res=getTableKey(obj,id)
		% get the key of a TableCell
		%  Input:
		%   id - Table id
			res=obj.cfgTables(id).key;
		end

		function res=getMatrixKey(obj,id)
		% get the key of a TableMatrix
		%  Input:
		%   id - Table id
			res=obj.cfgMatrices(id).key;
		end

		function res=getSummaryKey(obj,id)
		% get the the key of a TableSummary
		%  Input:
		%   id - Table id
			res=obj.cfgSummary(id).key;
		end
		
		function res=showNumber(obj,id)
		% Indicate if the id number is printing
		%  Input:
		%   id - Table id
			res=obj.cfgTables(id).number;
		end

		function res=getTableDescription(obj,id)
		% get the table desciption
		%  Input:
		%   id - Table id
			res=obj.cfgTables(id).description;
		end
			
		function res=getMatrixDescription(obj,id)
		% get the matrix desciption
		%  Input:
		%   id - Matrix id            
			res=obj.cfgMatrices(id).header;	
		end

		function res=getSummaryDescription(obj,id)
		% get the matrix desciption
		%  Input:
		%   id - Matrix id            
			res=obj.cfgSummary(id).header;	
		end
			
		function res=getTableHeader(obj,id)
		% get the table header cell array
		%  Input:
		%   id - Table id
			units=obj.getTableUnits(id);
			header={obj.cfgTables(id).fields.header};
			res=cellfun(@strcat,header,units,'UniformOutput',false);
		end
			
		function res=getNumColumns(obj,id)
		% get number of columns of the table
			res=obj.cfgTables(id).columns;
		end
			
		function res=getFieldNames(obj,id)
		% get field names of the table
		%  Input:
		%   id - Table id  
			res={obj.cfgTables(id).fields.name};
		end
			
		function format=getTableFormat(obj,id)
		% get an array cell with the format (C-like) of columns table
		%  Input:
		%   id - Table id
			idx=[obj.cfgTables(id).fields.type];
			format={obj.cfgTypes(idx).format};
        end

        function format=getMatrixFormat(obj,id)
		% get the format (C-like) of the elements of the matrix
		%  Input:
		%   id - Matrix id
			format=obj.getFormat(obj.cfgMatrices(id).type);
		end
			
		function format=getSummaryFormat(obj,id)
		% get the format (C-like) of the elements of the matrix
		%  Input:
		%   id - Matrix id
			format=obj.getFormat(obj.cfgSummary(id).type);
		end
	
		function units=getTableUnits(obj,id)
		% get a cell array with the units for each table column
		%   Input:
		%    id - Table id
			idx=[obj.cfgTables(id).fields.type];
			units={obj.cfgTypes(idx).unit};
		end
	
		function unit=getMatrixUnit(obj,id)
		% get the unit of the elements matrix
		%  Input:
		%   id - Matrix id
			unit=obj.getUnit(obj.cfgMatrices(id).type);
		end

		function unit=getSummaryUnit(obj,id)
		% get the unit of the elements matrix
		%  Input:
		%   id - Matrix id
			unit=obj.getUnit(obj.cfgSummary(id).type);
		end
				
		function name=getMatrixName(obj,id)
		% get the matrix name
		%  Input:
		%   id - Matrix id
			name=obj.cfgMatrices(id).name;
		end

		function name=getSummaryName(obj,id)
		% get the matrix name
		%  Input:
		%   id - Matrix id
			name=obj.cfgSummary(id).name;
		end

		function val=getMatrixGraphType(obj,id)
		% get the type of graph for matrix tables
		%  Input:
		%   id - Matrix id
			val=obj.cfgMatrices(id).graph;
		end

		function val=getMatrixGraphOptions(obj,id)
		% get the type of graph for matrix tables
		%  Input:
		%   id - Matrix id
			val=obj.cfgMatrices(id).options;
		end

		function val=getSummaryGraphOptions(obj,id)
		% get the type of graph for matrix tables
		%  Input:
		%   id - Matrix id
			val=obj.cfgSummary(id).options;
		end

		function [row,col]=getMatrixTotal(obj,id)
		% get rowTotal and colTotal check info
		%  Input:
		%   id - Matrix id
			row=obj.cfgMatrices(id).rowTotal;
			col=obj.cfgMatrices(id).colTotal;
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
			tIndex(N)=struct('id',N,'name','pI','resultId',0,'graph',0,'type',0,'tableId',0);
			% Retrieve information for simple tables
			for i=1:NT
				id=id+1;
				tIndex(id).id=id;
				tIndex(id).name=obj.cfgTables(i).key;
				tIndex(id).resultId=obj.cfgTables(i).resultId;
				tIndex(id).graph=cType.GraphType.NONE;
				tIndex(id).type=cType.TableType.TABLE;
				tIndex(id).tableId=i;
			end
			% Retrive information for matrix tables
			for i=1:NM
				id=id+1;
				tIndex(id).id=id;
				tIndex(id).name=obj.cfgMatrices(i).key;
				tIndex(id).resultId=obj.cfgMatrices(i).resultId;
				tIndex(id).graph=obj.cfgMatrices(i).graph;
				tIndex(id).type=cType.TableType.MATRIX;
				tIndex(id).tableId=i;
			end
			% Retrieve information for summary tables
			for i=1:NS
				id=id+1;
				tIndex(id).id=id;
				tIndex(id).name=obj.cfgSummary(i).key;
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