classdef (Sealed) cTableMatrix < cTableResult
% cTableMatrix Implements cTable interface to store the matrix results of ExIOLab.
%   It store the row/col summary of the matrix
%   Methods:
%       obj=cTableMatrix(data,rowNames,colNames,RowSum,ColSum)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(p)
%       res=obj.exportTable(varmode,fmt)
%       obj.printTable
%       obj.viewTable
%       log=obj.saveTable(filename)
%       status=obj.isGraph
%       obj.showGraph(options)
%       res=obj.getDescriptionLabel
% See also cTableResult, cTable
%
    properties (Access=private)
        RowSum			% Row summary true/false
        ColSum			% Column summary true/false
    end
    properties (GetAccess=public,SetAccess=private)
        GraphOptions    % Graph Type
    end
    methods
        function obj=cTableMatrix(data,rowNames,colNames,rowSum,colSum)
        % Table constructor
        %  Input:
        %   data - Matrix containing the data
        %   rowNames - Cell Array containing the row's names
        %   colNames - Cell Array containing the column's names
        %   rowSum - true/false row summary computation
        %   colSum - true/false column summary computation
            if rowSum
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if colSum
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            if colSum && rowSum
                data(end,end)=0.0;
            end
            obj.Data=num2cell(data);
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.ColSum=colSum;
            obj.RowSum=rowSum;
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
        end

        function res=getMatrix(obj)
        % Get the table data as Array
            res=cell2mat(obj.Data);
        end

        function res=formatData(obj)
        % Format the data value as characters
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
                res=addprop(res,["State","GraphType","GraphOptions","Format","Units"],...
                    ["table","table","table","table","table"]);
                res.Properties.CustomProperties.State=obj.State;
                res.Properties.CustomProperties.GraphType=obj.GraphType;
                res.Properties.CustomProperties.GraphOptions=obj.GraphOptions;
                res.Properties.CustomProperties.Format=obj.Format;
                res.Properties.CustomProperties.Units=obj.Unit;
            end
        end

        function res=getStructTable(obj)
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
                    'State',obj.State,'Unit',obj.Unit,'Format',obj.Format,'Data',data);
        end

        function res = isNumericColumn(obj,idx)
            res=(idx>0) && (idx<obj.NrOfCols);
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=repmat(cType.ColumnFormat.NUMERIC,1,obj.NrOfCols-1);
        end

        function res=getColumnWidth(obj)
            lkey=max(cellfun(@length,obj.Values(:,1)))+2;
            tmp=regexp(obj.Format,'[0-9]+','match','once');
            lfmt=str2double(tmp);
            res=[lkey,repmat(lfmt,1,obj.NrOfCols-1)];
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
            % first column header size
            tmp=[obj.ColNames{1},obj.RowNames(1:end)];
            len=max(cellfun(@length,tmp))+1;
            fkey=[' %-',num2str(len),'s'];
            % rest of columns
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
            if obj.RowSum
                fprintf(fId,'%s\n',lines);
                tmp=obj.Data(end,:);
                if obj.ColSum
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
        function res=isUnitCostTable(obj)
            res=bitget(obj.GraphOptions,1);
        end

        function res=isFlowsTable(obj)
            res=bitget(obj.GraphOptions,2);
        end

        function res=isGeneralCostTable(obj)
            res=bitget(obj.GraphOptions,3);
        end

        function res=isDigraph(obj)
        % Determine if table has a digraph representation       
            res=(obj.GraphType==cType.GraphType.DIAGRAM_FP);
        end

    end
end