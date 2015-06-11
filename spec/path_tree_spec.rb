# encoding: UTF-8

require 'spec_helper'
require 'shared/path_tree_model_examples'

describe PathTree do
  
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
      
      include PathTree
    end
  end

  before :all do
    PathTree::Test.create_tables
  end

  after :all do
    PathTree::Test.drop_tables
  end

  context "validations" do
    it "is invalid without a name"
    it "is invalid without a node_path"
    it "is invalid without a path"

    it "enforces unique path"

    it "enforces unique node_path under a parent"
    it "allows duplicate node_path under different parents"
  end
  
  context "path construction" do
    it "should turn accented characters into ascii equivalents" do
      PathTree::Test.asciify("ÀÂÄÃÅàâáããä-ÈÊÉËèêéë-ÌÎÍÏìîíï-ÒÔÖØÓÕòôöøóõ-ÚÜÙÛúüùû-ÝýÿÑñÇçÆæßÐ").should == "AAAAAaaaaaa-EEEEeeee-IIIIiiii-OOOOOOoooooo-UUUUuuuu-YyyNnCcAEaessD"
    end

    it "should unquote strings" do
      PathTree::Test.unquote(%Q("This is a 'test'")).should == "This is a test"
    end

    it "should translate a value to a path part" do
      PathTree::Test.pathify("This is the 1st / test À...").should == "this-is-the-1st-test-a"
    end

    # TODO move this inside delimiter contexts
    it "should expand a path to its component paths" do
      PathTree::Test.expanded_paths("this.is.a.test").should == ["this", "this.is", "this.is.a", "this.is.a.test"]
    end
    
    it "should set the parent path when setting the parent" do
      parent = PathTree::Test.new(:name => "parent")
      node = PathTree::Test.new(:name => "child")
      node.parent = parent
      node.parent_path.should == "parent"
      node.parent = nil
      node.parent_path.should == nil
    end
  end

  context "with default delimiter" do
    it_behaves_like "a PathTree model", nil, '/'
  end

  context "with custom delimiter" do
    it_behaves_like "a PathTree model", '/', ':'
  end
end
