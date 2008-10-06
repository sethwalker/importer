class AddStartAndEndTimeToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, 'start_time', :datetime
    add_column :imports, 'finish_time', :datetime
  end


  def self.down
    remove_column :imports, 'start_time'
    remove_column :imports, 'finish_time'
  end
end
