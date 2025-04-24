function fdisplay(A,fmt,label)
%fdisplay - Display a matrix A using C-like fmt
%   An optional text label could be used, if not variable name is used
%
%   Syntax
%       fdisplay(A, fmt)
%
%   Input Arguments
%       A - matrix
%     fmt - C-like format string
%     label - Header text (optional)
%
    if nargin==2
        label=inputname(1);    
        if isempty(label)
            label='ans';
        end
        fprintf('%s =\n',label);
    else
        fprintf('%s\n',label);
    end
    lfmt=[repmat(fmt,1,size(A,2)) '\n'];
    fprintf(lfmt,transpose(A));
    fprintf('\n');
end