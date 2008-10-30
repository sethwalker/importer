class AddErrorsColumn < ActiveRecord::Migration
  def self.up
    add_column :imports, :import_errors, :text
  end

  def self.down
    remove_column :imports, :import_errors
  end
end
