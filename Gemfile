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

  # Implementations of various algorithms (stacks, queues, rb-trees, etc...)
  gem 'algorithms'
end

# Web server gems - needed only for hosting results.
group :web do
  gem 'sinatra'
  gem 'sinatra-contrib'
  gem 'sinatra-partial'
  gem 'sinatra-flash'
  gem 'thin'
  gem 'haml'
end

# Install gems to work with MySQL databases.
group :mysql do
  gem 'mysql2'
end

# Install for web automation - will require the 'webdriver' feature.
group :watir do
  gem 'watir-webdriver'
end
