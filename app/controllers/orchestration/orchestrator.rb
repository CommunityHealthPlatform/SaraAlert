module Orchestration::Orchestrator
  include Orchestration::Playbooks
  include Orchestration::PlaybookValidator

  available = Orchestration::Playbooks.constants.reject { |m| m == :Templates }
  modules = available.map { |m| ('Orchestration::Playbooks::' + m.to_s).constantize }

  playbooks = {}
  modules.each { |m| playbooks[m::NAME] = m::PLAYBOOK }

  # remove invalid playbooks
  playbooks.each_with_index do |playbook, index|
    errors = Orchestration::PlaybookValidator.validate_playbook(playbook)
    if errors > 0
      puts 'Playbook ' + (index + 1).to_s + ' - ' + playbook[1][:label] + ' - contained ' + errors.to_s + ' error(s) and was removed.'
      playbooks.delete(playbooks.index(playbook[1]))

      # TODO - track these for a different error page than a 404?
    end
  end

  PLAYBOOKS = playbooks.freeze

  def custom_configuration(playbook, workflow, option)
    # For now, assume that if no workflow (ie it is nil, it is a general option)
    base_configuration = workflow.nil? ? PLAYBOOKS.dig(playbook, :general, :base, option) : PLAYBOOKS.dig(playbook, :workflows, workflow, :base, option)
    custom_options = workflow.nil? ? PLAYBOOKS.dig(playbook, :general, :custom_options,
                                                   option) : PLAYBOOKS.dig(playbook, :workflows, workflow, :custom_options, option)

    return if base_configuration.nil?
    return base_configuration if custom_options.nil?

    nested_configuration(base_configuration, custom_options)
  end

  # 'base': Return the whole base configuration. Do not follow nested configurations
  # 'all': Return the base configuration options, but also follow the nested configurations
  # 'subset': Select the given keys from the options, but also follow the nested configurations
  # 'remove': Reject the given keys from the options, but also follow the nested configurations
  # 'custom': Overwrite the whole configuration
  def nested_configuration(base_configuration, playbook_configuration)
    # Replace label first if available
    unless base_configuration[:label].nil?
      base_configuration[:label] =
        playbook_configuration[:label].nil? ? base_configuration[:label] : playbook_configuration[:label]
    end
    selected_configuration = {}
    selected_configuration[:label] = base_configuration[:label] if base_configuration[:label].present?

    # If playbook has no type, then we'll assume everything since we don't know what to do
    type = playbook_configuration[:type].nil? ? 'base' : playbook_configuration[:type]

    case type
    when 'base'
      # Return entirety of the base configuration
      return base_configuration
    when 'all'
      # Select the base configuration
      selected_configuration = base_configuration
    when 'subset'
      # If a subset, then look into the configuration and only return the wanted fields
      selected_configuration[:options] = if base_configuration[:options].is_a?(Array)
                                           base_configuration[:options].select { |key, _value| playbook_configuration[:config][:set].include?(key) }
                                         else
                                           base_configuration[:options].select { |key| playbook_configuration[:config][:set].include?(key) }
                                         end
    when 'remove'
      # If remove, then look into the configuration and reject the listed fields
      selected_configuration[:options] = if base_configuration[:options].is_a?(Array)
                                           base_configuration[:options].reject { |key, _value| playbook_configuration[:config][:set].include?(key) }
                                         else
                                           base_configuration[:options].reject { |key, _value| playbook_configuration[:config][:set].include?(key) }
                                         end
    when 'custom'
      # TODO: This is here as a catch all, but this isn't really being implemented
      # For now the assumption is if you choose custom you need to write the whole configuration
      # including the nested configuration
      return playbook_configuration[:config]
    end

    nested_options = playbook_configuration.dig(:config, :custom_options)

    # If there are no custom options... just return!
    return selected_configuration if nested_options.nil?

    # Otherwise we'll checkout the children
    nested_options.each do |key, value|
      next if base_configuration[:options][key].nil?
      selected_configuration[:options][key] = nested_configuration(base_configuration[:options][key], value)
    end

    selected_configuration
  end

  def available_playbooks
    PLAYBOOKS.keys.collect { |key| { name: key, label: PLAYBOOKS[key][:label] } }
  end

  def available_workflows(playbook)
    PLAYBOOKS[playbook][:workflows].keys.collect { |key| { name: key, label: PLAYBOOKS[playbook][:workflows][key][:label] } }
  end
end
