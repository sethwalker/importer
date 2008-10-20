class RenameImportColumns < ActiveRecord::Migration
  def self.up
    remove_column :imports, 'posts_guess'
    remove_column :imports, 'pages_guess'
    remove_column :imports, 'comments_guess'
    
    remove_column :imports, 'posts'
    remove_column :imports, 'pages'
    remove_column :imports, 'comments'
    
    add_column :imports, :adds, :text
    add_column :imports, :guesses, :text
  end

  def self.down
    remove_column :imports, :adds
    remove_column :imports, :guesses
    
    add_column :imports, 'posts_guess', :integer, :default => 0
    add_column :imports, 'pages_guess', :integer, :default => 0
    add_column :imports, 'comments_guess', :integer, :default => 0
    
    add_column :imports, 'posts', :integer, :default => 0
    add_column :imports, 'pages', :integer, :default => 0
    add_column :imports, 'comments', :integer, :default => 0
  end
end
