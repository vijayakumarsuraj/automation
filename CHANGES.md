Test Framework
==============


General
-------
- The minimum supported version has been increased to Ruby 2.0.0. The framework will not run on any of the older versions.
- Pure Ruby support for 64-bit libraries (including COM - yay!).
- Support for CruiseControl has been dropped.
- Framework can be executed as a Windows Service.


Command-line interface
----------------------
- The '--application' and '--mode' options are gone. They have been replaced with a mandatory first argument whose format is `<application>-<mode>`.


Setup
-----
- The framework configures itself automatically with little manual intervention.
- Gems are installed to a local gem repo by the framework - so no conflicts with Ruby's global repo.


Configuration
-------------
- The .properties files (loosely based on Java's property files) have been replaced by YAML. YAML is a standardized and portable data format. Also Ruby supports it very nicely.
- Per user configuration (user.yaml).


Results
-------
- Results are served by the Sinatra based web server that is built into the framework.
- The results database can store more comprehensive run information now.


Performance
-----------
- Large parts of the framework have been re-written to allow for execution on multiple threads / processors.
- Individual tasks can be separated out and executed in parallel.
- Tasks can 'depend on' other tasks to control the order of execution. All modes support this.


Directory with spaces
---------------------
- By default, the path to the framework cannot contain any spaces. This is a restriction imposed by Ruby's native gem installation libraries (DevKit). If you still want a path with spaces, the user property 'setup.gem_path' must be changed to an absolute path that does not contain spaces.
