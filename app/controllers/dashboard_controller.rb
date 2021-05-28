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

    @tabs = workflow_configuration(playbook, workflow, :dashboard_tabs)
    @available_workflows = available_workflows(playbook)
  end


  def index
    @path_params = request.path_parameters

    if @path_params[:playbook].nil? then
      # Request the playbook to use as the default from the orchestrator
      playbook = default_playbook
    else
      playbook = @path_params[:playbook].parameterize.underscore.to_sym
       # return error if playbook doesn't exist
      redirect_to('/404') && return if PLAYBOOKS.dig(playbook).nil?
    end

    # Select the workflow to present as the default
    workflow = default_workflow(playbook)

    redirect_to('/404') && return if workflow.nil?
    redirect_to ("/dashboard/#{playbook}/" + workflow[:name].to_s)
  end

  def authenticate_user_role
    # Role restriction with current_user, but we don't know if this is conifgurable yet
  end
end
