classdef cMessageBuilder < handle
%cMessageBuilder - Create a message for logger
%   The message include the type of error, the class which cause the message and the text message
%   There is three types of messages registered
%     cType.ERROR - Error which cause the object be invalid
%     cType.WARNING - Non critical error
%     cType.INFO - Informs that an operation finished correctly
%
%   cMessageBuilder properties:
%     Error - Type of message error code
%     Class - Name of the class which generate the error
%     Text  - Text of the message
%
%   cMessageBuilder methods:
%     cMessageBuilder - Construct an instance of this class
%     getMessage      - Get the text of the message including type and class
%     disp            - Show the message on console. Overload disp
%
    properties(GetAccess=public,SetAccess=private)
        Error    % Error type
        Class    % Class cause error
        Text     % Error text
    end

    methods
        function obj = cMessageBuilder(type,class,text)
        %cMessageBuilder - Construct an instance of this class
        %   Syntax:
        %     obj = cMessageBuilder(type,class,text)
        %   Input Arguments:
        %     type - type of error
        %       cType.ERROR: error message
        %       cType.WARNING: warning message
        %       cType.INFO: info message
        %     class - class name where message is produced
        %     text  - text of the message
        %   Output Arguments:
        %     obj - cMessageBuilder object
        %
            obj.Error=type;
            obj.Class=class;
            obj.Text=text;
        end

        function text = getMessage(obj)
        %getMessage - Get the message as text
        %   Syntax:
        %     text = obj.ggetMessage
        %   Output Arguments:
        %     text - message text which appears in the logger including error type, class name and text.
        %
            text=[cType.getTextErrorCode(obj.Error),': ',obj.Class,'. ',obj.Text];              
        end

        function disp(obj)
        %disp - Overload disp function
        %   fid=1 is the standard output file id
        %   fid=2 is the error output file id (printed in red in some consoles)
        %   Syntax:
        %     disp(obj)
        %
            fid=2*(obj.Error==0)+(obj.Error~=0);
            if cType.DEBUG_MODE && (obj.Error==cType.ERROR)
                dbstack;
            end
            fprintf(fid,'%s\n',obj.getMessage);
        end
    end
end