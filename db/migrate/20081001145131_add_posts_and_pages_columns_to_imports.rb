class AddPostsAndPagesColumnsToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, 'posts', :integer, :default => 0
    add_column :imports, 'pages', :integer, :default => 0
    add_column :imports, 'comments', :integer, :default => 0
  end

  def self.down
    remove_column :imports, 'posts'
    remove_column :imports, 'pages'
    remove_column :imports, 'comments'
  end
end
