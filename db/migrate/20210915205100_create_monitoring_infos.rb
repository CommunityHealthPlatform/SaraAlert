class CreateMonitoringInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :monitoring_infos do |t|
      t.belongs_to :patient
      t.belongs_to :monitoring_program

      # Transferred from patient model
      t.binary :submission_token
      t.boolean :monitoring
      t.string :monitoring_reason
      t.boolean :purged
      t.string :exposure_risk_assessment
      t.string :monitoring_plan
      t.string :public_health_action
      t.datetime :last_assessment_reminder_sent
      t.date :last_date_of_exposure
      t.string :potential_exposure_location
      t.string :potential_exposure_country
      t.boolean :contact_of_known_case
      t.string :contact_of_known_case_id
      t.boolean :member_of_a_common_exposure_cohort
      t.string :member_of_a_common_exposure_cohort_type
      t.boolean :travel_to_affected_country_or_area
      t.boolean :was_in_health_care_facility_with_known_cases
      t.string :was_in_health_care_facility_with_known_cases_facility_name
      t.text :exposure_notes
      t.boolean :isolation
      t.datetime :closed_at
      t.boolean :pause_notifications
      t.date :symptom_onset
      t.string :case_status
      t.integer :assigned_user
      t.boolean :continuous_exposure
      t.datetime :latest_assessment_at
      t.boolean :latest_assessment_symptomatic
      t.date :first_positive_lab_at
      t.integer :negative_lab_count
      t.datetime :latest_transfer_at
      t.integer :latest_transfer_from
      t.boolean :user_defined_symptom_onset

      t.timestamps
    end

    # Link assessments to the monitoring info instead of the patient itself
    remove_reference :assessments, :patient
    add_belongs_to :assessments, :monitoring_info

    # Have conditions also be attached to the monitoring program
    # NOTE: This can probably be linked to jurisidiction_monitoring_programs but for now just double up
    add_belongs_to :conditions, :monitoring_program

  end
end