classdef cResultSet < cStatusLogger
% cResultSet is the base class for result classes
%   It implements the cResultInfo methods
%   object of the class derived from it.
% Methods:
%   res=obj.getResultInfo
%   obj.printResults
%   obj.showResults(name,options)
%   res=obj.getTable(name,options)
%   res=obj.getTableIndex(options)
%   obj.showTableIndex(options)
%   obj.showGraph(name,options)
%   obj.saveResults(filename)
%   obj.saveTable(name,filename)
%
% See also cResultInfo, cThermoeconomicModel, cDataModel
    properties(Access=protected)
        classId  % Class Id (see cType.ClassId)
    end

    methods
        function obj = cResultSet(id)
        % cResultSet Construct an instance of this class
        %   Define the class identifier
            obj=obj@cStatusLogger(cType.VALID);
            obj.classId=id;
        end

        function res = getClassId(obj)
        % Get the class identifier
        %   Detailed explanation goes here
            res = obj.classId;
        end

        function res = getResultInfo(obj)
        % Get the associated result info
            res=[];
            switch obj.classId
            case cType.ClassId.RESULT_MODEL
                res=obj.resultModelInfo;
            case cType.ClassId.DATA_MODEL
                res=obj.ModelInfo;
            case cType.ClassId.RESULT_INFO
                res=obj;
            end
        end
        %%%
        % Result Set functions.
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
        function showGraph(obj,varargin)
        % Show the graph
        % See also cResultInfo/showGraph
            res=getResultInfo(obj);
            showGraph(res,varargin{:});
        end
        function log=saveResults(obj,varargin)
        % Save the results set
        % See also cResultInfo/saveResults
            res=getResultInfo(obj);
            log=saveResults(res,varargin{:});
        end
        function log=saveTable(obj,varargin)
        % Save a table of the result set
        % See also cResultInfo/saveTable
            res=getResultInfo(obj);
            log=saveTable(res,varargin{:});
        end
    end
end