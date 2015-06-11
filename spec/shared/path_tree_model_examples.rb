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

  let(:unsaved_rec) { PathTree::Test.new(name: 'level-2', parent: @root_1) }

  it "gets the root nodes" do
    expect(PathTree::Test.roots).to match_array [@root_1, @root_2]
  end

  it "loads an entire branch structure" do
    branch = PathTree::Test.branch(delim_join("root-1", "parent-a"))
    expect(branch).to eq @parent_a
    expect(branch.instance_variable_get(:@children)).to eq [@child_a1, @child_a2]
    expect(branch.children.first.instance_variable_get(:@children)).to eq [@grandchild]
  end

  it "constructs a fully qualified name with a delimiter" do
    expect(@grandchild.full_name).to eq "Root 1 > Parent A > Child A1 > Grandchild A1.1"
    expect(@grandchild.full_name(:separator => fq_sep)).to eq(
      fq_join("Root 1", "Parent A", "Child A1", "Grandchild A1.1") )
    expect(@grandchild.full_name(:context => delim_join("root-1", "parent-a"))).to eq "Child A1 > Grandchild A1.1"
  end

  it "is able to get and set a parent node" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    expect(node.parent).to eq @root_1
    node.parent = @root_2
    expect(node.parent_path).to eq "root-2"
    expect(node.path).to eq delim_join("root-2", "parent-a")
  end

  it "is able to set the parent by path" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.parent_path = "root-2"
    expect(node.parent).to eq @root_2
    expect(node.path).to eq delim_join("root-2", "parent-a")
  end

  it "has child nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    expect(node.children).to eq [@child_a1, @child_a2]
  end

  it "has descendant nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    expect(node.descendants).to eq [@child_a1, @child_a2, @grandchild]
  end

  it "has sibling nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    expect(node.siblings).to eq [@parent_b, @parent_c]
  end

  it "has ancestor nodes" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a", "child-a1"))
    expect(node.ancestors).to eq [@root_1, @parent_a]
  end

  context "when name is changed" do
    it "fills in a blank node_path when name is changed" do
      unsaved_rec.node_path = ''

      unsaved_rec.name = 'Changed Parent'
      expect(unsaved_rec.node_path).to eq 'changed-parent'
      expect(unsaved_rec.path).to eq delim_join('root-1', 'changed-parent')
    end

    it "does not overwrite a present node_path when name is changed" do
      orig_node_path = unsaved_rec.node_path
      unsaved_rec.name = 'Changed Parent'
      expect(unsaved_rec.node_path).to eq orig_node_path
      expect(unsaved_rec.path).to eq delim_join('root-1', orig_node_path)
    end
  end

  it "maintains the path with the node path" do
    node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
    node.node_path = "New Name"
    expect(node.path).to eq delim_join("root-1", "new-name")
  end

  it "expands a path to its component paths" do
    expect(PathTree::Test.expanded_paths(delim_join(*%w[this is a test]))).to eq [
      "this",
      delim_join(*%w[this is]),
      delim_join(*%w[this is a]),
      delim_join(*%w[this is a test]) ]
  end

  it "gets the expanded paths for a node" do
    expect(@grandchild.expanded_paths).to eq [
      "root-1",
      delim_join("root-1", "parent-a"),
      delim_join("root-1", "parent-a", "child-a1"),
      delim_join("root-1", "parent-a", "child-a1", "grandchild-a1-1") ]
  end

  context "child paths" do
    around :each do |ex|
      PathTree::Test.transaction do
        ex.run
        raise ActiveRecord::Rollback
      end
    end

    it "updates child paths when the path is changed" do
      node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
      node.node_path = "New Name"
      node.save!
      node.reload
      expect(node.children.map(&:path)).to eq [
        delim_join("root-1", "new-name", "child-a1"),
        delim_join("root-1", "new-name", "child-a2") ]
      expect(node.children.first.children.map(&:path)).to eq [
        delim_join("root-1", "new-name", "child-a1", "grandchild-a1-1") ]
    end

    it "updates child paths when a node is destroyed" do
      node = PathTree::Test.find_by_path(delim_join("root-1", "parent-a"))
      node.name = "New Name"
      node.destroy
      root = PathTree::Test.find_by_path("root-1")
      expect(root.children.map(&:path)).to eq [
        delim_join("root-1", "parent-b"),
        delim_join("root-1", "parent-c"),
        delim_join("root-1", "child-a1"),
        delim_join("root-1", "child-a2") ]
      expect(root.children[2].children.map(&:path)).to eq [
        delim_join("root-1", "child-a1", "grandchild-a1-1") ]
    end
  end
end
