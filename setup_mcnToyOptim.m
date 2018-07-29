function setup_mcnToyOptim()
%SETUP_MCNTOYOPTIM Sets up mcnToyOptim, by adding its folders
% to the MATLAB path
%
% Copyright (C) 2018 Samuel Albanie, Sebastien Erhardt, Joao F. Henriques
% Licensed under The MIT License [see LICENSE.md for details]

  % add dependencies
  check_dependency('autonn') ;
  check_dependency('curveball') ;

  root = fileparts(mfilename('fullpath')) ;
  addpath(root, [root '/examples'], [root '/exps'], [root '/vis']) ;

% -----------------------------------
function check_dependency(moduleName)
% -----------------------------------

  name2path = @(name) strrep(name, '-', '_') ;
  setupFunc = ['setup_', name2path(moduleName)] ;
  if exist(setupFunc, 'file')
    vl_contrib('setup', moduleName) ;
  else
    % try adding the module to the path
    addpath(fullfile(vl_rootnn, 'contrib', moduleName)) ;
    if exist(setupFunc, 'file')
      vl_contrib('setup', moduleName) ;
    else
      waiting = true ;
      msg = ['module %s was not found on the MATLAB path. Would you like ' ...
             'to install it now? (y/n)\n'] ;
      prompt = sprintf(msg, moduleName) ;
      while waiting
        str = input(prompt,'s') ;
        switch str
          case 'y'
            vl_contrib('install', moduleName) ;
            vl_contrib('compile', moduleName) ;
            vl_contrib('setup', moduleName) ;
            return ;
          case 'n'
            throw(exception) ;
          otherwise
            fprintf('input %s not recognised, please use `y` or `n`\n', str) ;
        end
      end
    end
  end
