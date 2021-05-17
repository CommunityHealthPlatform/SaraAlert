# frozen_string_literal: true

# CloseContactsController: close contacts
class CloseContactsController < ApplicationController
  before_action :authenticate_user!

  # Create a new close contact
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient_close_contacts?

    patient_id = params.permit(:patient_id)[:patient_id]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?

    cc = CloseContact.new(first_name: params.permit(:first_name)[:first_name],
                          last_name: params.permit(:last_name)[:last_name],
                          primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
                          email: params.permit(:email)[:email],
                          last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
                          assigned_user: params.permit(:assigned_user)[:assigned_user],
                          notes: params.permit(:notes)[:notes],
                          enrolled_id: nil,
                          contact_attempts: 0)
    cc.patient_id = params.permit(:patient_id)[:patient_id]
    cc.save
    History.close_contact(patient: params.permit(:patient_id)[:patient_id],
                          created_by: current_user.email,
                          comment: "User added a new close contact (ID: #{cc.id}).")
  end

  # Update an existing close contact
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient_close_contacts?

    patient_id = params.permit(:patient_id)[:patient_id]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?

    cc = CloseContact.find_by(id: params.permit(:id)[:id])
    cc.update(first_name: params.permit(:first_name)[:first_name],
              last_name: params.permit(:last_name)[:last_name],
              primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
              email: params.permit(:email)[:email],
              last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
              assigned_user: params.permit(:assigned_user)[:assigned_user],
              notes: params.permit(:notes)[:notes],
              contact_attempts: params.permit(:contact_attempts)[:contact_attempts])
    cc.save
    History.close_contact_edit(patient: patient_id,
                               created_by: current_user.email,
                               comment: "User edited a close contact (ID: #{cc.id}).")
  end

  # Delete an existing close contact record
  def destroy
    redirect_to root_url && return unless current_user.can_create_patient_close_contacts?
    cc = current_user.get_patient(params.permit(:patient_id)[:patient_id])&.close_contacts&.find_by(id: params.permit(:id)[:id])
    redirect_to root_url && return if cc.nil?
    cc.destroy
    if cc.destroyed?
      reason = params.permit(:delete_reason)[:delete_reason]
      History.close_contact_edit(patient: params.permit(:patient_id)[:patient_id],
                              created_by: current_user.email,
                              comment: "User deleted a close contact (ID: #{cc.id}, Name: #{cc.first_name} #{cc.last_name}, Primary Telephone: "\
                              "#{cc.primary_telephone}, Email: #{cc.email}, Last Date of Exposure: #{cc.last_date_of_exposure}, "\
                              "Assigned User: #{cc.assigned_user}, Notes: #{cc.notes}, Contact Attempts: #{cc.contact_attempts}. Reason: #{reason}.")
    else
      render status: 500
    end
  end
end
