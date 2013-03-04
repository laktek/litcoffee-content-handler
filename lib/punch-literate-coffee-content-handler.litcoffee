# Literate Coffee Content Handler for Punch

## What is Literate Programming?

Literate Programming is a way to construct your programs similar to the way you write any other prose, following your train of thoughts. Instead of jumping directly to the mechanical process of coding, you structure your program as a human readable document. The implementations of the ideas are done alongside the description. 

Concept of Literate programming was first introduced by Donald Knuth in 1970s as an alternative to structured programming. Recently, this technique was resurfaced with the introduction of "Literate CoffeeScript" mode introduced in CoffeeScript 1.5.

## How I do Literate Programming?

As you could see this program is done using the Literate Programming. Here's how my flow looked like.

* Start with a blank paper.
* Use [Distraction-free mode in Vim](http://www.laktek.com/2012/09/05/distraction-free-writing-with-vim/).
* Type whatever comes to your mind, be it prose or code.
* Use markdown formatting to structure the document. Code blocks needs to indent with 4-spaces.
* Write as you would explain it to a friend sitting next to you (imaginery pair-programming)
* CoffeeScript's syntax compliments to this type of programming. No commas, no brackets, short functions, variable scoping.

## What's this project? 

		LitCoffeeHandler = module.exports = {}

This is a custom content handler for Punch, to handle Literate CoffeeScript. It will produce human readable HTML pages from the markdown and machine executable JS from the coffeeScript code blocks.

This could be useful for:
* Generating documentation for your library
* To write code tutorials (automatically provide the source)

This works on top of Punch's default content handler. The content requests, that cannot be handled by this will be delegated to default content handler.

		DefaultContentHandler = require('punch').ContentHandler

## Setup

By convention, we expect the source files (`litcoffee` files) of a project to be found in the `src` path.

		LitCoffeeHandler.srcPath = 'src'

Punch calls the `setup` function of each configured plugin at the start, along with [project's configuration](https://github.com/laktek/punch/wiki/Configuration-Options). We can allow users to override the default path by providing a custom path in project's config.

		moduleUtils = require('punch').Utils.Module

		LitCoffeeHandler.setup = (config) ->
			if user_defined_path = config.litcoffee?.path
				LitCoffeeHandler.srcPath = user_defined_path 

We need to delegate certain functions to `DefaultContentHandler`, so let's setup it as well.

			DefaultContentHandler.setup config

Let's setup the markdown parser, based on what has been configured.

			LitCoffeeHandler.markdownParser = moduleUtils.requireAndSetup config.plugins.parsers['.markdown'], config

## Negotiating Content

Punch's page renderer will call `negotiateContent` function when user requests content. We shall check if we can serve the content. 

		fs = require 'fs'
		path = require 'path'

		LitCoffeeHandler.negotiateContent = (request_path, file_extension, options, callback) -> 
			file_path = path.join(LitCoffeeHandler.srcPath, "#{request_path}.litcoffee") 
			fs.stat file_path, (err, stats) -> 

If no file found, we'll delegate the handling to the `DefaultContentHandler`. 

				if err
					return DefaultContentHandler.negotiateContent(request_path, file_extension, options, callback)

Get the file's modified date from the stats.
	
				modified_date = stats.mtime

If there's a matching `litcoffee` file available in path, then we have to decide what to do with it based on user's request. 
* If the user requests for a HTML page, we'll parse the markdown. 
* If she requests for JS, we'll compile it using CoffeeScript compiler. 
* If the requested type is not something we can handle, again we'll delegate it to `DefaultContentHandler`.

				if file_extension == '.html'
					parseMarkdown file_path, modified_date, callback
				else if file_extension == '.js'
					compileToJs file_path, modified_date, callback
				else
					DefaultContentHandler.negotiateContent(request_path, file_extension, options, callback)

## Parse Markdown

To parse the markdown file, we should use the configured markdown parser. Result should be presented as a JSON object. The parsed content will be assigned to a key named `content`. This is what should be used in the templates to render the parsed content.

		LitCoffeeHandler.markdownParser = null

		parseMarkdown = (file_path, modified_date, callback) ->
			fs.readFile file_path, (err, litcoffee) ->
				if err
					return callback(err)

				LitCoffeeHandler.markdownParser.parse litcoffee.toString(), (err, parsed_output) ->
					if err
						return callback err, {}, {}, modified_date

					callback null, { 'content': parsed_output }, {}, modified_date

## Compile to JS

To compile LiterateCoffee files, we should get the configured CoffeeScript compiler. Similar to parsed markdown content, this will also be presented in a JSON object (with output assigned to a key named `content`). To serve this as a JS file, user should create a mustache template with the tag `{{{content}}}` (named `_layout.js.mustache`).

		CoffeeScript = require('coffee-script')
		
		compileToJs = (file_path, modified_date, callback) ->
			fs.readFile file_path, (err, litcoffee) ->
				if err
					return callback(err)

				try
					parsed_output = CoffeeScript.compile litcoffee.toString(), { filename: file_path, literate: true }, (err, parsed_output) ->
					callback null, { 'content': parsed_output }, {}, modified_date
				catch err
					return callback err, {}, {}, modified_date

## Get Content Paths

Punch uses `getContentPaths` functions to identify all available pages for it to generate. We traverse the source directory and create an array containing the paths of the `litcoffee` files. We ignore any hidden files or directories.

		_ = require('underscore')

		LitCoffeeHandler.getContentPaths = (basepath, callback) ->
			collected_paths = []

			fs.readdir path.join(process.cwd(), LitCoffeeHandler.srcPath), (err, files) ->
				_.each files, (file) ->
					if file.indexOf '.litcoffee' > 0
						basename = file.split('.').shift()
						collected_paths.push "#{basename}.html"
						collected_paths.push "#{basename}.js"
				
				callback null, collected_paths

## Is Section?

Punch calls `isSection` to check if there's an implicit index page to be rendered for the given path. We're leaving the section handling to the default content handler.

		LitCoffeeHandler.isSection = (basepath) ->
			DefaultContentHandler.isSection(basepath)

## Get Sections 

Punch calls `getSections` to get all available sections under content. Since we don't handle sections let's delegate that also to default content handler.

		LitCoffeeHandler.getSections = (callback) ->
			DefaultContentHandler.getSections(callback)

## Inspiration

* [Journo & Literate CoffeeScript](http://ashkenas.com/literate-coffeescript/)
* [Codd - building immutable SQL queries from relational primitives](https://gist.github.com/grncdr/5039898)
* [TOML parser for JavaScript](https://github.com/JonAbrams/tomljs/blob/master/toml.litcoffee)

## Further Reading

* [Literate Programming on Wikipedia](http://en.wikipedia.org/wiki/Literate_programming)
