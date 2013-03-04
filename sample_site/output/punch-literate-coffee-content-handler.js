(function() {
  var CoffeeScript, DefaultContentHandler, LitCoffeeHandler, compileToJs, fs, moduleUtils, parseMarkdown, path, _;

  LitCoffeeHandler = module.exports = {};

  DefaultContentHandler = require('punch').ContentHandler;

  LitCoffeeHandler.srcPath = 'src';

  moduleUtils = require('punch').Utils.Module;

  LitCoffeeHandler.setup = function(config) {
    var user_defined_path, _ref;
    if (user_defined_path = (_ref = config.litcoffee) != null ? _ref.path : void 0) {
      LitCoffeeHandler.srcPath = user_defined_path;
    }
    DefaultContentHandler.setup(config);
    return LitCoffeeHandler.markdownParser = moduleUtils.requireAndSetup(config.plugins.parsers['.markdown'], config);
  };

  fs = require('fs');

  path = require('path');

  LitCoffeeHandler.negotiateContent = function(request_path, file_extension, options, callback) {
    var file_path;
    file_path = path.join(LitCoffeeHandler.srcPath, "" + request_path + ".litcoffee");
    return fs.stat(file_path, function(err, stats) {
      var modified_date;
      if (err) {
        return DefaultContentHandler.negotiateContent(request_path, file_extension, options, callback);
      }
      modified_date = stats.mtime;
      if (file_extension === '.html') {
        return parseMarkdown(file_path, modified_date, callback);
      } else if (file_extension === '.js') {
        return compileToJs(file_path, modified_date, callback);
      } else {
        return DefaultContentHandler.negotiateContent(request_path, file_extension, options, callback);
      }
    });
  };

  LitCoffeeHandler.markdownParser = null;

  parseMarkdown = function(file_path, modified_date, callback) {
    return fs.readFile(file_path, function(err, litcoffee) {
      if (err) {
        return callback(err);
      }
      return LitCoffeeHandler.markdownParser.parse(litcoffee.toString(), function(err, parsed_output) {
        if (err) {
          return callback(err, {}, {}, modified_date);
        }
        return callback(null, {
          'content': parsed_output
        }, {}, modified_date);
      });
    });
  };

  CoffeeScript = require('coffee-script');

  compileToJs = function(file_path, modified_date, callback) {
    return fs.readFile(file_path, function(err, litcoffee) {
      var parsed_output;
      if (err) {
        return callback(err);
      }
      try {
        parsed_output = CoffeeScript.compile(litcoffee.toString(), {
          filename: file_path,
          literate: true
        }, function(err, parsed_output) {});
        return callback(null, {
          'content': parsed_output
        }, {}, modified_date);
      } catch (err) {
        return callback(err, {}, {}, modified_date);
      }
    });
  };

  _ = require('underscore');

  LitCoffeeHandler.getContentPaths = function(basepath, callback) {
    var collected_paths;
    collected_paths = [];
    return fs.readdir(path.join(process.cwd(), LitCoffeeHandler.srcPath), function(err, files) {
      _.each(files, function(file) {
        var basename;
        if (file.indexOf('.litcoffee' > 0)) {
          basename = file.split('.').shift();
          collected_paths.push("" + basename + ".html");
          return collected_paths.push("" + basename + ".js");
        }
      });
      return callback(null, collected_paths);
    });
  };

  LitCoffeeHandler.isSection = function(basepath) {
    return DefaultContentHandler.isSection(basepath);
  };

  LitCoffeeHandler.getSections = function(callback) {
    return DefaultContentHandler.getSections(callback);
  };

}).call(this);

