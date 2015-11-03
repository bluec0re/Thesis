function b = typecheck(x, varargin)
%TYPECHECK Checks whether the variable x is of the specified types
%
% [ Syntax ]
%   - typecheck(x, msg, type)
%   - typecheck(x, msg, type1, type2, ...)
%   - b = typecheck(x, type1, ...)
%
% [ Arguments ]
%   - x:        the variable to be checked
%   - msg:      the error message to be shown when x is not of valid type
%   - type:     the string indicating the expected type for x.
%               type can be a type name such as 'double', 'int8', 'struct',
%               etc, or can be a class name, or either of the following
%               \{:
%                   - numeric:    all numeric types
%                   - float:      'single' or 'double'
%                   - string:     a row vector of chars
%                   - integer:    numeric type with actual values being
%                                 integers
%                   - vector:     a 1 x n row vector or n x 1 column vector
%                   - row:        a 1 x n row vector
%                   - column:     a n x 1 column vector
%                   - scalar:     a 1 x 1 array
%                   - matrix:     a two-dimensional matrix
%                   - empty:      can be empty
%               \:}
%   - b:        the logical value indicating whether the x passes the
%               checking
%
% [ Description ]
%   - typecheck(x, msg, type) checks whether the variable x is of the
%     specified type. If not, an error will be raised.
%
%   - typecheck(x, msg, type1, type2, ...) checks whether the variable x
%     is of either one of the specified types. If not, an error will be
%     raised.
%
%   - b = typecheck(x, type1, ...) determines whether the variable x meets
%     the type constraint and returns the logical result.
%
% [ Examples ]
%   - Checks a variable with a specified type
%     \{
%        typecheck(x, 'x should be a double array', 'double')
%        % checks whether x is a double-precision value/array
%
%        typecheck(x, 'x should be of floating-point type', 'float')
%        % checks whether x is a floating-point value/array,
%        % either double or single
%
%        typecheck(x, 'x should be a vector', 'vector')
%        % checks whether x is a vector
%     \}
%
%   - Checks a variable with multiple types
%     \{
%        typecheck(x, 'numeric', 'logical')
%        % checks whether x is either a numerical or a logical value/array
%     \}
%
%   - Gets a type-checking judgment
%     \{
%        b = typecheck(1.2, 'double') => true
%        b = typecheck('abc', 'numeric') => false
%        b = typecheck({1, 2}, 'logical', 'cell') => true
%     \}
%
% [ History ]
%   - Created by Dahua Lin, on Jun 24, 2007
%

%% parse and verify input

if nargout > 0
    nargchk(2, inf, nargin);
    types = varargin;
else
    nargchk(3, inf, nargin);
    msg = varargin{1};
    types = varargin(2:end);
end

%% check

for i = 1 : length(types)
    ty = types{i};
    switch ty
        case 'empty'
            b = isempty(x);
        case 'numeric'
            b = isnumeric(x);
        case 'float'
            b = isfloat(x);
        case 'string'
            b = ischar(x) && ndims(x) == 2 && size(x, 1) == 1;
        case 'integer'
            b = isnumeric(x) && (isinteger(x) || isequal(x, fix(x)));
        case 'vector'
            b = ndims(x) == 2 && any(size(x) == 1);
        case 'row'
            b = ndims(x) == 2 && size(x, 1) == 1;
        case 'column'
            b = ndims(x) == 2 && size(x, 2) == 1;
        case 'scalar'
            b = isscalar(x);
        case 'matrix'
            b = ndims(x) == 2;
        otherwise  % for other types, use isa
            b = isa(x, ty);
    end

    if b
        return;
    end
end

% no matched type found
if nargout == 0
    error('dmtoolbox:typecheck', msg);
end
