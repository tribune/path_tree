# path_delimiter is used for configuring the model; use nil for default
# fq_separator: separator for fully qualified name
shared_examples "a PathTree model" do |path_delimiter, fq_separator|
  # actual_delim: the generated paths will be delimited by this
  attr_reader :path_delim, :fq_sep, :actual_delim

  before :all do
    @path_delim = path_delimiter
    @fq_sep = fq_separator or raise 'fq_separator must be set'

    @actual_delim = path_delim || '.'.freeze
    if $DEBUG
      puts "OPTIONS: path_delim=#{path_delim.inspect}, fq_sep=#{fq_sep.inspect}"
    end
  end

  def delim_join(*strings)
    strings.join(actual_delim)
  end
  def fq_join(*strings)
    strings.join(fq_sep)
  end

  before :all do
    PathTree::Test.path_delimiter = path_delim if path_delim
    @root_1 = PathTree::Test.create!(:name => "Root 1")
    @parent_a = PathTree::Test.create!(:name => "Parent A", :parent_path => "root-1")
    @parent_b = PathTree::Test.create!(:name => "Parent B", :parent_path => "root-1")
    @parent_c = PathTree::Test.create!(:name => "Parent C", :parent_path => "root-1")
    @child_a1 = PathTree::Test.create!(:name => "Child A1", :parent_path => delim_join("root-1", "parent-a"))
    @child_a2 = PathTree::Test.create!(:name => "Child A2", :parent_path => delim_join("root-1", "parent-a"))
    @grandchild = PathTree::Test.create!(:name => "Grandchild A1.1", :parent_path => delim_join("root-1", "parent-a", "child-a1"))
    @root_2 = PathTree::Test.create!(:name => "Root 2")
    @parent_z = PathTree::Test.create!(:name => "Parent Z", :parent_path => "root-2")
  end

  after :all do
    PathTree::Test.delete_all
    PathTree::Test.path_delimiter = nil  # reset to default
  end

  it "reassigns the node_path when name is changed"

  it "reassigns the path when node_path is changed"

  it "should get the root nodes" do
    PathTree::Test.roots.should =~ [@root_1, @root_2]
  end

  it "should load an entire branch structure" do
    branch = PathTree::Test.branch(delim_join("root-1", "parent-a"))
    branch.should == @parent_a
    branch.instance_variable_get(:@children).should == [@child_a1, @child_a2]
    branch.children.first.instance_variable_get(:@children).should == [@grandchild]
  end

  it "should construct a fully qualified name with a delimiter" do
    @grandchild.full_name.should == "Root 1 > Parent A > Child A1 > Grandchild A1.1"
    @grandchild.full_name(:separator => fq_sep).should ==
      fq_join("Root 1", "Parent A", "Child A1", "Grandchild A1.1")
    @grandchild.full_name(:context => delim_join("root-1", "parent-a")).should == "Child A1 > Grandchild A1.1"
  end

  it "should be able to get and set a parent node" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.parent.should == @root_1
    node.parent = @root_2
    node.parent_path.should == "root-2"
    node.path.should == delim_join("root-2", "parent-a")
  end

  it "should be able to set the parent by path" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.parent_path = "root-2"
    node.parent.should == @root_2
    node.path.should == delim_join("root-2", "parent-a")
  end

  it "should have child nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.children.should == [@child_a1, @child_a2]
  end

  it "should have descendant nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.descendants.should == [@child_a1, @child_a2, @grandchild]
  end

  it "should have sibling nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.siblings.should == [@parent_b, @parent_c]
  end

  it "should have ancestor nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a", "child-a1"))
    node.ancestors.should == [@root_1, @parent_a]
  end

  it "should maintain the path with the node path" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.node_path = "New Name"
    node.path.should == delim_join("root-1", "new-name")
  end

  it "should get the expanded paths for a node" do
    @grandchild.expanded_paths.should == [
      "root-1",
      delim_join("root-1", "parent-a"),
      delim_join("root-1", "parent-a", "child-a1"),
      delim_join("root-1", "parent-a", "child-a1", "grandchild-a1-1") ]
  end

  it "should update child paths when the path is changed" do
    PathTree::Test.transaction do
      node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
      node.node_path = "New Name"
      node.save!
      node.reload
      node.children.map(&:path).should == [
        delim_join("root-1", "new-name", "child-a1"),
        delim_join("root-1", "new-name", "child-a2") ]
      node.children.first.children.map(&:path).should == [
        delim_join("root-1", "new-name", "child-a1", "grandchild-a1-1") ]
      raise ActiveRecord::Rollback
    end
  end

  it "should update child paths when a node is destroyed" do
    PathTree::Test.transaction do
      node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
      node.name = "New Name"
      node.destroy
      root = PathTree::Test.find_by_path("root-1")
      root.children.map(&:path).should == [
        delim_join("root-1", "parent-b"),
        delim_join("root-1", "parent-c"),
        delim_join("root-1", "child-a1"),
        delim_join("root-1", "child-a2") ]
      root.children[2].children.map(&:path).should == [
        delim_join("root-1", "child-a1", "grandchild-a1-1") ]
      raise ActiveRecord::Rollback
    end
  end
end
