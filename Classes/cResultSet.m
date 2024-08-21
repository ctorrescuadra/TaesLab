classdef cResultSet < cStatusLogger
% cResultSet is the base class for result classes
%   It implements the cResultInfo methods
%   object of the class derived from it.
% Methods:
%   res=obj.getResultInfo
%   obj.printResults
%   obj.showResults(name,options)
%   res=obj.getTable(name,table)
%   res=obj.getTableIndex(options)
%   obj.showTableIndex(options)
%   obj.showGraph(name,options)
%   log=obj.saveResults(filename)
%   res=obj.exportResults(options)
%   log=obj.saveTable(name,filename)
%   res=obj.exportTable(name,options)
%
% See also cResultInfo, cThermoeconomicModel, cDataModel
    properties(Access=public)
        classId  % Class Id (see cType.ClassId)
    end

    methods
        function obj = cResultSet(id)
        % cResultSet Construct an instance of this class
        %   Define the class identifier
            obj=obj@cStatusLogger();
            obj.classId=id;
        end

        function res=getResultInfo(obj)
        % getResultInfo - get cResultInfo object from cResultSet
        %   Default method class
            res=obj;
        end
        
        %%%
        % Result Set functions.
        %%%
        function res=ListOfTables(obj)
        % Get the list of tables as cell array
            res={};
            tmp=getResultInfo(obj);
            if isValid(tmp)
                res=fieldnames(tmp.Tables);
            end
        end

        function log=saveTable(obj,tname,filename)
        % saveTable save the table name in a file depending extension
        %   Usage:
        %     obj.saveTable(tname, filename)
        %   Input:
        %     tname - name of the table
        %     filename - name of the file with extension
        %
            log=cStatusLogger();
            if nargin < 3
                log.messageLog(cType.ERROR,'Invalid input parameters');
                return
            end
            tbl=obj.getTable(tname);
            if isValid(tbl)
                log=saveTable(tbl,filename);
            else
                log.messageLog(cType.ERROR,'Table %s does NOT exists',tname);
            end
        end

        function res=exportTable(obj,tname,varargin)
        % exportTable export tname into the selected varmode/format
        %   Usage:
        %     obj.exportTable(tname,options)
        %   Input:
        %     tname - name of the table
        %     options - optional parameters
        %       varmode - result type
        %         cType.VarMode.NONE: cTable object (default)
        %         cType.VarMode.CELL: cell array
        %         cType.VarMode.STRUCT: structured array
        %         cType.VarModel.TABLE: Matlab table
        %       fmt - Format values (false/true)
        %
            res=cStatusLogger();
            if nargin < 2
                res.messageLog(cType.ERROR,'Invalid number of arguments')
                return
            end
            tbl=obj.getTable(tname);
            if isValid(tbl)
                res=exportTable(tbl,varargin{:});
            else
                res.messageLog(cType.ERROR,'Table %s does NOT exists',tname);
            end
        end

        %%%
        %  Methods implemented in cResultInfo
        %%%
        function printResults(obj)
        % Print the result set
        % See also cResultInfo/printResults
            res=getResultInfo(obj);
            printResults(res);
        end

        function showResults(obj,varargin)
        % Show the result set 
        % See also cResultInfo/showResults
            res=getResultInfo(obj);
            showResults(res,varargin{:});
        end

        function showGraph(obj,varargin)
        % Show result set graphs
        % See also cResultInfo/showGraph
            res=getResultInfo(obj);
            showGraph(res,varargin{:});
        end

        function tbl=getTable(obj,varargin)
        % Get the table info
        % See also cResultInfo/getTable
            res=getResultInfo(obj);
            tbl=getTable(res,varargin{:});
        end

        function tbl=getTableIndex(obj,varargin)
        % Get the table index info
        % See also cResultInfo/getTableIndex
            res=getResultInfo(obj);
            tbl=getTableIndex(res,varargin{:});
        end

        function showTableIndex(obj,varargin)
        % Show the table index
        % See also cResultInfo/getTableIndex
            res=getResultInfo(obj);
            showTableIndex(res,varargin{:});
        end

        function log=saveResults(obj,varargin)
        % Save the results set
        % See also cResultInfo/saveResults
            res=getResultInfo(obj);
            log=saveResults(res,varargin{:});
        end

        function res=exportResults(obj,varargin)
        % Get the tables of a result set in diferent formats
        % See also cResultInfo/exportTable
            tmp=getResultInfo(obj);
            res=exportResults(tmp,varargin{:});
        end
    end
end