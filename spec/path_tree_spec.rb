# encoding: UTF-8

require 'spec_helper'

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
    before :all do
      @root_1 = PathTree::Test.create!(:name => "Root 1")
      @parent_a = PathTree::Test.create!(:name => "Parent A", :parent_path => "root-1")
      @parent_b = PathTree::Test.create!(:name => "Parent B", :parent_path => "root-1")
      @parent_c = PathTree::Test.create!(:name => "Parent C", :parent_path => "root-1")
      @child_a1 = PathTree::Test.create!(:name => "Child A1", :parent_path => "root-1.parent-a")
      @child_a2 = PathTree::Test.create!(:name => "Child A2", :parent_path => "root-1.parent-a")
      @grandchild = PathTree::Test.create!(:name => "Grandchild A1.1", :parent_path => "root-1.parent-a.child-a1")
      @root_2 = PathTree::Test.create!(:name => "Root 2")
      @parent_z = PathTree::Test.create!(:name => "Parent Z", :parent_path => "root-2")
    end

    after :all do
      PathTree::Test.delete_all
    end

    it "updates the node_path when name is changed"

    it "updates the path when node_path is changed"

    it "should get the root nodes" do
      PathTree::Test.roots.sort{|a,b| a.path <=> b.path}.should == [@root_1, @root_2]
    end

    it "should load an entire branch structure" do
      branch = PathTree::Test.branch("root-1.parent-a")
      branch.should == @parent_a
      branch.instance_variable_get(:@children).should == [@child_a1, @child_a2]
      branch.children.first.instance_variable_get(:@children).should == [@grandchild]
    end

    it "should construct a fully qualified name with a delimiter" do
      @grandchild.full_name.should == "Root 1 > Parent A > Child A1 > Grandchild A1.1"
      @grandchild.full_name(:separator => "/").should == "Root 1/Parent A/Child A1/Grandchild A1.1"
      @grandchild.full_name(:context => "root-1.parent-a").should == "Child A1 > Grandchild A1.1"
    end

    it "should be able to get and set a parent node" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.parent.should == @root_1
      node.parent = @root_2
      node.parent_path.should == "root-2"
      node.path.should == "root-2.parent-a"
    end

    it "should be able to set the parent by path" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.parent_path = "root-2"
      node.parent.should == @root_2
      node.path.should == "root-2.parent-a"
    end

    it "should have child nodes" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.children.should == [@child_a1, @child_a2]
    end

    it "should have descendant nodes" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.descendants.should == [@child_a1, @child_a2, @grandchild]
    end

    it "should have sibling nodes" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.siblings.should == [@parent_b, @parent_c]
    end

    it "should have ancestor nodes" do
      node = PathTree::Test.find_by_path("root-1.parent-a.child-a1")
      node.ancestors.should == [@root_1, @parent_a]
    end

    it "should maintain the path with the node path" do
      node = PathTree::Test.find_by_path("root-1.parent-a")
      node.node_path = "New Name"
      node.path.should == "root-1.new-name"
    end

    it "should get the expanded paths for a node" do
      @grandchild.expanded_paths.should == ["root-1", "root-1.parent-a", "root-1.parent-a.child-a1", "root-1.parent-a.child-a1.grandchild-a1-1"]
    end

    it "should update child paths when the path is changed" do
      PathTree::Test.transaction do
        node = PathTree::Test.find_by_path("root-1.parent-a")
        node.node_path = "New Name"
        node.save!
        node.reload
        node.children.collect{|c| c.path}.should == ["root-1.new-name.child-a1", "root-1.new-name.child-a2"]
        node.children.first.children.collect{|c| c.path}.should == ["root-1.new-name.child-a1.grandchild-a1-1"]
        raise ActiveRecord::Rollback
      end
    end

    it "should update child paths when a node is destroyed" do
      PathTree::Test.transaction do
        node = PathTree::Test.find_by_path("root-1.parent-a")
        node.name = "New Name"
        node.destroy
        root = PathTree::Test.find_by_path("root-1")
        root.children.collect{|c| c.path}.should == ["root-1.parent-b", "root-1.parent-c", "root-1.child-a1", "root-1.child-a2"]
        root.children[2].children.collect{|c| c.path}.should == ["root-1.child-a1.grandchild-a1-1"]
        raise ActiveRecord::Rollback
      end
    end
  end

  
  # TODO can we use shared examples to avoid duplication?
  context "with custom delimiter" do
    before :all do
      PathTree::Test.path_delimiter = '/'
      @root_1 = PathTree::Test.create!(:name => "Root 1")
      @parent_a = PathTree::Test.create!(:name => "Parent A", :parent_path => "root-1")
      @parent_b = PathTree::Test.create!(:name => "Parent B", :parent_path => "root-1")
      @parent_c = PathTree::Test.create!(:name => "Parent C", :parent_path => "root-1")
      @child_a1 = PathTree::Test.create!(:name => "Child A1", :parent_path => "root-1/parent-a")
      @child_a2 = PathTree::Test.create!(:name => "Child A2", :parent_path => "root-1/parent-a")
      @grandchild = PathTree::Test.create!(:name => "Grandchild A1.1", :parent_path => "root-1/parent-a/child-a1")
      @root_2 = PathTree::Test.create!(:name => "Root 2")
      @parent_z = PathTree::Test.create!(:name => "Parent Z", :parent_path => "root-2")
    end

    after :all do
      PathTree::Test.path_delimiter = nil
    end

    it "updates the node_path when name is changed"

    it "updates the path when node_path is changed"

    it "should get the root nodes" do
      PathTree::Test.roots.sort{|a,b| a.path <=> b.path}.should == [@root_1, @root_2]
    end

    it "should load an entire branch structure" do
      branch = PathTree::Test.branch("root-1/parent-a")
      branch.should == @parent_a
      branch.instance_variable_get(:@children).should == [@child_a1, @child_a2]
      branch.children.first.instance_variable_get(:@children).should == [@grandchild]
    end

    it "should construct a fully qualified name with a delimiter" do
      @grandchild.full_name.should == "Root 1 > Parent A > Child A1 > Grandchild A1.1"
      @grandchild.full_name(:separator => ":").should == "Root 1:Parent A:Child A1:Grandchild A1.1"
      @grandchild.full_name(:context => "root-1/parent-a").should == "Child A1 > Grandchild A1.1"
    end

    it "should be able to get and set a parent node" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.parent.should == @root_1
      node.parent = @root_2
      node.parent_path.should == "root-2"
      node.path.should == "root-2/parent-a"
    end

    it "should be able to set the parent by path" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.parent_path = "root-2"
      node.parent.should == @root_2
      node.path.should == "root-2/parent-a"
    end

    it "should have child nodes" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.children.should == [@child_a1, @child_a2]
    end

    it "should have descendant nodes" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.descendants.should == [@child_a1, @child_a2, @grandchild]
    end

    it "should have sibling nodes" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.siblings.should == [@parent_b, @parent_c]
    end

    it "should have ancestor nodes" do
      node = PathTree::Test.find_by_path("root-1/parent-a/child-a1")
      node.ancestors.should == [@root_1, @parent_a]
    end

    it "should maintain the path with the node path" do
      node = PathTree::Test.find_by_path("root-1/parent-a")
      node.node_path = "New Name"
      node.path.should == "root-1/new-name"
    end

    it "should get the expanded paths for a node" do
      @grandchild.expanded_paths.should == ["root-1", "root-1/parent-a", "root-1/parent-a/child-a1", "root-1/parent-a/child-a1/grandchild-a1-1"]
    end

    it "should update child paths when the path is changed" do
      PathTree::Test.transaction do
        node = PathTree::Test.find_by_path("root-1/parent-a")
        node.node_path = "New Name"
        node.save!
        node.reload
        node.children.collect{|c| c.path}.should == ["root-1/new-name/child-a1", "root-1/new-name/child-a2"]
        node.children.first.children.collect{|c| c.path}.should == ["root-1/new-name/child-a1/grandchild-a1-1"]
        raise ActiveRecord::Rollback
      end
    end

    it "should update child paths when a node is destroyed" do
      begin
        PathTree::Test.transaction do
          node = PathTree::Test.find_by_path("root-1/parent-a")
          node.name = "New Name"
          node.destroy
          root = PathTree::Test.find_by_path("root-1")
          root.children.collect{|c| c.path}.should == ["root-1/parent-b", "root-1/parent-c", "root-1/child-a1", "root-1/child-a2"]
          root.children[2].children.collect{|c| c.path}.should == ["root-1/child-a1/grandchild-a1-1"]
          raise ActiveRecord::Rollback
        end
      rescue
        puts $@.join("\n")
      end
    end
  end
end
