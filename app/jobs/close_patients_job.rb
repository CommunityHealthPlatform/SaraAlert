# frozen_string_literal: true

# ClosePatientsJob: closes patient records based on criteria
class ClosePatientsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Grab closable patients
    enrolled_past_monitoring_period_ids = Set.new Patient.close_eligible.enrolled_past_monitoring_period.pluck(:id)
    enrolled_last_day_monitoring_period_ids = Set.new Patient.close_eligible.enrolled_last_day_monitoring_period.pluck(:id)
    completed_monitoring_ids = Set.new(Patient.close_eligible.pluck(:id)) - enrolled_past_monitoring_period_ids - enrolled_last_day_monitoring_period_ids
    total_patients = enrolled_past_monitoring_period_ids.size + enrolled_last_day_monitoring_period_ids.size + completed_monitoring_ids.size

    results = combine_batch_results(
      [
        perform_batch(enrolled_past_monitoring_period_ids, 'Enrolled more than 14 days after last date of exposure (system)'),
        perform_batch(enrolled_last_day_monitoring_period_ids, 'Enrolled on last day of monitoring period (system)'),
        perform_batch(completed_monitoring_ids, 'Completed Monitoring (system)')
      ]
    )

    # Send results
    UserMailer.close_job_email(results[:closed], results[:not_closed], total_patients).deliver_now
  end

  private

  def perform_batch(patient_batch, monitoring_reason)
    closed = patient_batch.map { |pid| { id: pid } }
    not_closed = []

    ActiveRecord::Base.transaction do
      # Close records
      Patient.where(id: patient_batch).update_all(
        monitoring: false,
        closed_at: DateTime.now,
        updated_at: DateTime.now,
        monitoring_reason: monitoring_reason,
        continuous_exposure: false
      )
      # Create histories
      History.import(patient_batch.map { |pid| History.record_automatically_closed(patient: pid, create: false) })
    end

    # Send emails to patients with an email in the system
    Patient.where(id: patient_batch)
           .where('patients.id = patients.responder_id')
           .where('patients.email IS NOT NULL AND patients.email != \'\'')
           .select(
             :id,
             :email,
             :primary_language,
             :first_name,
             :last_name,
             :date_of_birth
           )
           .each do |patient|
      PatientMailer.closed_email(patient).deliver_later
    rescue StandardError => _e
      next
    end

    {
      closed: closed,
      not_closed: not_closed
    }
  end

  def combine_batch_results(batch_results)
    results = {
      closed: [],
      not_closed: []
    }
    batch_results.each do |batch_result|
      results[:closed] += batch_result[:closed]
      results[:not_closed] += batch_result[:not_closed]
    end
    results
  end
end
