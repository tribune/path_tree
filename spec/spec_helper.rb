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

module PathTree
  class Test < ActiveRecord::Base
    self.table_name = :test_path_trees

    def self.create_tables
      connection.create_table(table_name) do |t|
        t.string :name
        t.string :node_path
        t.string :path
        t.string :parent_path
      end unless table_exists?
    end

    def self.drop_tables
      connection.drop_table(table_name)
    end

    # lib/path_tree must be loaded before this
    include PathTree
  end
end
