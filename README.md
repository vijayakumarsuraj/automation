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
    
Setup required features. These are located in the Packages/Features directory.
Run the administrative console. Start up the 'package' command and follow prompts.

    run console
    $> package


Execution
---------
Get a list of supported applications :

    run

Get a list of supported modes :

    run <application>-modes

Execute a mode :

    run <application>-<mode> [options]
    run <application>-<mode> --help
