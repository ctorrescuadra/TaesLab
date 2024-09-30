classdef cFormatData < cTablesDefinition
% cFormatData gets the format configuration data used to display tables of results.
%	cResultTableBuilder derives from this class
% 	
% cFormatData Methods:
%   getTableInfo - Get info about table properties
%   getFormat - Get the format of a data type
%   getUnit - Get the units of a data type
%
% See also printformat.json, cTablesDefinition
%	
	methods
		function obj=cFormatData(data)
		% Create an instance of the object
		% Syntax:
		%   obj = cFormatData(data)
		% Input Argument:
		%	data - Format struct from cModelData
		%
			if ~isstruct(data) || ~isfield(data,'definitions') 
				obj.messageLog(cType.ERROR,'Invalid format data ');
				return
			end
			
            format=data.definitions;
            if ~all(isfield(format,{'key','width','precision','unit'}))
                obj.messageLog(cType.ERROR,'Invalid data. Fields missing');
                return
            end
            % Check and save each format definition
            for i=1:numel(format)
                fmt=format(i);
			    id=cType.getFormatId(fmt.key);
                if isempty(id)
			        obj.messageLog(cType.ERROR,'Invalid Format Key %s',fmt.key);
                    continue
                end
                val1=isfloat(fmt.width) && isfloat(fmt.precision);
                val2=(fmt.width>1) && (fmt.precision>0) && (fmt.width > fmt.precision );
                if val1 && val2
                    cfmt=strcat('%',num2str(fmt.width),'.',num2str(fmt.precision),'f');
                    obj.cfgTypes(id).unit=fmt.unit;
                    obj.cfgTypes(id).format=cfmt;
                else
                    obj.messageLog(cType.ERROR,'Bad format defined in %s',fmt.key);
                end
            end
		end

		function res=getTableInfo(obj,name)
		% Get the properties of a table
		% Syntax:
		%   res = obj.getTableInfo(name)
		% Input Arguments:
		%   name - Name of the table
		% Output Arguments:
		%   res - Struct with the properties of the table
		%
			res=cType.EMPTY;
			idx=obj.getTableId(name);
            if idx
			    res=obj.tableIndex(idx);
            end
		end

		function res=getFormat(obj,id)
		% Get the format of a type of variable
		% Syntax:
		%  format = obj.getFormat(id)
		% Input Argument:
		%   id - Variable type, see cType.Format
		% Output Argument:
		%   res - char array with the C-like format of the variable
			res=obj.cfgTypes(id).format;
		end
				
		function res=getUnit(obj,id)
		% Get the format of a type of variable
		% Syntax:
		%  format = obj.getUnit(id)
		% Input Argument:
		%   id - Variable type, see cType.Format
		% Output Argument:
		%   res - char array with unit of the variable
			res=obj.cfgTypes(id).unit;
		end		
    end

    methods(Access=protected)						
		function res=getTableHeader(obj,props)
		% get the table header cell array
		%  Input:
		%   props - Table properties
			units=obj.getTableUnits(props);
			header={props.fields.header};
			res=cellfun(@strcat,header,units,'UniformOutput',false);
		end
			
		function format=getTableFormat(obj,props)
		% get an array cell with the format (C-like) of columns table
		%  Input:
		%   props - Table properties
			idx=[props.fields.type];
			format={obj.cfgTypes(idx).format};
        end
	
		function units=getTableUnits(obj,props)
		% get a cell array with the units for each table column
		%   Input:
		%    id - Table properties
			idx=[props.fields.type];
			units={obj.cfgTypes(idx).unit};
		end
	end
end