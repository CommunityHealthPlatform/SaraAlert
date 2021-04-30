# frozen_string_literal: true

require 'test_case'

class ClosePatientsJobTest < ActiveSupport::TestCase
  def setup
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    ENV['TWILLIO_STUDIO_FLOW'] = 'TEST'
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
    ENV['TWILLIO_STUDIO_FLOW'] = nil
  end

  def history_that_contains?(patient, history_comment_substring)
    patient.histories.each do |history|
      return true if history.comment.include? history_comment_substring
    end
    false
  end

  test 'handles case where last date of exposure is nil' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: nil,
                     created_at: 20.days.ago)
    ClosePatientsJob.perform_now
    # Reload attributes after job
    patient.reload
    assert_equal('Completed Monitoring (system)', patient.monitoring_reason)
  end

  test 'updates appropriate fields on each closed record' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    ClosePatientsJob.perform_now

    # Verify fields changed
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.closed_at.to_date, DateTime.now.to_date)
    assert_equal(updated_patient.monitoring, false)
  end

  test 'creates expected History item for each record' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.histories.last.history_type, History::HISTORY_TYPES[:record_automatically_closed])
  end

  test 'creates correct monitoring reason when record has normally completed monitoring period' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     created_at: 7.days.ago)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Completed Monitoring (system)')
  end

  test 'creates correct monitoring reason when record was enrolled past their monitoring period' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     created_at: Time.now)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Enrolled more than 14 days after last date of exposure (system)')
  end

  test 'creates correct monitoring reason when record was enrolled on their last day of monitoring' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 14.days.ago,
                     created_at: Time.now)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Enrolled on last day of monitoring period (system)')
  end

  test 'sends closed email if closed record is a reporter' do
    Patient.destroy_all
    patient = create(:patient,
                     first_name: 'Jon',
                     last_name: 'Doe',
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     email: 'testpatient@example.com',
                     preferred_contact_method: 'E-mailed Web Link')

    ClosePatientsJob.perform_now
    assert_equal(ActionMailer::Base.deliveries.count, 2)
    close_email = ActionMailer::Base.deliveries[-2]
    assert_equal(close_email.header['subject'].value, 'Sara Alert Reporting Complete')
    assert_includes(
      close_email.text_part.body.to_s.gsub("\r", ' ').gsub("\n", ' '),
      "Sara Alert monitoring for #{patient.initials_age('-')} completed on #{DateTime.now.strftime('%m-%d-%Y')}! Thank you for your participation."
    )
    assert_equal(close_email.to[0], patient.email)
    assert_contains_history(patient, 'Monitoring Complete message was sent.')
    assert_contains_history(patient, 'because the monitoree email was blank.')
    assert_not_contains_history(patient, 'Monitoree has completed monitoring.')
  end

  test 'does not send closed notification if jurisdiction send_close is false' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     email: 'testpatient@example.com',
                     preferred_contact_method: 'E-mailed Web Link')
    patient.jurisdiction.update(send_close: false)
    ClosePatientsJob.perform_now
    assert_equal(ActionMailer::Base.deliveries.count, 1)
    assert history_that_contains?(patient, 'Monitoree has completed monitoring.')
  end

  ['Telephone call', 'Opt-out', 'Unknown', nil, ''].each do |preferred_contact_method|
    test "no email notification for unsupported preferred contact method #{preferred_contact_method || 'nil'}" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       email: 'testpatient@example.com',
                       preferred_contact_method: preferred_contact_method)

      ClosePatientsJob.perform_now
      history_friendly_method = patient.preferred_contact_method.blank? ? patient.preferred_contact_method : 'Unknown'
      assert history_that_contains?(patient, "#{history_friendly_method}, is not supported for this message type.")
      assert history_that_contains?(patient, 'Monitoree has completed monitoring.')
    end
  end

  ['SMS Texted Weblink', 'SMS Text-message', 'E-mailed Web Link'].each do |preferred_contact_method|
    test "does not send closed notification if #{preferred_contact_method} preferred and field is blank" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       preferred_contact_method: preferred_contact_method)

      ClosePatientsJob.perform_now
      method_text = preferred_contact_method == 'E-mailed Web Link' ? 'email' : 'primary phone number'
      assert history_that_contains?(patient, "because their preferred contact method, #{method_text}, was blank.")
      assert history_that_contains?(patient, 'Monitoree has completed monitoring.')
    end

    test "sends closed email if closed record is a reporter with #{preferred_contact_method} preferred" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       email: 'testpatient@example.com',
                       primary_telephone: '+12223334444',
                       preferred_contact_method: preferred_contact_method)

      ClosePatientsJob.perform_now
      method_text = preferred_contact_method == 'E-mailed Web Link' ? 'email' : 'primary phone number'
      assert_not history_that_contains?(patient, "because their preferred contact method, #{method_text}, was blank.")
      assert history_that_contains?(patient, 'Monitoree has completed monitoring.')
    end
  end

  test 'sends an admin email with all closed monitorees' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)
    email = ClosePatientsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
  end

  test 'sends an admin email with all monitorees not closed due to an exception' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    allow_any_instance_of(Patient).to(receive(:save!) do
      raise StandardError, 'Test StandardError'
    end)

    email = ClosePatientsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
    assert_includes(email_body, 'Test StandardError')
  end
end
