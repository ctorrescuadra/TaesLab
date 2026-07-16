classdef cFormatData < cTablesDefinition
%cFormatData - Apply model-specific format overrides to the TaesLab table registry.
%   cFormatData extends cTablesDefinition by overriding the default numeric
%   formats and unit labels stored in cfgTypes with the values supplied by
%   the model's Format section (cModelData.Format).
%
%   cTablesDefinition reads the global table definitions from cType.CFGFILE
%   (printformat.json) and populates cfgTypes with toolbox-wide defaults.
%   cFormatData replaces those defaults entry-by-entry using the per-variable
%   definitions from the model file, so that every result table produced for
%   that model uses the correct physical units and numeric precision.
%
%   Each format definition in cModelData.Format.definitions must supply:
%     key       - Variable type key (must match a cType.Format identifier)
%     width     - Total field width (must be > 1)
%     precision - Number of decimal places (must be > 0 and < width)
%     unit      - Physical unit label string
%   A C-like format string  '%<width>.<precision>f'  is constructed and
%   stored in cfgTypes for use by all downstream table-building methods.
%
%   cFormatData Methods:
%     cFormatData        - Construct an instance from a cModelData format struct
%     getFormat          - Return the C-like format string for a variable type
%     getUnit            - Return the unit label for a variable type
%     getResultId        - Return the ResultId associated with a table name
%     getTableProperties - Return the definition and/or properties of a table
%
%   cFormatData Methods (inherited from cTablesDefinition):
%     getTablesDirectory     - Return a cTableData listing all registered tables
%     getTableDefinition     - Return the raw config struct for a named table
%     getTableInfo           - Return a summary-info struct for a named table
%     getTableId             - Return the dictionary index of a table name
%     getResultIdTables      - Return the table names for a given ResultId
%     getDataModelProperties - Return the data-model table configuration(s)
%     getCellTables          - Return cell-table configuration struct(s)
%     getMatrixTables        - Return matrix-table configuration struct(s)
%     getSummaryTables       - Return summary-table configuration struct(s)
%
%   See also cTablesDefinition, cResultTableBuilder, cModelData
%
	methods
		function obj=cFormatData(data)
		%cFormatData - Construct an instance from a cModelData format struct
		%   Calls the cTablesDefinition constructor to load the toolbox-wide
		%   defaults, then iterates over data.definitions to override cfgTypes
		%   with model-specific width, precision and unit values.
		%   Construction sets the object status to false under any of the
		%   following conditions:
		%     - data is not a struct or lacks a 'definitions' field
		%     - any definition is missing the required fields
		%       (key, width, precision, unit)
		%     - any definition has an unrecognised key (not in cType.Format)
		%     - any definition has an invalid width/precision relationship
		%       (width must be > 1, precision must be > 0, width > precision)
		%
		%   Syntax:
		%     obj = cFormatData(data)
		%
		%   Input Arguments:
		%     data - Struct with a 'definitions' field containing an array of
		%            format-definition structs (from cModelData.Format).
		%            Each element must have fields: key, width, precision, unit.
		%
		%   Output Arguments:
		%     obj  - cFormatData object.  Use isValid(obj) to confirm
		%            successful construction before calling other methods.
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
		%getFormat - Return the C-like format string for a variable type
		%   Returns the format string stored in cfgTypes(id).format, which
		%   was built by the constructor as '%<width>.<precision>f' using the
		%   model-specific values.  Example return value: '%8.3f'.
		%
		%   Syntax:
		%     res = obj.getFormat(id)
		%
		%   Input Arguments:
		%     id  - Numeric format-type index (cType.Format value).
		%
		%   Output Arguments:
		%     res - Char string with the C-like format, e.g. '%8.3f'.
		%
			res=obj.cfgTypes(id).format;
		end
				
		function res=getUnit(obj,id)
		%getUnit - Return the physical unit label for a variable type
		%   Returns the unit string stored in cfgTypes(id).unit, which was
		%   set either from the toolbox default (cType.CFGFILE) or overridden
		%   by the model-specific format definition.
		%
		%   Syntax:
		%     res = obj.getUnit(id)
		%
		%   Input Arguments:
		%     id  - Numeric format-type index (cType.Format value).
		%
		%   Output Arguments:
		%     res - Char string with the unit label, e.g. 'kW' or ''.
		%
			res=obj.cfgTypes(id).unit;
		end

		function res=getResultId(obj,table)
		%getResultId - Return the ResultId associated with a table name
		%   Looks up the table in the registry via getTableDefinition and
		%   returns its resultId field.  Returns 0 when table is not a string
		%   or is not registered, providing a safe sentinel the caller can
		%   test without error.
		%
		%   Syntax:
		%     res = obj.getResultId(table)
		%
		%   Input Arguments:
		%     table - Table name string to look up.
		%
		%   Output Arguments:
		%     res   - Positive integer ResultId (cType.ResultId value) if the
		%             table is registered; 0 otherwise.
		%
			res=0;
			if nargin<2 || ~ischar(table),return;end
			tmp=obj.getTableDefinition(table);
			if ~isempty(tmp)
				res=tmp.resultId;
			end
		end
		
		function [tdef,tprop]=getTableProperties(obj,name)
		%getTableProperties - Return the definition and/or properties of a named table
		%   Provides a two-level view of a table's configuration:
		%     tdef  - Raw configuration struct from the JSON config file
		%             (same as getTableDefinition).  Always computed.
		%     tprop - Properties struct ready for passing to the cTable
		%             constructor (cTableCell or cTableMatrix).  Only
		%             computed when two output arguments are requested,
		%             avoiding unnecessary work in single-output calls.
		%   The type of tprop depends on the table category:
		%     TABLE   → getCellTableProperties   → cTableCell properties
		%     MATRIX  → getMatrixTableProperties  → cTableMatrix properties
		%     SUMMARY → getSummaryTableProperties → cTableMatrix properties
		%
		%   Syntax:
		%     tdef          = obj.getTableProperties(name)
		%     [tdef, tprop] = obj.getTableProperties(name)
		%
		%   Input Arguments:
		%     name  - Table name string to look up.
		%
		%   Output Arguments:
		%     tdef  - Raw configuration struct (see getTableDefinition).
		%     tprop - cTable properties struct; only computed when requested.
		%             Returns cType.EMPTY when the table type is unrecognised.
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
		%getTableHeader - Return the column-header cell array for a table definition
		%   Retrieves the unit label for each column via getTableUnits and
		%   concatenates it with the field header string, producing entries
		%   such as 'Exergy [kW]' when a unit is present or just 'Type' when
		%   the unit label is empty.
		%
		%   Syntax:
		%     res = obj.getTableHeader(tdef)
		%
		%   Input Arguments:
		%     tdef - Table definition struct (from getTableDefinition).
		%
		%   Output Arguments:
		%     res  - 1×M cell array of column-header strings.
		%
			units=obj.getTableUnits(tdef);
			header={tdef.fields.header};
			res=cellfun(@strcat,header,units,'UniformOutput',false);
		end
			
		function format=getTableFormat(obj,tdef)
		%getTableFormat - Return the C-like format string for each column of a table
		%   Maps the type index of each field in tdef to the corresponding
		%   format entry in cfgTypes using vectorised indexing.
		%
		%   Syntax:
		%     format = obj.getTableFormat(tdef)
		%
		%   Input Arguments:
		%     tdef   - Table definition struct (from getTableDefinition).
		%
		%   Output Arguments:
		%     format - 1×M cell array of C-like format strings, one per column.
		%
			idx=[tdef.fields.type];
			format={obj.cfgTypes(idx).format};
        end
	
		function units=getTableUnits(obj,tdef)
		%getTableUnits - Return the physical unit label for each column of a table
		%   Maps the type index of each field in tdef to the corresponding
		%   unit entry in cfgTypes using vectorised indexing.
		%
		%   Syntax:
		%     units = obj.getTableUnits(tdef)
		%
		%   Input Arguments:
		%     tdef  - Table definition struct (from getTableDefinition).
		%
		%   Output Arguments:
		%     units - 1×M cell array of unit label strings, one per column.
		%
			idx=[tdef.fields.type];
			units={obj.cfgTypes(idx).unit};
        end

        function tp=getCellTableProperties(obj,td)
		%getCellTableProperties - Build a cTableCell properties struct from a definition
		%   Assembles the tp struct that is passed to the cTableCell constructor
		%   by reading scalar flags from the definition (graph, node, number,
		%   rsc) and deriving array properties (DataType, Unit, Format,
		%   FieldNames) from the fields sub-array via getTableUnits and
		%   getTableFormat.
		%
		%   Syntax:
		%     tp = obj.getCellTableProperties(td)
		%
		%   Input Arguments:
		%     td - Cell-table definition struct (from cfgTables).
		%
		%   Output Arguments:
		%     tp - Struct with fields: Name, Description, DataType, Unit,
		%          Format, FieldNames, ShowNumber, GraphType, NodeType,
		%          Resources.
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
		%getMatrixTableProperties - Build a cTableMatrix properties struct from a definition
		%   Assembles the tp struct that is passed to the cTableMatrix
		%   constructor for square numeric tables (FP tables, cost allocation
		%   matrices).  Unit and Format are scalar values taken from cfgTypes
		%   via td.type, and RowTotal/ColTotal control the totals row/column.
		%
		%   Syntax:
		%     tp = obj.getMatrixTableProperties(td)
		%
		%   Input Arguments:
		%     td - Matrix-table definition struct (from cfgMatrices).
		%
		%   Output Arguments:
		%     tp - Struct with fields: Name, Description, Unit, Format,
		%          GraphType, GraphOptions, Resources, SummaryType, NodeType,
		%          RowTotal, ColTotal.
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
		%getSummaryTableProperties - Build a cTableMatrix properties struct for a summary table
		%   Like getMatrixTableProperties, but sets SummaryType from td.stable
		%   (instead of cType.SummaryId.NONE) and forces RowTotal and ColTotal
		%   to false, since summary tables do not include totals rows/columns.
		%
		%   Syntax:
		%     tp = obj.getSummaryTableProperties(td)
		%
		%   Input Arguments:
		%     td - Summary-table definition struct (from cfgSummary).
		%
		%   Output Arguments:
		%     tp - Struct with fields: Name, Description, Unit, Format,
		%          GraphType, GraphOptions, Resources, SummaryType, NodeType,
		%          RowTotal (false), ColTotal (false).
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