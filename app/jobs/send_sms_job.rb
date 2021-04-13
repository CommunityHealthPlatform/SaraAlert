# frozen_string_literal: true

##
# SendSmsJob: sends SMS to a patient
#
# This is meant to be used in the case where we do not want to send an SMS to 
# a patient immediately. Twilio does not have an SMS scheduling feature, so
# we can use this job to schedule messages to be sent out.
#
# Example:
# `SendSmsJob.set(wait_until: Time.tomorrow.noon).perform_later(patient.id, 'Hello world')`
class SendSmsJob < ApplicationJob
  queue_as :mailers

  def perform(patient_id, contents)
    TwilioSender.send_sms(patient.find(patient_id), contents)
  end
end
