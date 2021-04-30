# frozen_string_literal: true

# ClosePatientsJob: closes patient records based on criteria
class ClosePatientsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Grab closable patients
    eligible = Patient.close_eligible

    closed = []
    not_closed = []
    jurisdiction_send_close = {} # { jurisdiction_id: send_close, ... }

    # Close patients who are past the monitoring period (and are actually closable from above logic)
    eligible.each do |patient|
      # Update related fields
      patient[:monitoring] = false
      patient[:closed_at] = DateTime.now

      # If the patient was enrolled already past their monitoring period based on their last date of exposure, specify special reason for closure
      if !patient.last_date_of_exposure.nil? &&
         ((patient.last_date_of_exposure.beginning_of_day + ADMIN_OPTIONS['monitoring_period_days'].days) < patient.created_at.beginning_of_day)
        patient[:monitoring_reason] = 'Enrolled more than 14 days after last date of exposure (system)'
      elsif !patient.last_date_of_exposure.nil? &&
            ((patient.last_date_of_exposure.beginning_of_day + ADMIN_OPTIONS['monitoring_period_days'].days) == patient.created_at.beginning_of_day)
        # If the patient was enrolled on their last day of monitoring based on their last date of exposure, specify special reason for closure
        patient[:monitoring_reason] = 'Enrolled on last day of monitoring period (system)'
      else
        # Otherwise, normal reason for closure
        patient[:monitoring_reason] = 'Completed Monitoring (system)'
      end

      # Determine if the patient's jurisdiction allows automated closed notifications
      jurisdiction_send_close[patient.jurisdiction_id] = patient.jurisdiction.send_close unless jurisdiction_send_close.key? patient.jurisdiction_id
      send_close = jurisdiction_send_close[patient.jurisdiction_id]
      # Send closed email or SMS to patient if they are a reporter
      if patient.save! && patient.self_reporter_or_proxy? && send_close
        contact_method = patient.preferred_contact_method&.downcase
        if ['sms texted weblink', 'sms text-message'].include? contact_method
          PatientMailer.closed_sms(patient).deliver_later(wait_until: patient.time_to_notify_closed)
        elsif contact_method == 'e-mailed web link'
          PatientMailer.closed_email(patient).deliver_later(wait_until: patient.time_to_notify_closed)
        else
          history_friendly_method = patient.preferred_contact_method.blank? ? patient.preferred_contact_method : 'Unknown'
          History.record_automatically_closed(
            patient: patient,
            comment: 'The system was unable to send a monitoring complete message to this monitoree because their'\
                     "preferred contact method, #{history_friendly_method}, is not supported for this message type."
          )
        end
      end

      # History item for automatically closing the record
      History.record_automatically_closed(patient: patient)

      closed << { id: patient.id }
    rescue StandardError => e
      not_closed << { id: patient.id, reason: e.message }
      next
    end

    # Send results
    UserMailer.close_job_email(closed, not_closed, eligible.size).deliver_now
  end
end
