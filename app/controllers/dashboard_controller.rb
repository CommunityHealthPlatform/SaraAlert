# frozen_string_literal: true

class DashboardController < ApplicationController
  include Orchestration::Orchestrator

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def dashboard
    @path_params = request.path_parameters

    playbook = @path_params[:playbook].parameterize.underscore.to_sym
    workflow = @path_params[:workflow].parameterize.underscore.to_sym

    @playbook_label = PLAYBOOKS.dig(playbook, :label)
    @workflow_label = PLAYBOOKS.dig(playbook, :workflows, workflow, :label)

    redirect_to('/404') && return if @playbook_label.nil? || @workflow_label.nil?

    @tabs = custom_configuration(playbook, workflow, :dashboard_tabs)
    @available_workflows = available_workflows(playbook)
  end


  def index
    @path_params = request.path_parameters

    if @path_params[:playbook].nil? then
      # Select the playbook to use as the default
      # NOTE: This is not deterministic if there are multiple playbook.
      default_playbook = available_playbooks[0]
      playbook_name = default_playbook[:name]
    else
      playbook_name = @path_params[:playbook].parameterize.underscore.to_sym
       # return error if given playbook doesn't exist
      redirect_to('/404') && return if PLAYBOOKS.dig(playbook_name).nil?
    end

    # Select the workflow to present as the default
    workflow = default_workflow(playbook_name)

    redirect_to('/404') && return if workflow.nil?
    redirect_to ("/dashboard/#{playbook_name}/" + workflow[:name].to_s)
  end

  def authenticate_user_role
    # Role restriction with current_user, but we don't know if this is conifgurable yet
  end
end
