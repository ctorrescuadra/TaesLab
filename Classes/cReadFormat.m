classdef cReadFormat < cStatusLogger
% cReadFormat reads the format configuration data, used to display tables of results.
%	This class implements cResultTableBuilder
%  	If no format is provided, default configuration file printformat.json is used
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
		cfgTables 	% Tables configuration
		cfgMatrices % Matrices configuration
		cfgSummary  % Summary configuration
		cfgTypes    % Format types configuration
	end
	
	methods
		function obj=cReadFormat(data)
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
                    if ( isfloat(fmt.width) && isfloat(fmt.precision) && fmt.width > fmt.precision )
                        id=cType.Format.(fmt.key);
                        cfmt=strcat('%',num2str(fmt.width),'.',num2str(fmt.precision),'f');
                        config.format(id).unit=fmt.unit;
                        config.format(id).format=cfmt;
                    else
                        obj.messageLog(cType.ERROR,'Bad format defined in %s',fmt.key);
                        return
                    end
                end
            else  % No data provided. Default configuration is taken
                obj.messageLog(cType.VALID,'Default format is used');
            end
		    obj.cfgTables=config.tables;
			obj.cfgMatrices=config.matrices;
			obj.cfgSummary=config.summary;
			obj.cfgTypes=config.format;
		end

		function res=get.PrintConfig(obj)
		% show print configuration
			res=struct('Tables',obj.cfgTables,'Matrices',obj.cfgMatrices,'Format',obj.cfgTypes);
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
			types=obj.cfgTypes(idx);
			format={obj.cfgTypes(1).format,types(:).format};
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
end