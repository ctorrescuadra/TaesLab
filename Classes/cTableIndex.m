classdef cTableIndex < cTable
%cTableIndex - Catalog table listing all result tables in a cResultInfo object.
%   cTableIndex is a specialised read-only cTable that provides a three-column
%   directory of the tables held by a cResultInfo. Each row corresponds to one
%   result table and records its key name, human-readable description, and
%   whether a graph can be plotted from it.
%
%   A cTableIndex is built automatically when a cResultInfo is constructed and
%   is the object returned by cResultSet.getTableIndex. It supports all standard
%   cTable display, export, and save operations, so it can be shown in the
%   console, opened in the GUI viewer, or saved to any supported file format.
%
%   Table columns:
%     Key         - Table key name (used in cResultInfo.Tables.<Key>)
%     Description - Human-readable description of the table
%     Graph       - 'true' if the table has an associated graph, 'false' otherwise
%
%   cTableIndex properties:
%     Content - Cell array holding the cTable objects from the parent cResultInfo
%     Info    - cResultId object with metadata about the parent result set
%
%   cTableIndex properties (inherited from cTable):
%     Data        - Cell array with the table data (Description and Graph columns)
%     Values      - Full table: [ColNames; RowNames', Data]
%     RowNames    - Table key names (one per result table)
%     ColNames    - {'Key', 'Description', 'Graph'}
%     NrOfRows    - Number of result tables in the parent cResultInfo
%     NrOfCols    - 3
%     Name        - Table name (derived from the ResultId of the parent)
%     Description - Name of the parent result set
%     State       - Always 'INDEX'
%     GraphType   - Always 0 (cTableIndex itself has no associated graph)
%
%   cTableIndex methods:
%     cTableIndex          - Construct an instance from a cResultInfo object
%     printTable           - Print the index to console or a file
%     getDescriptionLabel  - Return the display title for GUI presentation
%
%   cTableIndex methods (inherited from cTable):
%     showTable       - Display the index in console, GUI, or HTML
%     exportTable     - Return the index in a selected variable format
%     saveTable       - Save the index to a file (CSV, XLSX, HTML, …)
%     isNumericTable  - Always false (all columns are text)
%     isNumericColumn - Always false for all columns
%     isGraph         - Always false
%     getColumnFormat - Return column format vector (all CHAR)
%     getColumnWidth  - Return column display widths
%     getStructData   - Return data as struct array
%     getMatlabTable  - Return data as MATLAB table object
%     getStructTable  - Return a struct with table info and data
%
%   Example:
%     res = ExergyAnalysis(data);
%     idx = res.getTableIndex;          % returns cTableIndex
%     idx.showTable;                    % print to console
%     idx.showTable(cType.TableView.HTML);
%     idx.saveTable('index.xlsx');
%
%   See also cTable, cResultInfo, cResultSet
%
    properties (GetAccess=public,SetAccess=private)
        Content % Cell array of cTable objects from the parent cResultInfo
        Info    % cResultId object with metadata of the parent result set
    end
    methods
        function obj=cTableIndex(res)
        %cTableIndex - Construct a catalog table from a cResultInfo object.
        %   Reads all tables held by the cResultInfo and builds a three-column
        %   cTable where each row describes one result table: its key name,
        %   description string, and graph availability flag.
        %   This constructor is called automatically inside cResultInfo and is
        %   not intended for direct use by end users.
        %
        %   Syntax:
        %     obj = cTableIndex(res)
        %   Input Arguments:
        %     res - Source result container
        %       cResultInfo object
        %       Must be a valid cResultInfo with at least one result table
        %   Output Arguments:
        %     obj - cTableIndex object
        %       Check obj.status before use
        % 
            % Check input parameters
            if ~isObject(res,'cResultInfo')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(res))
                return
            end
            % Get tables of the results and build table
            tnames=res.ListOfTables;
            descr=cellfun(@(x) res.Tables.(x).Description,tnames,'UniformOutput',false);
            gtype=cellfun(@(x) mat2str(logical(res.Tables.(x).GraphType)),tnames,'UniformOutput',false);
            obj.ColNames={'Key','Description','Graph'};
            obj.RowNames=tnames';
            obj.NrOfCols=numel(obj.ColNames);
            obj.NrOfRows=numel(obj.RowNames);
            obj.Data=cell(obj.NrOfRows,2);
            obj.Data(:,1)=descr;
            obj.Data(:,2)=gtype;
            obj.Name=cType.ResultIndex{res.ResultId};
            obj.Description=res.ResultName;
            obj.State='INDEX';
            obj.Content=struct2cell(res.Tables);
            obj.Info=res.Info;
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Return the display title used in GUI and HTML headers.
        %   Appends ' - Table Index' to the parent result set name so that the
        %   title clearly identifies the object type when shown in a GUI viewer
        %   or an HTML page.
        %
        %   Syntax:
        %     res = obj.getDescriptionLabel
        %   Output Arguments:
        %     res - char array of the form '<ResultName> - Table Index'
        %
            res=[obj.Description, ' - Table Index'];
        end

        function printTable(obj,fid)
        %printTable - Print the index table with aligned columns.
        %   Writes the table key, description, and graph flag for every result
        %   table to the console or to an open file, using left-aligned columns
        %   sized to the widest entry in each column.
        %   Called internally by cTable.showTable when the CONSOLE view is selected.
        %
        %   Syntax:
        %     obj.printTable
        %     obj.printTable(fid)
        %   Input Arguments:
        %     fid - File identifier (optional)
        %       positive integer returned by fopen
        %       If omitted, output goes to stdout (console)
        %
        %   See also fopen, cTable.showTable
        %
            if nargin==1
                fid=1;
            end
            wc=obj.getColumnWidth;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s\n',obj.getDescriptionLabel);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            arrayfun(@(i) fprintf(fid,lformat,obj.RowNames{i},obj.Data{i,:}),1:obj.NrOfRows)
            fprintf(fid,'\n');
        end
    end

    methods(Access=private)
        function setColumnFormat(obj)
        % Get column format for cTableIndex
            obj.fcol=repmat(cType.ColumnFormat.CHAR,1,obj.NrOfCols);
        end

        function setColumnWidth(obj)
        % Get column width for cTableIndex
            obj.wcol=arrayfun(@(i) max(cellfun(@length,obj.Values(:,i)))+2,1:obj.NrOfCols);
        end
    end
end