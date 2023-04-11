classdef cMessageLog < handle
% cMessageLog define the logger messages as class
%   Methods:
%       obj=cMessageLog(error,class,text)
%       text=obj.getMessage;
%
    properties(GetAccess=public,SetAccess=private)
        Error    % Error type
        Class    % Class cause error
        Text     % Error text
    end

    methods
        function obj = cMessageLog(error,class,text)
        %Construct an instance of this class
            obj.Error=error;
            obj.Class=class;
            obj.Text=text;
        end

        function text = getMessage(obj)
        % Get the message as text   
            text=[cType.getTextErrorCode(obj.Error),': ',obj.Class,'. ',obj.Text];              
        end

        function disp(obj)
        % Overload disp function
            fprintf('%s\n',obj.getMessage);
        end
    end
end