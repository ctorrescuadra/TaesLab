classdef cTableData < cTable
%cTableData - Implement cTable to store data model tables.
%   This class implements methods to manage data tables. It is derived from cTable.
%
%   cTableData properties (inherited from cTable):
%     Data        - Cell array with the table data
%     Values      - Cell array with the table data including row and column names
%     RowNames    - Cell array with the row names
%     ColNames    - Cell array with the column names
%     NrOfRows    - Number of rows
%     NrOfCols    - Number of columns
%     Name        - Name of the table
%     Description - Description of the table
%     State       - State Name of the data     
%     Sample       - Resource sample name
%     Resources    - Contains reources info
%     GraphType    - Graph Type associated to table
%
%   cTableData methods:
%     cTableData          - Construct an instance of this class
%     getStructTable       - Get a table as struct
%     printTable           - Print a table on console
%     formatData           - Get formatted data
%     getDescriptionLabel  - Get the title label for GUI presentation
%     create               - Create a cTableData from values (static method)
%
%   cTableData methods (inherited from cTable):
%     exportTable     - Get cTable info in diferent types of variables
%     getCellData     - Get table as cell array
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
%   See also cTable
%
    methods
        function obj = cTableData(data,rowNames,colNames,props)
        %cTableData - Construct an instance of this class
        %   Syntax:
        %     obj = cTableData(data,rowNames,colNames,properties)
        %   Input Arguments:
        %   data - cell array containg data table
        %   rowNames - cell array with the row names
        %   colNames - cell array with the column names
        %   properties - struct with additional table properties
        %     Name - name of the table
        %     Description - table description
        %   Output Arguments:
        %     obj - cTableData object
        
            % Check input arguments
            if iscolumn(rowNames)
                obj.RowNames=transpose(rowNames);
            else
                obj.RowNames=rowNames;
            end
            if iscolumn(colNames)
                obj.ColNames=transpose(colNames);
            else
                obj.ColNames=colNames;
            end
            % Set the properties
            obj.Data=data;
            obj.NrOfCols=length(obj.ColNames);
            obj.NrOfRows=length(obj.RowNames);
            obj.State='DATA';
            if obj.checkTableSize
                obj.setProperties(props)
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end

        function res=getStructTable(obj)
        %getStructTable - Get table as a struct
        %   Syntax:
        %     res=obj.getStructTable
        %   Output Arguments:
        %     res - struct with table information
        %       Name - Name of the table
        %       Description - table Description
        %       State - State of the data
        %       Data - Data of the table as struct
        %
            data=obj.getStructData;
            res=struct('Name',obj.Name,'Description',obj.Description,...
                'State',obj.State,'Data',data);
        end

        function res=formatData(obj)
        %formatData - Format the values of the table
        %   If values are numeric are converted to numeric strings
        %   Syntax:
        %     res = obj.formatData();
        %   Output arguments:
        %     res - cell array with formatted data
        %   
            res=obj.Data;
            cw=obj.getColumnWidth;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j+1)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    fmt=['%',num2str(cw(j+1)),'s'];
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),data,'UniformOutput',false);
                end
            end
        end

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Get the description of each table for graph or printing
        % Syntax:
        %   res = obj.getDescriptionLabel();
        % Output Arguments:
        %   res - char array with table description 
        %
            res=obj.Description;
        end

        function printTable(obj,fid)
        %printTable - Display table on console or in a file in a pretty formatted way
        %   Syntax:
        %     obj.printTable(fid)
        %   Input Arguments:
        %     fid - (optional) file Id parameter. 
        %       If not provided table, is show in console
        %       If provided, table is writen into a file defined by fid.
        %   See also fopen
        %   
            if nargin==1
                fid=1;
            end
            fdata=obj.formatData;
            wc=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            for j=2:obj.NrOfCols
                if fcol(j)==cType.ColumnFormat.NUMERIC
                    lfmt{j}=['%',num2str(wc(j)),'s '];
                end
            end
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s\n',obj.getDescriptionLabel);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            arrayfun(@(i) fprintf(fid,lformat,obj.RowNames{i},fdata{i,:}),1:obj.NrOfRows);
            fprintf(fid,'\n');
        end
    end

    methods(Access=private)
        function setProperties(obj,p)
        %setProperties - Set the additional properties of the table
        %   Syntax:
        %     setProperties(obj,p)
        %   Input Arguments:
        %     p - struct with the cTableCell properties
        %
            obj.Name=p.Name;
            obj.Description=p.Description;
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function setColumnFormat(obj)
        %setColumnFormat - Define the format of each column (TEXT or NUMERIC)
        %   Set the property fcol
        %   It is used in printTable method
        %   Syntax:
        %     obj.setColumnFormat
        %
            tmp=cellfun(@isnumeric,obj.Values(2:end,:));
            if isrow(tmp)
                obj.fcol=tmp+1;
            else
                obj.fcol=all(tmp)+1;
            end
        end

        function setColumnWidth(obj)
        %setColumnWidth - Define the width of the columns
        %   Set the property wcol
        %   It is used in printTable method
        %   Syntax:
        %     obj.setColumnWidth
            res=zeros(1,obj.NrOfCols);
            for j=1:obj.NrOfCols
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Values(2:end,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    res(j)=cw+1;
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
            obj.wcol=res;
        end
    end
    
    methods (Static,Access=public)
        function tbl=create(values,props)
        %create - Create a cTableData from values
        %   Syntax:
        %     tbl = cTableData.create(values,props)
        %   Input Arguments:
        %     values - cell array with the table values
        %       First row with the column names
        %       First column with the row names
        %     props - struct with additional table properties
        %       Name - name of the table
        %       Description - table description
        %   Output Arguments:
        %     tbl - cTableData object or cMessageLogger object if an error occurs
        %
            tbl=cMessageLogger(cType.INVALID);
            if all(size(values)>1)   
                rowNames=values(2:end,1);
                colNames=values(1,:);
                data=values(2:end,2:end);
                tbl=cTableData(data,rowNames',colNames,props);
            else
                tbl.messageLog(cType.ERROR,cMessages.NoValuesAvailable);
            end
        end

        function tbl=import(filename,props)
        %import - Create cTableData from file
        %   Valid formats: CSV, JSON.
        %   In case of CSV file, first row must contain column names and first column row names.
        %   In case of JSON file, it must contain a single JSON array object with field names as column names and field values as data.
        %   Syntax:
        %     tbl = cTableData.import(filename,props)
        %   Input Arguments:
        %     filename - char array with the file name
        %     props - struct with additional table properties
        %       Name - name of the table
        %       Description - table description
        %   Output Arguments:
        %     tbl - cTableData object or cMessageLogger object if an error occurs
        %
            tbl=cMessageLogger();
            % Validate filename
            if ~isFilename(filename)
                tbl.messageLog(cType.ERROR,cMessages.InvalidFileName)
                return
            end
            % Determine file type and import data
            fileType=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    values=importCSV(filename);
                case cType.FileType.JSON
                    S=importJSON(tbl,filename);
                    if ~empty(S) && isstruct(S)
                        values=[fieldnames(S)'; struct2cell(S)'];
                    else
                        tbl.messageLog(cType.ERROR,cMessages.InvalidInputFile,filename);
                        return
                    end
                otherwise
                    tbl.messageLog(cType.ERROR,cMessages.InvalidInputFile);
                    return
            end
            % Create cTableData object
            tbl=cTableData.create(values,props);
        end
    end
end