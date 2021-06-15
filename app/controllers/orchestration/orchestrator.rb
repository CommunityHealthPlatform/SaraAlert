module Orchestration::Orchestrator
  include Orchestration::Playbooks

  available = Orchestration::Playbooks.constants.reject { |m| m == :Templates }
  modules = available.map { |m| ('Orchestration::Playbooks::' + m.to_s).constantize }

  playbooks = {}
  modules.each { |m| playbooks[m::NAME] = m::PLAYBOOK }

  PLAYBOOKS = playbooks.freeze

  def workflow_configuration(playbook, workflow, option)
    base_configuration = PLAYBOOKS.dig(playbook, :workflows, workflow, :base, option)
    options = PLAYBOOKS.dig(playbook, :workflows, workflow, :custom_options, option)

    # Return nothing if there is no base_configuration
    # TODO: This potentially might be different if we want complete customization,
    # but for now, follow the base configuration
    return if base_configuration.nil?

    # Assume that if there are no custom option, get base configuration
    type = options.nil? ? 'all' : options[:type]

    case type
    when 'all'
      # Return the base configuration
      base_configuration
    when 'subset'
      # If a subset, then look into the configuration and only return the wanted fields
      base_configuration.select { |key, _value| options[:config][:set].include?(key) }
    when 'custom'
      options[:config]
    end
  end

  def system_configuration(playbook, option)
    PLAYBOOKS.dig(playbook, :system, option)
  end

  def available_playbooks
    PLAYBOOKS.keys.collect { |key| { name: key, label: PLAYBOOKS[key][:label] } }
  end

  def available_workflows(playbook)
    PLAYBOOKS[playbook][:workflows].keys.collect { |key| { name: key, label: PLAYBOOKS[playbook][:workflows][key][:label] } }
  end

  # Returns array of hashes (for each available workflow that lists the available line lists.
  def available_line_lists(playbook)
    workflows = available_workflows(playbook)

    line_lists = {}
    workflows.each { |wf|
        line_lists[wf[:name]] = workflow_configuration(playbook, wf[:name], :dashboard_tabs)
    }

    return line_lists
  end

  def default_workflow(playbook)
    available_workflows = available_workflows(playbook)

    if available_workflows.size == 1 then
      default = available_workflows[0]
    else
      primary_workflow_key = PLAYBOOKS.dig(playbook, :system, :primary_workflow)

      # No workflows were marked as primary. Prefer one named exposure
      if primary_workflow_key.blank? then
        workflow = PLAYBOOKS.dig(playbook, :workflows, :exposure)
        if workflow.blank? then
          # NOTE: This does not guarantee the same workflow is selected every time.
          workflow = available_workflows[0]
          default = {name: workflow[:name], label: workflow[:label].nil? ? '' : workflow[:label].to_s}
        else
          default = {name: :exposure, label: workflow[:label].nil? ? '' : workflow[:label].to_s}
        end
      else
        label = PLAYBOOKS.dig(playbook, :workflows, primary_workflow_key, :label)
        default = {name: (":"+primary_workflow_key.to_s).parameterize.underscore.to_sym,
            label: (label.nil? ? '' : label.to_s)}
      end
    end
    return default
  end

  # Return the symbol to the default playbook
  def default_playbook
      # Sara Alert is always expected to have a covid_19 playbook
      playbook_name = ADMIN_OPTIONS['playbook_name'] || 'covid_19'

      default_playbook = playbook_name.parameterize.underscore.to_sym
      redirect_to('/404') && return if PLAYBOOKS.dig(default_playbook).nil?
      return default_playbook
  end
end
