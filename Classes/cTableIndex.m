classdef cTableIndex < cTable
%cTableIndex create a cTable with the tables of a cResultInfo
%   The table index is a property of the cResultInfo object
%   
%   cTableIndex constructor:
%     obj = cTableIndex(res)
%
%   cTableIndex properties:
%     Content - Cell array with the cResultInfo tables
%     Info    - cResultId Info object
%
%   cTableIndex methods:
%     printTable           - Print the index table on console
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
%
% See also cTable
%
    properties (GetAccess=public,SetAccess=private)
        Content % Cell array with the cResultInfo tables
        Info    % Info handle
    end
    methods
        function obj=cTableIndex(res)
        %cTableIndex - create a instance of the class
        %   Syntax:
        %     obj = cTableIndex(res)
        %   Input:
        %     res - cResultInfo object
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
        %getDescriptionLabel - Get table description
        %   Syntax:
        %     res = obj.getDescriptionLabel
        %   Output Argument:
        %     res - char array with the table description
        %
            res=[obj.Description, ' - Table Index'];
        end

        function printTable(obj,fid)
        %printTable - Print table on console or in a file in a pretty formatted way
        %   Syntax:
        %     obj.printTable(fid)
        %   Input Argument:
        %     fId - optional parameter 
        %       If not provided, table is show in console
        %       If provided, table is writen to a file identified by fId
        % See also fopen
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