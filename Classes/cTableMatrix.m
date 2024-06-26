classdef (Sealed) cTableMatrix < cTableResult
% cTableMatrix Implements cTable interface to store the matrix results of ExIOLab.
%   It store the row/col summary of the matrix
%   Methods:
%       obj=cTableMatrix(data,rowNames,colNames,RowTotal,ColTotal)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(p)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.printTable(fId)
%       obj.showTable(options)
%       log=obj.saveTable(filename)
%       res=obj.exportTable(varmode,fmt)
%       res=obj.isNumericTable
%       res=obj.isNumericColumn(idx)
%       res=obj.getColumnFormat;
%       res=obj.getColumnWidth;
%       res=obj.formatData
%       obj.setColumnValues(idx,values)
%       obj.setRowValues(idx,values)
%       status=obj.isGraph
%       obj.showGraph(options)
%       res=obj.getDescriptionLabel
% See also cTableResult, cTable
%
    properties (Access=private)
        RowTotal			% Row Total true/false
        ColTotal			% Column Total true/false
    end
    properties (GetAccess=public,SetAccess=private)
        GraphOptions    % Graph Type
    end
    methods
        function obj=cTableMatrix(data,rowNames,colNames,rowTotal,colTotal)
        % Table constructor
        %  Input:
        %   data - Matrix containing the data
        %   rowNames - Cell Array containing the row's names
        %   colNames - Cell Array containing the column's names
        %   rowTotal - true/false row total sum
        %   colTotal - true/false column total sum
            if rowTotal
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if colTotal
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            if colTotal && rowTotal
                data(end,end)=0.0;
            end
            obj.Data=num2cell(zerotol(data));
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.ColTotal=colTotal;
            obj.RowTotal=rowTotal;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames); 
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                obj.messageLog(cType.ERROR,'Invalid table size (%d,%d)',size(data,1),size(data,2));
            end
        end
        
        function setProperties(obj,p)
        % Set the table properties: Description, Unit, Format, GraphType
            obj.Name=p.key;
            obj.Description=p.Description;
            obj.Unit=p.Unit;
            obj.Format=p.Format;
            obj.GraphType=p.GraphType;
            obj.GraphOptions=p.GraphOptions;
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function res=getMatrix(obj)
        % Get the table data as Array
            res=cell2mat(obj.Data);
        end

        function res=formatData(obj)
        % Format the data values as characters
            res=cellfun(@(x) sprintf(obj.Format,x),obj.Data,'UniformOutput',false);
        end

        function res=getStructData(obj,fmt)
        % Get table as formatted structure
        %  Input:
        %   fmt - (true/false) use table format
            if nargin==1
                fmt=false;
            end
            if fmt
                val=[obj.RowNames',obj.formatData];
            else
                val=[obj.RowNames',obj.Data];
            end
            res=cell2struct(val,obj.ColNames,2);
        end

        function res=getMatlabTable(obj)
        % Return as matlab table if apply
            res=getMatlabTable@cTable(obj);
            if isMatlab
                res=addprop(res,["GraphOptions","Format","Units"],...
                    ["table","table","table"]);
                res.Properties.CustomProperties.GraphOptions=obj.GraphOptions;
                res.Properties.CustomProperties.Format=obj.Format;
                res.Properties.CustomProperties.Units=obj.Unit;
            end
        end

        function res=getStructTable(obj)
        % Get table info as structure
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
                    'State',obj.State,'Unit',obj.Unit,'Format',obj.Format,'Data',data);
        end

        function res = isNumericColumn(obj,idx)
        % Check if the column is numeric
            res=(idx>0) && (idx<obj.NrOfCols);
        end

        function setColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            tmp=repmat(cType.ColumnFormat.NUMERIC,1,obj.NrOfCols-1);
            obj.fcol=[cType.ColumnFormat.CHAR,tmp];
        end

        function setColumnWidth(obj)
        % Define the width of columns
            lkey=max(cellfun(@length,obj.Values(:,1)))+2;
            tmp=regexp(obj.Format,'[0-9]+','match','once');
            lfmt=str2double(tmp);
            obj.wcol=[lkey,repmat(lfmt,1,obj.NrOfCols-1)];
        end

        function res=getDescriptionLabel(obj)
        % Get the description of the table
            res=[obj.Description,' ',obj.Unit];
        end

        function printTable(obj,fId)
        % Print table on console in a pretty formatted way
            if nargin==1
                fId=1;
            end
            if obj.NrOfCols > cType.MAX_PRINT_COLS
                fprintf(fId,'\n');
                fprintf(fId,'%s\n',obj.getDescriptionLabel);
                fprintf(fId,'\n');   
                fprintf(fId,'--- Table exceed number of columns to print --- \n');
                fprintf(fId,'\n');   
                return
            end
            nrows=obj.NrOfRows;
			ncols=obj.NrOfCols;
            wc=obj.getColumnWidth;
            % first column header size
            len=wc(1)+1;
            fkey=[' %-',num2str(len),'s'];
            % Rest of columns
            tmp=regexp(obj.Format,'[0-9]+','match','once');
            fval=['%',tmp,'s'];
            hformat=[fkey,repmat(fval,1,ncols-1)];
            sformat=[fkey,repmat(obj.Format,1,ncols-1),'\n'];
            % Print formatted table
            header=sprintf(hformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
			fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');       
			fprintf(fId,'%s\n',header);
            fprintf(fId,'%s\n',lines);
            for i=1:nrows-1
				fprintf(fId,sformat,obj.RowNames{i},obj.Data{i,:});
            end	
            % Total summary by rows
            if obj.RowTotal
                fprintf(fId,'%s\n',lines);
                tmp=obj.Data(end,:);
                if obj.ColTotal
                    tmp{end,end}='';
                end
                fprintf(fId,sformat,obj.RowNames{end},tmp{:});       
            else
                fprintf(fId,sformat,obj.RowNames{end},obj.Data{end,:}); 
            end
            fprintf(fId,'\n');
        end
        %%%%
        % Graphic Interface functions
        %%%%
        function res = isUnitCostTable(obj)
        % Table is contains unit costs
            res=bitget(obj.GraphOptions,1);
        end

        function res = isFlowsTable(obj)
        % Table is contains flows or processes
            res=bitget(obj.GraphOptions,2);
        end

        function res = isGeneralCostTable(obj)
        % Table is general cost
            res=bitget(obj.GraphOptions,3);
        end

        function res = isTotalMalfunctionCost(obj)
        % Table is TotalMalfuctionCost
            res=bitget(obj.GraphOptions,4);
        end
    end

    methods(Static)
        function tbl=create(data,rowNames,colNames,param)
        % Create a cTableMatrix given the additional properties
        %   Input:
        %       data - Matrix containing the data
        %       rowNames - Cell Array containing the row's names
        %       colNames - Cell Array containing the column's names
        %       param - additional properties:
        %           rowTotal: true/false row total sum
        %           colTotal: true/false column total sum
        %           Name: Name of the table
        %           Description: table description
        %           Unit: unit name of the data
        %           Format: format of the data
        %           GraphType: type of graph asociated
        %           GraphOptions: options of the graph
        % See also cResultTableBuilder
            tbl=cTableMatrix(data,rowNames,colNames,param.rowTotal,param.colTotal);
            if tbl.isValid
                tbl.setProperties(param);
            end
        end
    end
end