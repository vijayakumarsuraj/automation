# Use RubyGems.
source 'http://rubygems.org'

# Core gems - are needed always.
group :core do
  gem 'facets' # lots of useful extensions to Ruby's core classes.
  gem 'logging'
  gem 'rubyzip'

  # ORM.
  gem 'activerecord'
  gem 'activerecord-import'
  gem 'squeel'
  gem 'sqlite3'
  gem 'mysql2'
end

# Steps into each of the specified directories and attempts to load 'Gemfile'
#
# @param [String] directories
def load_gemfiles(directories)
  directories.each do |directory|
    gemfile = File.expand_path(File.join(directory, 'Gemfile'))
    eval(File.read(gemfile), binding) if File.exist?(gemfile)
  end
end

# Now go in and look for any "feature" or "application" gem files.
root_directory = File.dirname(File.realpath(__FILE__))
# First the applications.
applications_directory = File.join(root_directory, 'Applications')
FileUtils.cd(applications_directory) { load_gemfiles(Dir.glob('*')) }
# Then the features.
features_directory = File.join(root_directory, 'Features')
FileUtils.cd(features_directory) { load_gemfiles(Dir.glob('*')) }
