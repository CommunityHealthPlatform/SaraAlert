module Orchestration::Orchestrator
  include Orchestration::Playbooks
  include Orchestration::PlaybookValidator

  available = Orchestration::Playbooks.constants.reject { |m| m == :Templates }
  modules = available.map { |m| ('Orchestration::Playbooks::' + m.to_s).constantize }

  playbooks = {}
  modules.each { |m| playbooks[m::NAME] = m::PLAYBOOK }

  #remove invalid playbooks
  playbooks.each_with_index do |playbook, index|
    errors = Orchestration::PlaybookValidator.validate_playbook(playbook)
    if errors > 0
       puts 'Playbook ' + (index + 1).to_s + ' - ' + playbook[1][:label] + ' - contained ' + errors.to_s + ' error(s) and was removed.'
       playbooks.delete(playbooks.index(playbook[1]))
    end
  end

  PLAYBOOKS = playbooks.freeze

  def custom_configuration(playbook, workflow, option)
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

  def available_playbooks
    PLAYBOOKS.keys.collect { |key| { name: key, label: PLAYBOOKS[key][:label] } }
  end

  def available_workflows(playbook)
    PLAYBOOKS[playbook][:workflows].keys.collect { |key| { name: key, label: PLAYBOOKS[playbook][:workflows][key][:label] } }
  end
end
