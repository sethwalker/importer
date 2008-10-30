class AddSubmittedAtToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :submitted_at, :datetime
  end

  def self.down
    remove_column :imports, :submitted_at
  end
end
