Test Framework
==============


Requirements
------------
- Ruby 2.0 (or greater)
- DevKit
- Bundler gem
- 7-Zip
- CompareIt (optional - required for producing diffs)


Installation
------------
Setup the framework before first use (can be skipped, framework will do this automatically the first time you run) :

    ruby main.rb setup
    
Setup required features, applications and test packs. These are located in the Packages/ directory.  
Run the administrative console. Start up the 'package' command and follow prompts.

    ruby main.rb console
    $> package


Execution
---------
Get a list of supported applications :

    ruby main.rb

Get a list of supported modes :

    ruby main.rb <application>-modes

Execute a mode :

    ruby main.rb <application>-<mode> [options]
    ruby main.rb <application>-<mode> --help
