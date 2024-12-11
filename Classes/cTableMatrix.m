classdef (Sealed) cTableMatrix < cTableResult
% cTableMatrix Implements cTable interface to store the matrix results
%   It store the row/col summary of the matrix
%
% cTableCell Properties
%   GraphOptions  - Options for graphs
%   SummaryType   - Type of summary type tables
% 
% cTableCell Methods
%   printTable             - Print a table on console
%   formatData             - Get formatted data
%   getDescriptionLabel    - Get the title label for GUI presentation
%   getMatrixValues        - Get the matrix values
%   isUnitCostTable        - Check if its a unit cost table (GraphOptions)
%   isFlowsTable           - Check if its a flows table (GraphOptions)
%   isGeneralCostTable     - Check if its a general cost table (GraphOptions)
%   isTotalMalfunctionCost - Check if its Total Malfunction Cost Table (GraphOptions)
%
% cTable Methods
%   showTable       - show the tables in diferent interfaces
%   exportTable     - export table in diferent formats
%   saveTable       - save a table into a file in diferent formats
%   isNumericTable  - check if all data of the table are numeric
%   isNumericColumn - check if a column data is numeric
%   isGraph         - check if the table has a graph associated
%   getColumnFormat - get the format of the columns
%   getColumnWidth  - get the width of the columns
%   getStructData   - get data as struct array
%   getMatlabTable  - get data as MATLAB table
%   getStructTable  - get a structure with the table info
%
% See also cTableResult, cTable, cGraphResults
%
    properties (Access=private)
        RowTotal			% Row Total true/false
        ColTotal			% Column Total true/false
    end
    properties (GetAccess=public,SetAccess=private)
        SummaryType     % Type of Summary Table
        GraphOptions    % Graph Type
    end
    methods
        function obj=cTableMatrix(data,rowNames,colNames,props)
        % Table constructor
        %  Input:
        %   data - Matrix containing the data
        %   rowNames - Cell Array containing the row's names
        %   colNames - Cell Array containing the column's names
        %   props - additional properties
        %    rowTotal: true/false row total sum
        %    colTotal: true/false column total sum
        %    Name: Name of the table
        %    Description: table description
        %    Unit: unit name of the data
        %    Format: format of the data
        %    GraphType: type of graph asociated
        %    GraphOptions: options of the graph            
            if props.rowTotal
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if props.colTotal
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            if props.colTotal && props.rowTotal
                data(end,end)=0.0;
            end
            obj.Data=num2cell(zerotol(data));
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            if obj.checkTableSize
                obj.setProperties(props);
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end
        
        function res=getMatrixValues(obj)
        % Get the table data as Array
        % Syntax: 
        %   res = obj.getMatrixValues
        % Output Arguments:
        %   res - Numeric array containing the data
        % 
            res=cell2mat(obj.Data);
        end

        function res=formatData(obj)
        % Apply Format to the data values
        % Syntax: 
        %   res = obj.formatData
        % Output Arguments:
        %   res - formatted data cell array
        % 
            res=cellfun(@(x) sprintf(obj.Format,x),obj.Data,'UniformOutput',false);
        end

        function res=getStructData(obj,fmt)
        % Get table as formatted structure
        % Syntax:
        %   res = obj.getStructData(fmt)
        % Input Arguments:
        %   fmt - Use data format. true | false (default)
        % Output Arguments:
        %   res - struct with table data information
        %
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
        % Get the table as Matlab table
        % Syntax:
        %   res = obj.getMatlabTable
        % Output Arguments:
        %   res - Matlab table with data information and properties
        %
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
        % Syntax:
        %   res = obj.getStructTable
        % Output Arguments:
        %   res - struct with table data information and properties
        %
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
                    'State',obj.State,'Unit',obj.Unit,'Format',obj.Format,'Data',data);
        end

        function res = isNumericColumn(obj,idx)
        % Check if the column is numeric.  
        % Syntax:
        %   res = obj.isNumericColumn(idx)
        % Input Arguments:
        %   idx - Column index
        % Output Arguments:
        %   res - true | false
        %
            res=(idx>0) && (idx<obj.NrOfCols);
        end

        function res=getDescriptionLabel(obj)
        % Get the description of the table plus Unit and State
        % Syntax:
        %   res = obj.getDescriptionLabel
        % Output Arguments:
        %   res - char array with table description, units and state data
        %
            switch obj.SummaryType
                case cType.STATES
                    obj.State='SUMMARY';
                case cType.RESOURCES
                    obj.Sample='SUMMARY';
            end
            if obj.Resources
                stc=horzcat('[',obj.State,'/',obj.Sample,']');
            else
                stc=obj.State;
            end
            res=horzcat(obj.Description,' ',obj.Unit,' - ',stc );
        end

        function printTable(obj,fId)
        % Print table on console or in a file in a pretty formatted way
        % Syntax:
        %   obj.printTable(fid)
        % Input Argument:
        %   fId - optional parameter 
        %     If not provided, table is show in console
        %     If provided, table is writen to a file identified by fId
        % See also fopen
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
            arrayfun(@(i) fprintf(fId,sformat,obj.RowNames{i},obj.Data{i,:}),1:nrows-1);
            % Total summary by rows
            if obj.RowTotal
                fprintf(fId,'%s\n',lines);
                tmp=obj.Data(end,:);
                if obj.ColTotal
                    tmp{end,end}=cType.EMPTY_CHAR;
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

    methods(Access=private)
        function setProperties(obj,p)
         % Set the table properties: Description, Unit, Format, GraphType
            try
                obj.Name=p.Name;
                obj.Description=p.Description;
                obj.Unit=p.Unit;
                obj.Format=p.Format;
                obj.GraphType=p.GraphType;
                obj.Resources=p.Resources;
                obj.GraphOptions=p.GraphOptions;
                obj.SummaryType=p.SummaryType;
                obj.setColumnFormat;
                obj.setColumnWidth;
            catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,cMessages.InvalidTableProp);
            end
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
    end
end