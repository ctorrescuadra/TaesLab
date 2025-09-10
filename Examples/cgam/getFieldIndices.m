function idx = getFieldIndices(mapStruct, fields)
%GETFIELDINDICES Devuelve los índices asociados a nombres de campo
%   idx = GETFIELDINDICES(mapStruct, fields)
%   mapStruct : struct con pares (nombre → índice)
%   fields    : cell array de nombres de campo
%   idx       : vector con los índices correspondientes

    % Nombres disponibles en el struct
    sKeys = fieldnames(mapStruct);

    % Comprobar que todos los campos pedidos existen
    tf = ismember(fields, sKeys);
    if ~all(tf)
        missing = fields(~tf);
        error('getFieldIndices:UnknownField', ...
              'Los siguientes campos no existen en la estructura: %s', ...
              strjoin(missing, ', '));
    end

    % Extraer valores de forma vectorizada
    idx = cellfun(@(f) mapStruct.(f), fields);
end
