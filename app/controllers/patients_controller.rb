# frozen_string_literal: true

# PatientsController: handles all subject actions
class PatientsController < ApplicationController
  before_action :authenticate_user!

  # Enroller view to see enrolled subjects and button to enroll new subjects
  def index; end

  def monitoree_unavailable
    @title = 'Monitoree Unavailable'
  end

  # The single subject view
  def show
    redirect_to(root_url) && return unless current_user.can_view_patient?
  end

  # Returns a new (unsaved) subject, for creating a new subject
  def new
    redirect_to(root_url) && return unless current_user.can_create_patient?
  end

  # Editing a patient
  def edit
    redirect_to(root_url) && return unless current_user.can_edit_patient?
  end

  # This follows 'new', this will receive the subject details and save a new subject
  # to the database.
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient? || current_user.can_import?
  end

  # General updates to an existing subject.
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient?
  end

  def bulk_update
    redirect_to(root_url) && return unless current_user.can_edit_patient_monitoring_info?

    # Nothing to do in this function if there isn't a list of patient ids.
    patient_ids = params.require(:ids)
  end

  # Check to see if a phone number has blocked SMS communications with SaraAlert
  def sms_eligibility_check
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    phone_number = params.require(:phone_number)
    blocked = BlockedNumber.exists?(phone_number: phone_number)
    render json: { sms_eligible: !blocked }
  end

  # Construct a diff for a patient update to keep track of changes
  def patient_diff(patient_before, patient_after)
    diffs = []
    allowed_params.each_key do |attribute|
      next if patient_before[attribute] == patient_after[attribute]

      diffs << {
        attribute: attribute,
        before: attribute == :jurisdiction_id ? Jurisdiction.find(patient_before[attribute])[:path] : patient_before[attribute],
        after: attribute == :jurisdiction_id ? Jurisdiction.find(patient_after[attribute])[:path] : patient_after[attribute]
      }
    end
    diffs
  end

  # Parameters allowed for saving to database
  def allowed_params
    params.require(:patient).permit(
      :first_name,
      :middle_name,
      :last_name,
      :date_of_birth,
      :age,
      :sex,
      :white,
      :black_or_african_american,
      :american_indian_or_alaska_native,
      :asian,
      :native_hawaiian_or_other_pacific_islander,
      :race_other,
      :race_unknown,
      :race_refused_to_answer,
      :ethnicity,
      :primary_language,
      :secondary_language,
      :interpretation_required,
      :nationality,
      :address_line_1,
      :address_city,
      :address_state,
      :address_line_2,
      :address_zip,
      :address_county,
      :contact_type,
      :contact_name,
      :primary_telephone,
      :primary_telephone_type,
      :secondary_telephone,
      :secondary_telephone_type,
      :international_telephone,
      :email,
      :preferred_contact_method,
      :preferred_contact_time,
      :alternate_contact_type,
      :alternate_contact_name,
      :alternate_primary_telephone,
      :alternate_primary_telephone_type,
      :alternate_secondary_telephone,
      :alternate_secondary_telephone_type,
      :alternate_international_telephone,
      :alternate_email,
      :alternate_preferred_contact_method,
      :alternate_preferred_contact_time,
      :jurisdiction_id,
      :gender_identity,
      :sexual_orientation,
    )
  end

  private

  # Set the instance variables necessary for rendering the breadcrumbs
  def dashboard_crumb(dashboard, patient); end
end
