classdef cFormatData < cTablesDefinition
% cFormatData gets the format configuration data used to display tables of results.
%	This class implements cResultTableBuilder
% 	Methods:
%		res=obj.getFormat(id)
%		res=obj.getUnit(id)
%		res=obj.getTableHeader(id)
%		res=obj.getTableFormat(id)
%		res=obj.getTableUnits(id)
% See also printformat.json, cTablesDefinition
%	
	methods
		function obj=cFormatData(format)
		% Class Constructor
		%	format - format configuration data
			obj=obj@cTablesDefinition;          
            if ~isstruct(format) || isscalar(format)
				obj.messageLog(cType.ERROR,'Invalid format data provided');
				return
            end
            if ~all(isfield(format,{'key','width','precision','unit'}))
                obj.messageLog(cType.ERROR,'Invalid data. Fields missing');
                return
            end
            % Check and save each format definition
            for i=1:numel(format)
                fmt=format(i);
			    id=cType.getFormatId(fmt.key);
                if cType.isEmpty(id)
			        obj.messageLog(cType.WARNING,'Invalid Format Key %s',fmt.key);
                    continue
                end
                val1=isfloat(fmt.width) && isfloat(fmt.precision);
                val2=(fmt.width>1) && (fmt.precision>0) && (fmt.width > fmt.precision );
                if val1 && val2
                    cfmt=strcat('%',num2str(fmt.width),'.',num2str(fmt.precision),'f');
                    obj.cfgTypes(id).unit=fmt.unit;
                    obj.cfgTypes(id).format=cfmt;
                else
                    obj.messageLog(cType.WARNING,'Bad format defined in %s',fmt.key);
                end
            end
		end

		function res=getTableInfo(obj,name)
		% get the resultId of a table from tables dictionary
			res=[];
			idx=getIndex(obj.tDictionary,name);
			if cType.isEmpty(idx)
				return
			end
			res=obj.tableIndex(idx);
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