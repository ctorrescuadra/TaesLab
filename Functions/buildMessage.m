function res = buildMessage(functionName,message,varargin)  
%buildMessage - Builds a formatted error message for a given function.
%   This function constructs a standardized error message that includes 
%   the function name, and a custom message, using additional arguments.
%   The message is formatted differently based on whether the environment is
%   Octave or MATLAB.
%
%   Syntax:
%     res = buildMessage(functionName, message, varargin)
%
%   Input Arguments :
%     functionName - Name of the function (string)
%     message      - Custom error message (string)
%     varargin     - Additional arguments (cell array)
%
%   Output Arguments:
%     res          - Formatted error message (string)
%
%   Example:
%     msg = buildMessage(mfilename, cMessages.InvalidFilename, filename);
%     error(msg);
%     % returns: 'ERROR: myFunction. Invalid filename: myfile.txt'
%
%   Note: This function is used internally for error handling.
%
%   See also: cMessages, cMessageBuilder

    % Construct the error message based on the environment
    if isOctave()
        sfmt=[functionName,'. ',message];
    else %is MATLAB
        sfmt=['ERROR: ',functionName,'. ',message];  
    end
    res=sprintf(sfmt,varargin{:});
end