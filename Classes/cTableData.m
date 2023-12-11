classdef cTableData < cTable
% cTableData implement cTable to use in cReadModelTable
%   Methods:
%       cTableData(data,rowNames,colnames)
%       cTableData.create(values)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(idx)
%       status=obj.isNumericTable
%       status=obj.isNumericColumn(i)
%       res=obj.getColumnFormat
%       res=obj.getColumnWidth
%       res=obj.getStructData
%       res=obj.getStructTable
%       res=obj.getMatlabTable
%       res=obj.exportTable(varmode)
%       obj.printTable
%       obj.viewTable
%       log=obj.saveTable(filename)
% See also cTable
    properties(Access=private)
        fdata   % Format Data
        fcol    % Columns Format
        wcol    % Columns Width
    end
    methods
        function obj = cTableData(data,rowNames,colNames)
        %cTableData Construct an instance of this class
        %  data could be cell data or struct data
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.Data=data;
            obj.NrOfCols=length(obj.ColNames);
            obj.NrOfRows=length(obj.RowNames);
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                obj.messageLog(cType.ERROR,'Invalid table size (%d,%d)',size(data,1),size(data,2));
            end
        end

        function setProperties(obj,name,descr)
        % Set Table Description and Name from cType
        %   Input:
        %       idx - Table index
            obj.Name=name;
            obj.Description=descr;
        end

        function res=getColumnWidth(obj)
        % Get column width info
            if isempty(obj.fdata)
                obj.buildFormatData;
            end
            res=obj.wcol;
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            if isempty(obj.fdata)
                obj.buildFormatData;
            end
            res=obj.fcol;
        end

        function res=formatData(obj)
        % Get the format of each column (TEXT or NUMERIC)
            if isempty(obj.fdata)
                obj.buildFormatData;
            end
            res=obj.fdata;
        end

        function printTable(obj,fid)
        % Get table as text or print in conoloe
            if nargin==1
                fid=1;
            end
            if isempty(obj.fdata)
                obj.buildFormatData;
            end
            wc=obj.getColumnWidth;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            for j=1:obj.NrOfCols-1
                if obj.fcol(j)==cType.ColumnFormat.NUMERIC
                    lfmt{j+1}=['%',num2str(wc(j+1)),'s '];
                end
            end
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fid,lformat,obj.RowNames{i},obj.fdata{i,:});
            end
            fprintf(fid,'\n');
        end
    end

    methods(Access=private)
        function buildFormatData(obj)
        % Build format data column type and width
            M=obj.NrOfCols-1;
            obj.fdata=obj.Data;
            obj.fcol=zeros(1,M);
            obj.wcol=zeros(1,obj.NrOfCols);
            obj.wcol(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    fmt=['%',num2str(cw),'s'];
                    obj.fdata(:,j)=cellfun(@(x) sprintf(fmt,x),data,'UniformOutput',false);
                    obj.wcol(j+1)=cw+1;
                    obj.fcol(j)=cType.ColumnFormat.NUMERIC;
                else
                    cw=max(cellfun(@length,obj.Values(:,j+1)));
                    obj.wcol(j+1)=cw+2;
                    obj.fcol(j)=cType.ColumnFormat.CHAR;
                end
            end
        end
    end


    methods (Static,Access=public)
        function tbl=create(values)
            % Create a cTableData from values
            rowNames=values(2:end,1);
            colNames=values(1,:);
            data=values(2:end,2:end);
            tbl=cTableData(data,rowNames',colNames);
        end
    end
end