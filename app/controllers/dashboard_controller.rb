# frozen_string_literal: true

# DashboardController: Actions associated with presenting dasbhoards
class DashboardController < ApplicationController
  include Orchestration::Orchestrator

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def dashboard
    @path_params = request.path_parameters

    # Look to see if the user has access to this monitoring program.
    # We're going go 1 for 1 playbook to monitoring program as mentioned before
    mp = MonitoringProgram.includes(:jurisdiction_monitoring_programs)
                          .where({ monitoring_programs: { name: @path_params[:playbook] },
                                   jurisdiction_monitoring_programs: { jurisdiction_id: current_user.jurisdiction.id } }).first

    # TODO: Should this be 404 or 403?
    redirect_to('/404') && return if mp.nil?

    playbook = @path_params[:playbook].parameterize.underscore.to_sym
    workflow = @path_params[:workflow].parameterize.underscore.to_sym

    @playbook_label = playbook_label(playbook)
    @workflow_label = PLAYBOOKS.dig(playbook, :workflows, workflow, :label)

    redirect_to('/404') && return if @playbook_label.nil? || @workflow_label.nil?

    tabs = workflow_configuration(playbook, workflow, :dashboard_tabs)
    @tabs = tabs[:options]
    button = workflow_configuration(playbook, workflow, :header_action_buttons)
    @header_action_buttons = button.nil? ? nil : button[:options]
    dashboard_buttons = workflow_configuration(playbook, nil, :monitoring_dashboard_buttons)
    @monitoring_dashboard_buttons = dashboard_buttons.nil? ? nil : dashboard_buttons[:options]
    @available_workflows = available_workflows(playbook, filter_out_global: false)
    @available_line_lists = available_line_lists(playbook)

    @possible_jurisdiction_paths = current_user.jurisdiction.subtree.pluck(:id, :path).to_h
    # Get all assigned users of current user's jurisdiction
    @all_assigned_users = current_user.patients.where.not(assigned_user: nil).pluck(:assigned_user).uniq.sort
  end

  def index
    @path_params = request.path_parameters

    if @path_params[:playbook].nil?
      # See if there is also a default in the database
      mp = MonitoringProgram.includes(:jurisdiction_monitoring_programs)
                            .where({ monitoring_programs: { name: @path_params[:playbook] },
                                     jurisdiction_monitoring_programs: { jurisdiction_id: current_user.jurisdiction.id, is_default: true } }).first

      # Request the playbook to use as the default from the orchestrator
      playbook = mp.nil? ? default_playbook : mp.name

    else
      playbook = @path_params[:playbook].parameterize.underscore.to_sym
      # return error if playbook doesn't exist
      redirect_to('/404') && return if PLAYBOOKS[playbook].nil?
    end

    # Select the workflow to present as the default
    workflow = default_workflow(playbook)

    redirect_to('/404') && return if workflow.nil?

    redirect_to("/monitoring_program/#{playbook}/dashboard/" + workflow[:name].to_s)
  end

  def authenticate_user_role
    # TODO: Role restriction with current_user, but we don't know if this is configurable yet
    # For now, stick with public health

    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end
end
