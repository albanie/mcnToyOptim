function val = parseArg(x, key)
%PARSEARG - A simple key-value argument parser
%   VAL = PARSEARG(X, KEY) parses the value associated with KEY
%   in X, a cell array of key-value pairs.
%
%   Example:
%     X = {'key1', 'value1', 'key2', 'value2'} ;
%     parseArg(X, 'key2') ; # returns 'value2'
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  % sanity check on cell array of key-value pairs
  assert(mod(numel(x), 2) == 0, 'expected key-value pairs') ;
  pos = find(strcmp(x, key), 1) ;
  assert(~isempty(pos), sprintf('could not find key: %s', key)) ;
  val = x{pos+1} ;
end
