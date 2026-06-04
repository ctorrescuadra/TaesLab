classdef (Abstract) cTableResult < cTable
%cTableResult - Abstract base class to store thermoeconomic result tables.
%   cTableResult extends cTable with additional properties (Format, Unit, NodeType)
%   needed to represent computation results. It is not intended to be instantiated
%   directly; use the concrete subclasses cTableCell or cTableMatrix instead.
%
%   This class overrides exportTable to support formatted output (fmt flag) and
%   provides getCellData and getProperties as result-specific operations.
%
%   Derived classes: cTableCell, cTableMatrix
%
%   cTableResult properties:
%     Format   - Format string array for each data column
%     Unit     - Unit label array for each data column
%     NodeType - Row key node type (see cType.NodeType)
%
%   cTableResult properties (inherited from cTable):
%     Data        - Cell array with the table data
%     Values      - Cell array with data including row and column names
%     RowNames    - Cell array with row key names
%     ColNames    - Cell array with column names
%     NrOfRows    - Number of data rows
%     NrOfCols    - Number of columns (including row-name column)
%     Name        - Table identifier name
%     Description - Table header or description text
%     State       - Thermodynamic state name associated with the data
%     Sample      - Resource cost sample name
%     Resources   - True if the table contains resource cost information
%     GraphType   - Graph type associated with the table (see cType.GraphType)
%
%   cTableResult methods:
%     exportTable   - Export table in different variable formats (overrides cTable)
%     getCellData   - Return table values as a cell array, optionally formatted
%     getProperties - Return a struct with the result-specific table properties
%
%   cTableResult methods (inherited from cTable):
%     getStructData   - Return table data as a struct array
%     getMatlabTable  - Return table as a MATLAB table object (MATLAB only)
%     getColumnValues - Return the values of a data column
%     getColumnData   - Return a key/value struct array for a data column
%     getColumnWidth  - Return the display width of each column
%     getColumnFormat - Return the format code of each column (see cType.ColumnFormat)
%     getStructTable  - Return a struct with table name, description and data
%     setColumnValues - Replace the values of one or more data columns
%     setRowValues    - Replace the values of one or more data rows
%     setStudyCase    - Set the State and Sample identifiers
%     setDescription  - Set the table description text
%     isNumericColumn - True if the specified column contains numeric data
%     isNumericTable  - True if all data columns are numeric
%     isGraph         - True if a graph type is associated with the table
%     showTable       - Display the table (console, GUI or HTML)
%     saveTable       - Save the table to a file (CSV, XLSX, JSON, XML, TXT, HTML, LaTeX, MD)
%
%   See also cTable, cTableCell, cTableMatrix
%
    properties (GetAccess=public, SetAccess=protected)
        Format    % Format string array for each data column
        Unit      % Unit label array for each data column
        NodeType  % Row key node type (see cType.NodeType)
    end

    methods
        function res=exportTable(obj,varmode,fmt)
        %exportTable - Export table data in different variable formats
        %   Overrides cTable.exportTable to add optional formatted-output support
        %   via the fmt flag.
        %   Syntax:
        %     res = obj.exportTable(varmode,fmt)
        %   Input Arguments:
        %     varmode - Output variable type (default: cType.VarMode.NONE)
        %       cType.VarMode.NONE   - return the cTableResult object (no conversion)
        %       cType.VarMode.CELL   - return a cell array (via getCellData)
        %       cType.VarMode.STRUCT - return a struct array (via getStructData)
        %       cType.VarMode.TABLE  - return a MATLAB table object (MATLAB only)
        %     fmt - Apply column formatting to numeric values: true | false (default)
        %           Only used when varmode is CELL or STRUCT.
        %   Output Arguments:
        %     res - Table data in the requested variable type
        %
            switch nargin
                case 1
                    varmode=cType.VarMode.NONE;
                    fmt=false;
                case 2
                    fmt=false;
            end
            switch varmode
                case cType.VarMode.CELL
                    res=obj.getCellData(fmt);
                case cType.VarMode.STRUCT
                    res=obj.getStructData(fmt);
                case cType.VarMode.TABLE
                    if isMatlab
                        res=obj.getMatlabTable;
                    else
                        res=obj;
                    end
                otherwise
                    res=obj;
            end
        end

        function res=getCellData(obj,fmt)
        %getCellData - Return table values as a cell array
        %   Syntax:
        %     res = obj.getCellData(fmt)
        %   Input Arguments:
        %     fmt - (optional) true to apply column formatting to numeric values;
        %           false (default) to return raw values
        %   Output Arguments:
        %     res - cell array with column names in the first row, row names in
        %           the first column, and data values in the remaining cells
            if nargin==1
                fmt=false;
            end
            if fmt
                res=[obj.ColNames;[obj.RowNames',obj.formatData]];
            else    
                res=obj.Values;
            end
        end

        function res = getProperties(obj)
        %getProperties - Return a struct with the result-specific table properties
        %   Returns Format, Unit, NodeType and the inherited State and Sample fields.
        %   The set of fields included in Format, Unit and NodeType is determined
        %   by cType.getPropertiesList.
        %   Syntax:
        %     res = obj.getProperties()
        %   Output Arguments:
        %     res - struct containing Format, Unit, NodeType, State and Sample
        %
            res = struct();
            list=cType.getPropertiesList(obj);   
            for i = 1:numel(list)
                fname = list{i};
                if isprop(obj, fname)
                    res.(fname) = obj.(fname);
                end
            end
            res.State=obj.State;
            res.Sample=obj.Sample;
        end
    end
end
