class AddGuessColumnsToImportsTable < ActiveRecord::Migration
  def self.up
    add_column :imports, 'posts_guess', :integer, :default => 0
    add_column :imports, 'pages_guess', :integer, :default => 0
    add_column :imports, 'comments_guess', :integer, :default => 0
  end

  def self.down
    remove_column :imports, 'posts_guess'
    remove_column :imports, 'pages_guess'
    remove_column :imports, 'comments_guess'
  end
end
