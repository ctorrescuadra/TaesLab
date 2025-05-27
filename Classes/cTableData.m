classdef cTableData < cTable
%cTableData - Implement cTable to store data model tables
% 
%   cTableData Methods:
%     cTableData.create    - Create table from cell array
%     printTable           - Print a table on console
%     formatData           - Get formatted data
%     getDescriptionLabel  - Get the title label for GUI presentation
%
%   cTable Methods
%     showTable       - show the tables in diferent interfaces
%     exportTable     - export table in diferent formats
%     saveTable       - save a table into a file in diferent formats
%     isNumericTable  - check if all data of the table are numeric
%     isNumericColumn - check if a column data is numeric
%     isGraph         - check if the table has a graph associated
%     getColumnFormat - get the format of the columns
%     getColumnWidth  - get the width of the columns
%     getStructData   - get data as struct array
%     getMatlabTable  - get data as MATLAB table
%     getStructTable  - get a structure with the table info
%     setColumnValues - set the values of a column
%     setRowValues    - set the values of a row
%
% See also cTable
    methods
        function obj = cTableData(data,rowNames,colNames,props)
        % cTableData Construct an instance of this class
        % Syntax:
        %   obj = cTableData(data,rowNames,colNames,properties)
        % Input Arguments:
        %   data - cell array containg data table
        %   rowNames - cell array with the row names
        %   colNames - cell array with the column names
        %   properties - struct with additional table properties
        %     Name - name of the table
        %     Description - table description
        %
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
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

        function setProperties(obj,props)
        % Set Table properties
        % Input Arguments:
        %   props - Table Properties
        %     Name: Name of the table
        %     Description: Description of the table
            try
                obj.Name=props.Name;
                obj.Description=props.Description;
                obj.setColumnFormat;
                obj.setColumnWidth;
            catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,cMessages.InvalidTableProp);
            end
        end

        function res=getStructTable(obj)
        % Get table as a struct
        % Syntax:
        %   res=obj.getStructTable
        % Output Arguments
        %   res - struct with table information
        %    Name - Name of the table
        %    Description - table Description
        %    State - State of the data
        %    Data - Data of the table as struct
        %
            data=obj.getStructData;
            res=struct('Name',obj.Name,'Description',obj.Description,...
                'State',obj.State,'Data',data);
        end

        function res=formatData(obj)
        % Format the values of the table
        %   If values are numeric are converted to numeric strings
        % Syntax:
        %   res = obj.formatData
        % Output arguments
        %   
            res=obj.Data;
            cw=obj.getColumnWidth;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    fmt=['%',num2str(cw(j+1)),'s'];
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),data,'UniformOutput',false);
                end
            end
        end

        function res=getDescriptionLabel(obj)
        % Get the description of each table for graph or printing
        % Syntax:
        %   res = obj.getDescriptionLabel
        % Output Arguments:
        %   res - char array with table description 
        %
            res=obj.Description;
        end

        function printTable(obj,fid)
        % Get table as text file or printing in console
        % Syntax:
        %   obj.printTable(fid)
        % Input Arguments
        %   fid - optional parameter. 
        %         If not provided table, is show in console
        %         If provided, table is writen into a file defined by fid.
        % See also fopen
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

        function setColumnWidth(obj)
        % Define the width of the columns
            res=zeros(1,obj.NrOfCols);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    res(j+1)=cw+1;
                else
                    res(j+1)=max(cellfun(@length,obj.Values(:,j+1)))+2;
                end
            end
            obj.wcol=res;
        end
    
        function setColumnFormat(obj)
        % Define the format of each column (TEXT or NUMERIC)
            tmp=arrayfun(@(x) isNumericColumn(obj,x),1:obj.NrOfCols-1)+1;
            obj.fcol=[cType.ColumnFormat.CHAR,tmp];
        end

    end
    
    methods (Static,Access=public)
        function tbl=create(values,props)
        % Create a cTableData from values
            rowNames=values(2:end,1);
            colNames=values(1,:);
            data=values(2:end,2:end);
            tbl=cTableData(data,rowNames',colNames,props);
        end
    end
end