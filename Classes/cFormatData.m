classdef cFormatData < cTablesDefinition
%cFormatData - Get the format configuration data used to display tables of results.
%   This class loads the format configuration data from a struct, which
%   should be obtained from a JSON file printconfig.json.
%   The format configuration data contains the format definition of each type
%   of variable, and the definition of each table used in TaesLab.
%	cResultTableBuilder derives from this class.
% 	
%   cFormatData methods:
%	  cFormatData        - Create an instance of the class
%     getFormat          - Get the format of a variable type
%     getUnit            - Get the units of a variable type
%     getResultId        - Get the ResultId of a table
%     getTableProperties - Get the properties of a cTable
%
%   cFormatData methods (inherited from cTablesDefinition):
%     getTablesDirectory - Get the a cTableData with the tables index
%     getTableDefinition - Get configurarion properties of a table
%     getTableInfo       - Get table info as a struct
%     getTableId         - Get the TableId of a table
%     getResultIdTables  - Get the tables configuration of a ResultId
%     getCellTables      - Get the Cell tables configuration
%     getMatrixTables    - Get the Matrix tables configuration     
%     getSummaryTables   - Get the Summary tables configuration
%
%   See also printformat.json, cTablesDefinition, cResultTableBuilder
%	
	methods
		function obj=cFormatData(data)
		%cFormatData - Create an instance of the class
		%   Syntax:
		%     obj = cFormatData(data)
		%   Input Arguments:
		%	  data - Format struct from cModelData
		%   Output Arguments:
		%     obj - cFormatData object
		%
			% Check input
			if ~isstruct(data) || ~isfield(data,'definitions') 
				obj.messageLog(cType.ERROR,cMessages.InvalidFormatDefinition);
				return
			end		
            format=data.definitions;
            if ~all(isfield(format,{'key','width','precision','unit'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidFormatDefinition);
                return
            end
            % Check and save each format definition
            for i=1:numel(format)
                fmt=format(i);
			    id=cType.getFormatId(fmt.key);
                if isempty(id)
			        obj.messageLog(cType.ERROR,cMessages.InvalidFormatKey,fmt.key);
                    continue
                end
                if (fmt.width>1) && (fmt.precision>0) && (fmt.width > fmt.precision )
                    cfmt=strcat('%',num2str(fmt.width),'.',num2str(fmt.precision),'f');
                    obj.cfgTypes(id).unit=fmt.unit;
                    obj.cfgTypes(id).format=cfmt;
                else
                    obj.messageLog(cType.ERROR,cMessages.BadFormatDefinition,fmt.key);
                end
            end
        end

		function res=getFormat(obj,id)
		%getFormat - Get the format of a type of variable
		%   Syntax:
		%     format = obj.getFormat(id)
		%   Input Arguments:
		%     id - Variable type, see cType.Format
		%   Output Arguments:
		%     res - char array with the C-like format of the variable
		%
			res=obj.cfgTypes(id).format;
		end
				
		function res=getUnit(obj,id)
		%getUnit - Get the format of a type of variable
		% 	Syntax:
		%     format = obj.getUnit(id)
		% 	Input Arguments:
		%     id - Variable type, see cType.Format
		% 	Output Arguments:
		%     res - char array with unit of the variable
		%
			res=obj.cfgTypes(id).unit;
		end

		function res=getResultId(obj,table)
		%getResultId - Get the ResultId of a table
		%   Syntax:
		%     res = obj.getResultId(table)
		%   Input Arguments:
		%     table - Name of the table (char)
		%   Output Arguments:
		%     res - ResultId of the table (scalar numeric)
		%
			res=0;
			if nargin<2 || ~ischar(table),return;end
			tmp=obj.getTableDefinition(table);
			if ~isempty(tmp)
				res=tmp.resultId;
			end
		end
		
		function [tdef,tprop]=getTableProperties(obj,name)
		%getTableProperties - Get the properties of a cTable
		%   Syntax:
		%     [tdef,tprop] = obj.getTableProperties(name)
		%   Input Arguments:
		%     name - name of the table
		%   Output Arguments:
		%     tdef  - definition struct of the table
		%     tprop - properties on the cTable
		%
			tprop=cType.EMPTY;
			% Get table definition
			tdef=getTableDefinition(obj,name);
			if nargout<2
				return
			end
			% Get table properties if required
        	switch tdef.ttable
            	case cType.TableType.TABLE
                	tprop=obj.getCellTableProperties(tdef);
            	case cType.TableType.MATRIX
                	tprop=obj.getMatrixTableProperties(tdef);
            	case cType.TableType.SUMMARY
                	tprop=obj.getSummaryTableProperties(tdef);
        	end
		end
    end

    methods(Access=protected)						
		function res=getTableHeader(obj,tdef)
		%getTableHeader - get the table header cell array
		%   Input Arguments:
		%     tdef - Table properties
		%   Output Arguments:
		%     res - cell array with the table header of each column
		%
			units=obj.getTableUnits(tdef);
			header={tdef.fields.header};
			res=cellfun(@strcat,header,units,'UniformOutput',false);
		end
			
		function format=getTableFormat(obj,tdef)
		%getTableFormat - get an array cell with the format (C-like) of columns table
		%   Input Arguments:
		%     tdef - Table definition struct
		%   Output Arguments:
		%     format - cell array with the format of the column table
		%
			idx=[tdef.fields.type];
			format={obj.cfgTypes(idx).format};
        end
	
		function units=getTableUnits(obj,tdef)
		%getTableUnits - get a cell array with the units for each table column
		%   Input Arguments:
		%     tdef - Table definition struct
		%   Output Arguments:
		%     res - cell array with the units of each column
		%
			idx=[tdef.fields.type];
			units={obj.cfgTypes(idx).unit};
        end

        function tp=getCellTableProperties(obj,td)
		%getCellTableProperties - Get the cTableCell properties from table definition
		%   Input Arguments:
		%     td - table definition strcuture
		%   Output Arguments:
		%     tp - struct witc cTableCell properties
		% 
			tp=struct('Name',td.key,...
				      'Description',td.description,...
					  'DataType',[],... 
                      'Unit',[],...
            		  'Format',[],...
            	      'FieldNames',[],...
            		  'ShowNumber',td.number,...
            		  'GraphType',td.graph,...
                      'NodeType',td.node,...
            		  'Resources',td.rsc);
			% set cell array properties.
			tp.DataType=[td.fields.type];
			tp.Unit=obj.getTableUnits(td);
			tp.Format=obj.getTableFormat(td);
			tp.FieldNames={td.fields.name};
        end

        function tp=getMatrixTableProperties(obj,td)
		%getMatrixTableProperties - Get the cTableMatrix properties from table definition
		%   Input Arguments:
		%     td - table definition strcuture
		%   Output Arguments:
		%     tp - struct witc cTableMatrix properties
		% 
			tp=struct('Name',td.key,...
				      'Description',td.header,...  
                      'Unit',obj.getUnit(td.type),...
            		  'Format',obj.getFormat(td.type),...
            		  'GraphType',td.graph,...
					  'GraphOptions',td.options,...
            		  'Resources',td.rsc,...
   					  'SummaryType',cType.SummaryId.NONE,...
					  'NodeType',td.node,...
                      'RowTotal',td.rowTotal,...
                      'ColTotal',td.colTotal);
        end

        function tp=getSummaryTableProperties(obj,td)
		%getSummaryTableProperties - Get the cTableMatrix properties from summary table definition
		%   Input Arguments:
		%     td - table definition structure
		%   Output Arguments:
		%     tp - struct with cTableMatrix properties for summary table
		% 
			tp=struct('Name',td.key,...
				      'Description',td.header,...  
                      'Unit',obj.getUnit(td.type),...
            		  'Format',obj.getFormat(td.type),...
            		  'GraphType',td.graph,...
					  'GraphOptions',td.options,...
            		  'Resources',td.rsc,...
   					  'SummaryType',td.stable,...
					  'NodeType',td.node,...
                      'RowTotal',false,...
                      'ColTotal',false);
        end
	end
end