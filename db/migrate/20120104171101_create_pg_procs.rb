class CreatePgProcs < ActiveRecord::Migration
  def self.up
    create_table :pg_procs do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :pg_procs
  end
end
