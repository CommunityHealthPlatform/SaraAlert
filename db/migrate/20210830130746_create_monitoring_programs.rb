class CreateMonitoringPrograms < ActiveRecord::Migration[6.1]
  def change
    create_table :monitoring_programs do |t|
      t.string :name, null: false, unique: true
      t.string :label, null: false
      t.timestamps
    end

    create_table :jurisdiction_monitoring_programs do |t|
      t.belongs_to :monitoring_program
      t.belongs_to :jurisdiction
      t.boolean :is_default, default: false
    end
  end
end
