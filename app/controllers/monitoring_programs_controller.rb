# frozen_string_literal: true

class MonitoringProgramsController < ApplicationController
  include PatientQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  # Get monitoring programs available to user's jurisdiction
  def available_monitoring_programs
    render json: { monitoring_programs: current_user.jurisdiction.monitoring_programs}
  end

  # Get all monitoring programs
  def all_monitoring_programs
    render json: { all_monitoring_programs: MonitoringProgram.all.pluck(:id, :name).to_h }
  end


  private

  def authenticate_user_role
    return head :unauthorized unless current_user.can_create_patient? || current_user.can_edit_patient? ||
                                     current_user.can_view_public_health_dashboard? || current_user.admin?
  end
end