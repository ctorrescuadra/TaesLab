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
    properties(Access=public)
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

        function setProperties(obj,idx)
        % Set Table Description and Name from cType
        %   Input:
        %       idx - Table index
            obj.Description=cType.TableDataDescription{idx};
            obj.Name=cType.TableDataName{idx};
        end

        function res = isNumericColumn(obj,idx)
            tmp=cellfun(@isnumeric,obj.Data(:,idx));
            res=all(tmp(:));
        end

        function res = getStructData(obj)
        % Get Table data as struct array
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        % Get Table as Matlab table
            if isOctave
                res=obj;
            else
                res=cell2table(obj.Data,'VariableNames',obj.ColNames(2:end),'RowNames',obj.RowNames');
                res=addprop(res,["Name","State"],["table","table"]);
                res.Properties.Description=obj.Description;
                res.Properties.CustomProperties.Name=obj.Name;
                res.Properties.CustomProperties.State=obj.State;
            end
        end

        function res=getStructTable(obj)
        % Get a structure with the table info
            data=cell2struct([obj.RowNames',obj.Data],obj.ColNames,2);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function res=exportTable(obj,varmode)
        % Get table values in diferent formats
            switch varmode
                case cType.VarMode.CELL
                    res=obj.Values;
                case cType.VarMode.STRUCT
                    res=obj.getStructData;
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

        function buildFormatData(obj)
            M=obj.NrOfCols-1;
            obj.fdata=cell(obj.NrOfRows,M);
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
                    fmt=['%-',num2str(cw),'s'];
                    obj.fdata(:,j)=cellfun(@(x) sprintf(fmt,x),obj.Data(:,j),'UniformOutput',false);
                    obj.wcol(j+1)=cw+2;
                    obj.fcol(j)=cType.ColumnFormat.CHAR;
                end
            end
        end

        function res=getColumnWidth(obj)
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
        % Get table as text
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