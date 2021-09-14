# frozen_string_literal: true

# JurisdictionsController: handles all subject actions
class JurisdictionsController < ApplicationController
  include PatientQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  # Get jurisdiction ids and paths of viewable jurisdictions
  def jurisdiction_paths
    render json: { jurisdiction_paths: current_user.jurisdiction.subtree.pluck(:id, :path).to_h }
  end

  # Get jurisdiction ids and paths under a specific monitoring program
  def jurisdiction_paths_under_monitoring_program
    mp = params.require(:monitoring_program)

    # TODO Eventually determine if this should be by name or by id
    render json: { jurisdiction_paths: current_user.jurisdiction.subtree.includes(:monitoring_programs).where(monitoring_programs: { name: mp }).pluck(:id, :path).to_h }
  end

  # Get all jurisdiction ids and paths
  def all_jurisdiction_paths
    render json: { all_jurisdiction_paths: Jurisdiction.all.pluck(:id, :path).to_h }
  end

  # Get monitoring programs available to jurisdiction
  def available_monitoring_programs
    render json: { monitoring_programs: current_user.jurisdiction.monitoring_programs}
  end

  # Get list of assigned users unique to jurisdiction
  def assigned_users_for_viewable_patients
    # Require jurisdiction and scope params
    params.require(:query).require(:jurisdiction)
    params.require(:query).require(:scope)

    # Validate filter and sorting params
    begin
      query = validate_patients_query(params.require(:query))
    rescue StandardError => e
      return render json: e, status: :bad_request
    end

    # Get distinct assigned users from filtered patients
    render json: { assigned_users: patients_by_query(current_user, query).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort }
  end

  private

  def authenticate_user_role
    return head :unauthorized unless current_user.can_create_patient? || current_user.can_edit_patient? ||
                                     current_user.can_view_public_health_dashboard? || current_user.admin?
  end
end
