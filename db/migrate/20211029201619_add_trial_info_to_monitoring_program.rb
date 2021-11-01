class AddTrialInfoToMonitoringProgram < ActiveRecord::Migration[6.1]
  def change
    add_column :monitoring_programs, :welcome_survey_link, :string
    add_column :monitoring_programs, :cms_link, :string
  end
end
