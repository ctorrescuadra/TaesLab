function fdisplay(A, fmt, label)
%FDISPLAY - Display a matrix A using C-like formatting.
%   This function is useful for displaying matrices in a readable format,
%   specially when working with numerical data in a console or script.
%   The function takes a numeric matrix A and displays it using the specified
%   format string fmt, similar to C-style formatting. If fmt is not provided,
%   it defaults to '%g'. An optional label can be provided to identify the matrix.
%   If label is not provided, the function attempts to use the variable name of A.
%   If A is empty, it displays 'label = []'. If A is a scalar, 
%   it displays 'label = value'.
%   If A is a matrix, it displays the label followed by the matrix in the 
%   specified format.
%
%   Syntax:
%     FDISPLAY(A)
%     FDISPLAY(A, fmt)
%     FDISPLAY(A, fmt, label)
%
%   Input Arguments:
%     A     - Numeric matrix to be displayed
%     fmt   - Format string (optional, default is '%g')
%     label - Label for the matrix (optional, default is variable name of A)
%
%   Note: This function uses zerotol to set very small values to zero for better readability.
%
%   See also zerotol, fprintf

    % Check Inputs   
    if nargin < 2
        fmt='%g'; % Default format
    end
    if nargin < 3
        label=inputname(1); % Get the variable name
        if isempty(label)
            label='ans'; % Default label if variable name is not available
        end
    end
    % Check variables
    if ~isnumeric(A) || ~ismatrix(A)
        error('ERROR: %s. Input must be a numeric matrix.', mfilename);
    end
    if isempty(fmt)
        fmt='%g'; % Default format if empty
    end
    if ~ischar(fmt) 
        error('ERROR: %s. Format must be a character array.', mfilename);
    end
    if ~ischar(label) && ~isstring(label)
        error('ERROR: %s. Label must be a character array.', mfilename);
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