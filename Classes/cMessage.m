classdef cMessage < cTaesLab
% cMessage -  create a message
%   The message include the type of error, the class which cause the message and the text message
%   There is three types of messages registered
%     cType.ERROR - Error which cause the object be invalid
%     cType.WARNING - Non critical error
%     cType.INFO - Informs that an operation finished correctly
%
% cMessage Properties
%   Error - Type of message error code
%   Class - Name of the class which generate the error
%   Text  - Text of the message
%
% cMessage Methods:
%   getMessage - get the text of the message including type and class
%   disp - show the message on console. Overload disp
%
    properties(GetAccess=public,SetAccess=private)
        Error    % Error type
        Class    % Class cause error
        Text     % Error text
    end

    methods
        function obj = cMessage(type,class,text)
        %Construct an instance of this class
            obj.Error=type;
            obj.Class=class;
            obj.Text=text;
        end

        function text = getMessage(obj)
        % Get the message as text   
            text=[cType.getTextErrorCode(obj.Error),': ',obj.Class,'. ',obj.Text];              
        end

        function disp(obj)
        % Overload disp function
        %   fid=1 is the standard output file id
        %   fid=2 is the error output file id
            fid=2*(obj.Error<=0)+(obj.Error>0);
            fprintf(fid,'%s\n',obj.getMessage);
        end
    end
end