function fdisplay(A,fmt,label)
%fdisplay - Display a matrix A using C-like fmt.
%   This function is useful for displaying matrices in a readable format,
%   especially when working with numerical data in a console or script.
%
%   Syntax
%       fdisplay(A, fmt, label)
%
%   Input Arguments
%    A     - numeric matrix, or scalar to display
%    fmt   - C-like format string
%    label - Header text (optional)
%       If not provided, the variable name is used.
%   
%   Output Arguments
%       Prints the matrix A to the console in a formatted way.
%
%   Example
%       A = [1.234567 2.345678; 3.456789 4.567890];
%       fmt = '%.2f';
%       label = 'My Matrix';
%     fdisplay(A, fmt, label); %returns:
%       My Matrix
%        1.23 2.35
%        3.46 4.57
%     fdisplay(A, fmt); %returns:
%        A =  
%        1.23 2.35 
%        3.46 4.57
%
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
        error('ERROR: fdisplay. Input must be a numeric matrix.');
    end
    if isempty(fmt)
        fmt='%g'; % Default format if empty
    end
    if ~ischar(fmt) 
        error('ERROR: fdisplay. Format must be a character array.');
    end
    if ~ischar(label) && ~isstring(label)
        error('ERROR: fdisplay. Label must be a character array.');
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