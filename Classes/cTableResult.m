classdef (Abstract) cTableResult < cTable
%cTableResult - Abstrat class to store results into a cTable.
%   This class is the base class to store results tables. It is derived from cTable.
%   The class implements methods to export the table in different formats (cell, struct, table).
%   The class also implements methods to get the table properties.
%   Derived classes: cTableMatrix, cTableCell
%
%   cTableResults properties:
%     Format   - Format of the table columns
%     Unit     - Units of the table columns
%     NodeType - Type of row key (see cType.NodeType)
%
%   cTableResult properties (inherited from cTable):
%     Data        - Cell array with the table data
%     Values      - Cell array with the table data including row and column names
%     RowNames    - Cell array with the row names
%     ColNames    - Cell array with the column names
%     NrOfRows    - Number of rows
%     NrOfCols    - Number of columns
%     Name        - Name of the table
%     Description - Description of the table
%     State       - State Name of the data
%     Sample      - Resource sample name
%     Resources   - Contains reources info
%     GraphType   - Graph Type associated to table
%
%   cTableResult methods:
%     exportTable   - Get cTable info in diferent types of variables
%     getCellData   - Get table as cell array
%     getProperties - Get the additional properties of a cTableResults
%     
%   cTableResult methods (inherited from cTable):
%     getStructData   - Get table as struct array
%     getMatlabTable  - Get table as a MATLAB table (if available)
%     getColumnWidth  - Get the width of each column
%     getColumnFormat - Get the format of each column (TEXT or NUMERIC)
%     getStructTable  - get a structure with the table info
%     setColumnValues - set the values of a column
%     setRowValues    - set the values of a row
%     setStudyCase    - Set state and sample values
%     setDescription  - Set Table Header or Description 
%     isNumericColumn - Check if a column is numeric
%     isNumericTable  - Check if the table is numeric
%     isGraph         - Check if the table is a graphic table
%     showTable       - show the tables in diferent interfaces
%     exportTable     - export table in diferent formats
%     saveTable       - save a table into a file in diferent formats
%
%   See also cTable, cTableMatrix, cTableCell
%
    properties (GetAccess=public, SetAccess=protected)
        Format    % Format of the table cells
        Unit      % Units of the table cell
        NodeType  % Type of Row key
    end

    methods
        function res=exportTable(obj,varmode,fmt)
        %exportTable - Get cTable info in diferent types of variables
        %   Syntax:
        %     res=obj.exportTable(varmode,fmt)
        %   Input Arguments:
        %     varmode - type of variable
        %       cType.VarMode.NONE (default) - return the cTableResult object
        %       cType.VarMode.CELL           - return a cell array
        %       cType.VarMode.STRUCT         - return a struct array
        %       cType.VarMode.TABLE          - return a MATLAB table (if available)
        %     fmt - use formatted data true | false (default)
        %   Output Arguments:
        %     res - table in the selected variable type   
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
        %getCellData - Get table as cell array
        %   Syntax:
        %     obj.getCellData(fmt)
        %   Input Arguments:
        %     fmt - (true/false) indicate is the numerical values of the table must be formatted
        %   Output Argumenta
        %     res - cell array with the table values
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
        %getProperties - get the additional properties of a cTableResults
        %   Syntax:
        %     obj.getProperties();
        %   Output Arguments:
        %     res - struct with the additional properties of the table
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
