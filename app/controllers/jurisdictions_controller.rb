# frozen_string_literal: true

# JurisdictionsController: handles all subject actions
class JurisdictionsController < ApplicationController

  before_action :authenticate_user!
  before_action :authenticate_user_role

  # Get jurisdiction ids and paths of viewable jurisdictions
  def jurisdiction_paths
    render json: { jurisdiction_paths: current_user.jurisdiction.subtree.pluck(:id, :path).to_h }
  end

  # Get all jurisdiction ids and paths
  def all_jurisdiction_paths
    render json: { all_jurisdiction_paths: Jurisdiction.all.pluck(:id, :path).to_h }
  end

  private

  def authenticate_user_role
    return head :unauthorized unless current_user.admin?
  end
end
