require 'active_record'
require 'sqlite3'

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
  # simplecov not installed
end

ActiveRecord::Base.establish_connection("adapter" => "sqlite3", "database" => ":memory:")

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'path_tree'))
