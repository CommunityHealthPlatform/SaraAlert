class AddNoReportedSymptomsToPatients < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :no_reported_symptoms, :boolean
  end
end
