# This module implements a tree structure by using a convention of converting a name into a path.
# Paths created by normalizing a name attribute and then separating levels with periods with
# the lowest level coming last.
#
# In order to use this module, the model must respond to the +first+ and +all+ methods like ActiveRecord,
# have support for after_destroy and after_save callbacks, validates_* macros and include attributes
# for name, node_path, path, and parent_path.
module PathTree  
  if RUBY_VERSION.match(/^1\.8/)
    require File.expand_path("../ruby_18_patterns.rb", __FILE__)
  else
    require File.expand_path("../ruby_19_patterns.rb", __FILE__)
  end
  include Patterns

  def self.included (base)
    base.extend(ClassMethods)
    
    base.validates_uniqueness_of :path
    base.validates_uniqueness_of :node_path, :scope => :parent_path
    base.validates_presence_of :name, :node_path, :path
    
    base.after_save do |record|
      if record.path_changed? and !record.path_was.nil?
        record.children.each do |child|
          child.update_attributes(:parent_path => record.path)
        end
      end
      record.instance_variable_set(:@children, nil)
    end
    
    base.after_destroy do |record|
      record.children.each do |child|
        child.update_attributes(:parent_path => record.parent_path)
      end
    end
  end

  module ClassMethods
    include Patterns
    
    NON_WORD_PATTERN = /[^a-z0-9_]+/.freeze
    DASH_AT_START_PATTERN = /^-+/.freeze
    DASH_AT_END_PATTERN = /-+$/.freeze
    
    # Get all the root nodes (i.e. those without any parents)
    def roots
      all(:conditions => {:parent_path => nil})
    end
    
    # Set the path delimiter (default is '.').
    def path_delimiter= (char)
      @path_delimiter = char
    end
    
    def path_delimiter
      @path_delimiter ||= '.'
    end
    
    # Load the entire branch of the tree under path at once. If you will be traversing the
    # tree, this is the fastest way to load it. Returns the root node of the branch.
    def branch (path)
      raise ArgumentError.new("branch path must not be blank") if path.blank?
      root = first(:conditions => {:path => path})
      return [] unless root
      nodes = path_like(path).sort{|a,b| b.path <=> a.path}
      nodes << root
      return populate_tree_structure!(nodes.pop, nodes)
    end
    
    # Translate a value into a valid path part. By default this will translate it into an ascii
    # lower case value with words delimited by dashes. Implementations can override this logic.
    def pathify (value)
      if value
        asciify(unquote(value)).strip.downcase.gsub(NON_WORD_PATTERN, '-').gsub(DASH_AT_START_PATTERN, '').gsub(DASH_AT_END_PATTERN, '')
      end
    end
    
    # Replace accented characters with the closest ascii equivalent
    def asciify (value)
      if value
        value.gsub(UPPER_A_PATTERN, 'A').gsub(LOWER_A_PATTERN, 'a').
          gsub(UPPER_E_PATTERN, 'E').gsub(LOWER_E_PATTERN, 'e').
          gsub(UPPER_I_PATTERN, 'I').gsub(LOWER_I_PATTERN, 'i').
          gsub(UPPER_O_PATTERN, 'O').gsub(LOWER_O_PATTERN, 'o').
          gsub(UPPER_U_PATTERN, 'U').gsub(LOWER_U_PATTERN, 'u').
          gsub(UPPER_Y_PATTERN, 'Y').gsub(LOWER_Y_PATTERN, 'y').
          gsub(UPPER_N_PATTERN, 'N').gsub(LOWER_N_PATTERN, 'n').
          gsub(UPPER_C_PATTERN, 'C').gsub(LOWER_C_PATTERN, 'c').
          gsub(UPPER_AE_PATTERN, 'AE').gsub(LOWER_AE_PATTERN, 'ae').
          gsub(SS_PATTERN, 'ss').gsub(UPPER_D_PATTERN, 'D')
      end
    end
    
    # Remove quotation marks from a string.
    def unquote (value)
      value.gsub(/['"]/, '') if value
    end
    
    # Abstract way of finding paths that start with a value so it can be overridden by non-SQL implementations.
    def path_like (value)
      all(:conditions => ["path LIKE ?", "#{value}#{path_delimiter}%"])
    end
    
    # Expand a path into an array of the path and all its ancestor paths.
    def expanded_paths (path)
      expanded = []
      path.split(path_delimiter).each do |part|
        if expanded.empty?
          expanded << part
        else
          expanded << "#{expanded.last}#{path_delimiter}#{part}"
        end
      end
      expanded
    end
    
    private
    
    def populate_tree_structure! (root, sorted_nodes)
      while !sorted_nodes.empty? do
        node = sorted_nodes.last
        if node.parent_path == root.path
          sorted_nodes.pop
          node.parent = root
          root.send(:append_child, node)
        else
          last_child = root.children.last
          if last_child and node.parent_path == last_child.path
            populate_tree_structure!(last_child, sorted_nodes)
          else
            break
          end
        end
      end
      return root
    end
  end
  
  # Get the full name of a node including the names of all it's parent nodes. Specify the separator string to use
  # between values with :separator (defaults to " > "). You can also specify the context for the full name by
  # specifying a path in :context. This will only render the names up to and not including that part of the tree.
  def full_name (options = {})
    separator = options[:separator] || " > "
    n = ""
    n << parent.full_name(options) if parent_path and parent_path != options[:context]
    n << separator unless n.blank?
    n << name
  end
  
  def path_delimiter
    self.class.path_delimiter
  end

  # Get the parent node.
  def parent
    unless instance_variable_defined?(:@parent)
      if path.index(path_delimiter)
        @parent = self.class.base_class.first(:conditions => {:path => parent_path})
      else
        @parent = nil
      end
    end
    @parent
  end
  
  # Set the parent node.
  def parent= (node)
    node_path = node.path if node
    self.parent_path = node_path unless parent_path == node_path
    @parent = node
  end
  
  # Set the parent path
  def parent_path= (value)
    unless value == parent_path
      self[:parent_path] = value
      recalculate_path
      remove_instance_variable(:@parent) if instance_variable_defined?(:@parent)
    end
    value
  end
  
  def name= (value)
    unless value == name
      self[:name] = value
      self.node_path = value if node_path.blank?
    end
    value
  end
  
  def node_path= (value)
    pathified = self.class.pathify(value)
    self[:node_path] = pathified
    recalculate_path
  end
  
  # Get all nodes that are direct children of this node.
  def children
    unless @children
      childrens_path = new_record? ? path : path_was
      @children = self.class.base_class.all(:conditions => {:parent_path => childrens_path})
      @children.each{|c| c.parent = self}
    end
    @children
  end

  # Get all nodes that share the same parent as this node.
  def siblings
    self.class.base_class.all(:conditions => {:parent_path => parent_path}).reject{|node| node == self}
  end

  # Get all descendant of this node.
  def descendants
    self.class.base_class.path_like(path)
  end

  # Get all ancestors of this node with the root node first.
  def ancestors
    ancestor_paths = expanded_paths
    ancestor_paths.pop
    if ancestor_paths.empty?
      []
    else
      self.class.base_class.all(:conditions => {:path => ancestor_paths}).sort{|a,b| a.path.length <=> b.path.length}
    end
  end

  # Returns an array containing the paths of this node and those of all its ancestors.
  def expanded_paths
    self.class.expanded_paths(path)
  end
  
  protected
  
  def append_child (node)
    @children ||= []
    @children << node
    node.parent = self
  end
  
  def recalculate_path
    path = ""
    path << "#{parent_path}#{path_delimiter}" unless parent_path.blank?
    path << node_path if node_path
    self.path = path
  end
end
