classdef (Sealed) cTableMatrix < cTableResult
%cTableMatrix - Implements cTableResult interface to store matrix results.
%   It store the row/col summary of the matrix
%
%   cTableCell constructor
%     obj = cTableMatrix(data,rowNames,colNames,props)
%
%   cTableMatrix Properties
%     GraphOptions  - Options for graphs
%     SummaryType   - Type of summary type tables
%     RowTotal	  - Row Total is calculated
%     ColTotal	  - Column Total is calculated
% 
%   cTableMatrix methods
%     printTable             - Print a table on console
%     formatData             - Get formatted data
%     getDescriptionLabel    - Get the title label for GUI presentation
%     getMatrixValues        - Get the matrix values
%     getStructData          - Get data as struct array
%     getMatlabTable         - Get data as MATLAB table
%     getStructTable         - Get a structure with the table info
%     isUnitCostTable        - Check if it's a unit cost table (GraphOptions)
%     isFlowsTable           - Check if it's a flows table (GraphOptions)
%     isGeneralCostTable     - Check if it's a general cost table (GraphOptions)
%     isTotalMalfunctionCost - Check if it's Total Malfunction Cost Table (GraphOptions)
%
%   cTable methods
%     getProperties   - Get table properties
%     setStudyCase    - Set state and sample values
%     setDescription  - Set Table Header or Description
%     showTable       - Show the tables in diferent interfaces
%     exportTable     - Export table in diferent formats
%     saveTable       - Save a table into a file in diferent formats
%     isNumericTable  - Check if all data of the table are numeric
%     isNumericColumn - Check if a column data is numeric
%     isGraph         - Check if the table has a graph associated
%     getColumnFormat - Get the format of the columns
%     getColumnWidth  - Get the width of the columns
%
%   See also cTableResult, cTable, cGraphResults
%
    properties (GetAccess=public,SetAccess=private)
        SummaryType     % Type of Summary Table
        GraphOptions    % Graph Type
        RowTotal	    % Row Total true/false
        ColTotal	    % Column Total true/false
    end

    methods
        function obj=cTableMatrix(data,rowNames,colNames,props)
        %cTableMatrix - create an instance of the class
        %   Syntax:
        %     obj = cTableMatrix(data,rowNames,colNames,props) 
        %   Input:
        %     data - Matrix containing the data
        %     rowNames - Cell Array containing the row's names
        %     colNames - Cell Array containing the column's names
        %     props - additional properties
        %      RowTotal: true/false row total sum
        %      ColTotal: true/false column total sum
        %      Name: Name of the table
        %      Description: table description
        %      Unit: unit name of the data
        %      Format: format of the data
        %      GraphType: type of graph asociated
        %      GraphOptions: options of the graph
        %
            % Compute Totals if is required          
            if props.RowTotal
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if props.ColTotal
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            if props.ColTotal && props.RowTotal
                data(end,end)=0.0;
            end
            % Assign properties
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
            obj.Data=num2cell(zerotol(data));
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            if obj.checkTableSize
                obj.setProperties(props);
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end
        
        function res=getMatrixValues(obj)
        %getMatrixValues - Get the table data as Array
        %   Syntax: 
        %     res = obj.getMatrixValues
        %   Output Arguments:
        %     res - Numeric array containing the data
        % 
            res=cell2mat(obj.Data);
        end

        function res=formatData(obj)
        %formatData - Apply Format to the data values
        %   Syntax: 
        %     res = obj.formatData
        %   Output Arguments:
        %     res - formatted data cell array
        % 
            res=cellfun(@(x) sprintf(obj.Format,x),obj.Data,'UniformOutput',false);
        end

        function res=getStructData(obj,fmt)
        %getStructData - Get table as formatted structure
        %   Syntax:
        %     res = obj.getStructData(fmt)
        %   Input Arguments:
        %     fmt - Use data format. true | false (default)
        %   Output Arguments:
        %     res - struct with table data information
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
        %getMatlabTable - Get the table as Matlab table
        %   Syntax:
        %     res = obj.getMatlabTable
        %   Output Arguments:
        %     res - Matlab table with data information and properties
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
        %getStructTable Get table info as structure
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with table data information and properties
        %
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
                    'State',obj.State,'Unit',obj.Unit,'Format',obj.Format,'Data',data);
        end

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Get the description of the table plus Unit and State
        %   Syntax:
        %     res = obj.getDescriptionLabel
        %   Output Arguments:
        %     res - char array with table description, units and state data
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
        %printTable - Print table on console or in a file in a pretty formatted way
        %   Syntax:
        %     obj.printTable(fid)
        %   Input Argument:
        %     fId - optional parameter 
        %       If not provided, table is show in console
        %       If provided, table is writen to a file identified by fId
        %   See also fopen
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
        %isUnitCostTable - Check if table has unit costs
            res=bitget(obj.GraphOptions,1);
        end

        function res = isFlowsTable(obj)
        %isFlowtable - Check if table contains flows or processes
            res=bitget(obj.GraphOptions,2);
        end

        function res = isGeneralCostTable(obj)
        %isGeneralCostTable - Check if table is general cost
            res=bitget(obj.GraphOptions,3);
        end

        function res = isTotalMalfunctionCost(obj)
        %isTotalMalfunctionCost - Check if table is total malfuction cost
            res=bitget(obj.GraphOptions,4);
        end
    end

    methods(Access=private)
        function setProperties(obj,p)
        %setProperties - set the additional properties of the table
        %   Syntax:
        %     setProperties(obj,p)
        %   Input Arguments:
        %     p - struct with the cTableCell properties
        %
            list=cType.TableMatrixProps;
            for i = 1:numel(list)
                fname = list{i};
                if isfield(p, fname)
                    obj.(fname) = p.(fname);
                end
            end
            obj.setColumnFormat;
            obj.setColumnWidth;
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