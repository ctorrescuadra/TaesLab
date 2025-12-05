function fdisplay(A, fmt, label)
%FDISPLAY - Display a matrix A using C-like formatting.
%   This function is useful for displaying matrices in a readable format,
%   specially when working with numerical data in a console or script.
%   The function takes a numeric matrix A and displays it using the specified
%   format string fmt, similar to C-style formatting.
%   An optional label can be provided to identify the matrix.
%   If label is not provided, the function attempts to use the variable name of A.
%   If A is empty, it displays 'label = []'. If A is a scalar, 
%   it displays 'label = value'.
%   If A is a matrix, it displays the label followed by the matrix in the 
%   specified format.
%
%   Syntax:
%     fdisplay(A)
%     fdisplay(A, fmt)
%     fdisplay(A, fmt, label)
%
%   Input Arguments:
%     A     - Numeric matrix to be displayed
%     fmt   - Format string (optional, default is '%g')
%     label - Label for the matrix (optional, default is variable name of A)
%
%   Note: This function uses zerotol to set very small values to zero for better readability.
%
%   Examples:
%     % Example 1: Display a matrix with default format
%     A = [1.23456, 2.34567; 3.45678, 4.56789];
%     fdisplay(A);
%
%     % Output:
%     A=
%     1.23456 2.34567
%     3.45678 4.56789
%
%     % Example 2: Display a matrix with specific format and label
%     A = [1.23456, 2.34567; 3.45678, 4.56789];
%     fdisplay(A, '%.2f', 'MyMatrix');
%
%     % Output:
%     MyMatrix
%     1.23 2.35
%     3.46 4.57
%
%   Example 3: Display an empty matrix
%     A = [];
%     fdisplay(A, '%.2f', 'EmptyMatrix');
%
%     % Output:
%     EmptyMatrix = []

%     Example 4: Display a scalar
%     A = 3.14159;
%     fdisplay(A, '%.2f', 'ScalarValue');
%
%     % Output:
%     ScalarValue = 3.14
% 
%   See also zerotol, fprintf

    % Check Inputs
    try 
        narginchk(2,3); 
    catch ME
        msg=buildMessage(mfilename, ME.message);
        error(msg);
    end
    if nargin < 3
        label=inputname(1); % Get the variable name
        if isempty(label)
            label='ans'; % Default label if variable name is not available
        end
    end
    % Check variables
    if ~isnumeric(A) || ~ismatrix(A)
        msg=buildMessage(mfilename, cMessages.NonNumericalMatrixError);
        error(msg);
    end
    if isempty(fmt) || ~ischar(fmt) || ~cParseStream.checkNumericFormat(fmt)
        msg=buildMessage(mfilename, cMessages.InvalidFormatError);
        error(msg);
    end
    if ~ischar(label) && ~isstring(label)
        msg=buildMessage(mfilename, cMessages.InvalidLabelError);
        error(msg);
    end
    if isempty(A)
        fprintf('%s = []\n\n', label);
        return; % Exit if A is empty
    end
    if isscalar(A)
        fprintf('%s = %s\n\n', label, num2str(A, fmt));
        return; % Exit if A is a scalar
    end
    % Display label
    if nargin==3
        fprintf('%s\n', label);
    else
        fprintf('%s=\n',label);
    end
    % Display the matrix with the specified format
    lfmt=[repmat(fmt,1,size(A,2)) '\n'];
    fprintf(lfmt,transpose(zerotol(A)));
    fprintf('\n');
end