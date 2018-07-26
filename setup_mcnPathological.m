function setup_mcnPathological()
%SETUP_MCNPATHOLOGICAL Sets up mcnPathological, by adding its folders
% to the MATLAB path
%
% Copyright (C) 2018 Samuel Albanie, Sebastien Erhardt, Joao F. Henriques
% Licensed under The MIT License [see LICENSE.md for details]

  root = fileparts(mfilename('fullpath')) ;
  addpath(root, [root '/examples'], [root '/exps']) ;
  addpath([root '/matlab'], [root '/vis']) ;
