classdef (Sealed) cTableCell < cTableResult
% cTableCell Implements cTable interface to store the tabular results of ExIOLab as array cells.
%   Methods:
%       obj=cTableCell(data,rowNames,colNames)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(p)
%       obj.printTable(fId)
%       obj.viewTable(options)
%       log=obj.saveTable(filename)
%       res=obj.exportTable(varmode,fmt)
%       res=obj.isNumericTable
%       res=obj.isNumericColumn(idx)
%       res=obj.getColumnFormat;
%       res=obj.getColumnWidth;
%       res=obj.formatData
%       obj.setColumnValues(idx,values)
%       obj.setRowValues(idx,values)
%       res=obj.isGraph
%       obj.showGraph(name)
%       res=obj.getDescriptionLabel
% See also cTableResult, cTable
%
    properties (GetAccess=public,SetAccess=private)
        FieldNames  % Cell array with field names (optional)
        ShowNumber  % logical variable indicating if line number is printed
    end
	
    methods
        function obj=cTableCell(data,rowNames,colNames)
        % Create table with mandatory info
        %  Input:
        %   data - data values as cell array
        %   rowNames - row's names as cell array 
        %   colNames - column's  names as cell array
        %
            obj.Data=data;
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                obj.messageLog('Invalid table size (%d,%d)',size(data,1),size(data,2));
            end
        end
		
        function setProperties(obj,p)
        % Set table properties: Description, Unit, Format, FieldNames, ...
            obj.Name=p.key;
            obj.Description=p.Description;
            obj.Unit=p.Unit;
            obj.Format=p.Format;
            obj.FieldNames=p.FieldNames;
            obj.ShowNumber=p.ShowNumber;
            obj.GraphType=p.GraphType;
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function res=formatData(obj)
        % Apply format to data
            N=obj.NrOfRows;
            M=obj.NrOfCols-1;
            res=cell(N,M);
            for j=1:M
                fmt=obj.Format{j+1};
                if ismember('f',fmt)
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),obj.Data(:,j),'UniformOutput',false);
                else
                    res(:,j)=obj.Data(:,j);
                end
            end
        end

        function res=getMatlabTable(obj)
        % Return as matlab table if apply
            res=getMatlabTable@cTable(obj);
            if isMatlab
                res.Properties.VariableNames=obj.FieldNames(2:end);
                res.Properties.VariableUnits=obj.Unit(2:end);
                res.Properties.VariableDescriptions=obj.ColNames(2:end);
                res=addprop(res,["ShowNumber","Format"],["table","variable"]);
                res.Properties.CustomProperties.Format=obj.Format(2:end);
                res.Properties.CustomProperties.ShowNumber=obj.ShowNumber;
            end
        end

        function res=getStructData(obj,fmt)
        % Return table as structure
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
            res=cell2struct(val,obj.FieldNames,2);
        end

        function res=getStructTable(obj)
        % Get table as a struct
            N=obj.NrOfCols-1;
            data=obj.getStructData;
            fields(N)=struct('Name','','Format','','Unit','');
            for i=1:N
                fields(i)=struct('Name',obj.FieldNames{i+1},...
                     'Format',obj.Format{i+1},...
                     'Unit',obj.Unit{i+1});
            end
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Fields',fields,'Data',data);
        end
		
        function res=isNumericColumn(obj,j)
        % determine if the column is numeric
            res=ismember('f',obj.Format{j+1});
        end

        function setColumnWidth(obj)
        % define the width of the columns
            M=obj.NrOfCols;
            res=zeros(1,M);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=2:M
                if isNumericColumn(obj,j-1)
                    tmp=regexp(obj.Format{j},'[0-9]+','match','once');
                    res(j)=str2double(tmp);
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
            obj.wcol=res;
        end

        function printTable(obj,fId)
        % Print table on console in a pretty formatted way
            if nargin==1
                fId=1;
            end
            wcol=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            hfmt=arrayfun(@(x) ['%-',num2str(x),'s'],wcol,'UniformOutput',false);
            sfmt=hfmt;
            for j=2:obj.NrOfCols
                if fcol(j)==cType.ColumnFormat.NUMERIC
                    hfmt{j}=[' %',num2str(wcol(j)),'s'];
                    sfmt{j}=[' ',obj.Format{j}];
                end
            end
            % Determine output depending of table definition
            if obj.ShowNumber
                sfmt0=[' ',cType.FORMAT_ID,' '];
                tmp=regexp(sfmt0,'[0-9]+','match');
                hfmt0=[' %',tmp{1},'s '];
                hformat=[hfmt0, hfmt{:}];
                sformat=[sfmt0, sfmt{:}];
                header=sprintf(hformat,'Id',obj.ColNames{:});
                data=[num2cell(1:obj.NrOfRows)' obj.Values(2:end,:)];
           else
                hformat=[hfmt{:}];
                sformat=[sfmt{:}];
                header=sprintf(hformat,obj.ColNames{:});
                data=obj.Values(2:end,:);
            end
            % Print formatted table   
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',header);
            lines=cType.getLine(length(header)+1);
            fprintf(fId,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fId,sformat,data{i,:});
                fprintf(fId,'\n');
            end	
            fprintf(fId,'\n');
        end
    end
    methods(Static)
        function tbl=create(data,rowNames,colNames,param)
        % Create a cTableCell given the additional properties
        %   Input:
        %       data - Cell Array containing the data
        %       rowNames - Cell Array containing the row's names
        %       colNames - Cell Array containing the column's names
        %       param - additional properties:
        %           Name: Name of the table
        %           Description: table description
        %           Unit: cell array with the unit name of the data columns
        %           Format: cell array with the format of the data columns
        %           GraphType: type of graph asociated
        %           FieldNames: optional field name of the columns
        %           ShowNumber: true/false show column number option
        % See also cResultTableBuilder
            tbl=cTableCell(data,rowNames,colNames);
            tbl.setProperties(param);
        end

    end
end
