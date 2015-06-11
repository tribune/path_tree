# encoding: UTF-8

require 'spec_helper'
require 'shared/path_tree_model_examples'

describe PathTree do
  before :all do
    PathTree::Test.create_tables
  end

  after :all do
    PathTree::Test.drop_tables
  end

  context "validations" do
    let(:new_rec) { PathTree::Test.new }

    it "is invalid without a name" do
      expect(new_rec).not_to be_valid
      expect(new_rec.errors[:name]).to include "can't be blank"
    end

    it "is invalid without a node_path" do
      new_rec.name = "I'm a leaf"
      new_rec.node_path = ''
      expect(new_rec).not_to be_valid
      expect(new_rec.errors[:node_path]).to include "can't be blank"
    end

    it "is invalid without a path" do
      new_rec.name = "I'm a leaf"
      new_rec.path = ''
      expect(new_rec).not_to be_valid
      expect(new_rec.errors[:path]).to include "can't be blank"
    end

    context "uniqueness" do
      around :each do |ex|
        PathTree::Test.transaction do
          @root = PathTree::Test.create!(name: 'top-dog')
          @child_1 = PathTree::Test.create!(name: 'underdog', parent: @root)
          ex.run
          raise ActiveRecord::Rollback
        end
      end

      it "enforces unique path" do
        new_rec = PathTree::Test.new(name: @child_1.node_path, parent: @root)
        expect(new_rec).not_to be_valid
        expect(new_rec.errors[:path]).to include 'has already been taken'
        expect(new_rec.errors[:node_path]).to include 'has already been taken'
      end

      it "allows duplicate node_path under different parents" do
        new_rec = PathTree::Test.new(name: @child_1.node_path)
        expect(new_rec).to be_valid
      end
    end
  end
  
  context "path construction" do
    it "turns accented characters into ascii equivalents" do
      accent_string = "ÀÂÄÃÅàâáããä-ÈÊÉËèêéë-ÌÎÍÏìîíï-ÒÔÖØÓÕòôöøóõ-ÚÜÙÛúüùû-ÝýÿÑñÇçÆæßÐ"
      expected_string = "AAAAAaaaaaa-EEEEeeee-IIIIiiii-OOOOOOoooooo-UUUUuuuu-YyyNnCcAEaessD"
      expect(PathTree::Test.asciify(accent_string)).to eq expected_string
    end

    it "unquotes strings" do
      expect(PathTree::Test.unquote(%Q("This is a 'test'"))).to eq "This is a test"
    end

    it "translates a value to a path part" do
      expect(PathTree::Test.pathify("This is the 1st / test À...")).to eq "this-is-the-1st-test-a"
    end

    it "sets the parent path when setting the parent" do
      parent = PathTree::Test.new(:name => "parent")
      node = PathTree::Test.new(:name => "child")
      node.parent = parent
      expect(node.parent_path).to eq "parent"
      node.parent = nil
      expect(node.parent_path).to be nil
    end
  end

  context "with default delimiter" do
    include_examples "a PathTree model", nil, '/'
  end

  context "with custom delimiter" do
    include_examples "a PathTree model", '/', ':'
  end
end
