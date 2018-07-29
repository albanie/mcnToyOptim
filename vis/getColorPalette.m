function colors = getColorPalette()
%GETCOLORPALETTE - select some nice colors for the graphs
%   COLORS = GETCOLORPALETTE returns a cell array of lovingly
%   selected colors for plotting purposes.
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  % some useful colours
  gold = [0.854902 0.647059 0.12549] ;
  olive = [ 125 ; 168 ; 50 ] / 255 ;
  teal = [0 ; 139 ; 139] / 255 ;

  colors = {gold, olive, teal, 'red', 'blue', 'magenta', 'black', 'yellow'} ;
