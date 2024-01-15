classdef (Abstract) cTableResult < cTable
% cTableResult Abstrat class to store ExIOLab results into a cTable
%   Methods:
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
% See also cTable, cTableMatrix, cTableCell
%
    properties (GetAccess=public, SetAccess=protected)
        Format    % Format of the table cells
        Unit      % Units of the table cell
    end
    methods      
        function res=exportTable(obj,varmode,fmt)
        % get cTable info in diferent types of variables
            if nargin==1
                fmt=false;
            end
            switch varmode
                case cType.VarMode.CELL
                    res=obj.getCellData(fmt);
                case cType.VarMode.STRUCT
                    res=obj.getStructData(fmt);
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

        function res=getCellData(obj,fmt)
        % Get table as cell array
        %  Input:
        %   fmt - (true/false) indicate is the numerical values of the table must be formatted
        %  Output
        %   res - cell array with the table values
            if nargin==1
                fmt=false;
            end
            if fmt
                res=[obj.ColNames;[obj.RowNames',obj.formatData]];
            else    
                res=obj.Values;
            end
        end

        function showGraph(obj, varargin)
        % Show table values as graph
        %  Input:
        %   varargin - Options depending on graph type. 
        %  See cResultInfo/showGraph
        %
            g=cGraphResults(obj, varargin{:});
            if ~isValid(g)
                g.printLogger;
                g.printError('Invalid graph parameters. See error log.');
                return
            end
            g.showGraph;
        end
    end
end
