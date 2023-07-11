classdef cResultId < cStatusLogger
% cResultId base class to define the ResultId of the classes which provide results
% 	It is used in: cProductiveStructure, cExergyModel, cModelFPR, cDiagnosis, 
%	cRecyclingAnalysis, cDiagramFP, cWasteData
%
	properties(GetAccess=public,SetAccess=protected)
		ResultId=cType.ResultId.DATA_MODEL % Result Id
		ResultName % Result Name
    end
    properties(Access=protected)
		objectId    % class object identifier
	end

	methods
		function obj = cResultId(id)
        % Class constructor
			obj=obj@cStatusLogger();
            obj.objectId=randi(intmax,"int32");
			if (nargin==1) &&isscalar(id) && isnumeric(id)
				N=length(cType.Results);
				if any (id==1:N)
					obj.ResultId=id;
				end
			end
        end
        function res=get.ResultName(obj)
        % get the result name 
            res=cType.Results{obj.ResultId};
        end
        
        function res=eq(obj1,obj2)
        % Check if two class object are equal. Overload eq operator
            res=(obj1.objectId==obj2.objectId);
        end
        
        function res=ne(obj1,obj2)
        % Check if two class objects are different. Overload ne operator
            res=(obj1.objectId~=obj2.objectId);
		end
	end
end