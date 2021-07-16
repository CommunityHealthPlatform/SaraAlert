# frozen_string_literal: true

# PlaybookValidator: validates playbooks before use
module Orchestration::PlaybookValidator
  def self.validate_exposure(tabs)
    errors = 0
    options = %i[symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out all]
    tabs.each do |tab|
      if options.none? tab
        errors += 1
        puts 'The selected option ' + tab.to_s + ' is not a supported tab in the Exposure workflow.'
      end
    end
    errors
  end

  def self.validate_isolation(tabs)
    errors = 0
    options = %i[requiring_review non_reporting reporting closed transferred_in transferred_out all]
    tabs.each do |tab|
      if options.none? tab
        errors += 1
        puts 'The selected option ' + tab.to_s + ' is not a supported tab in the Isolation workflow.'
      end
    end
    errors
  end

  def self.validate_workflow(workflow)
    errors = 0
    label = workflow[1][:label]
    type = workflow[1][:custom_options][:dashboard_tabs][:type]
    case label
    when 'Exposure'
      if %w[all base].include?(type)
        # this is always valid
      elsif %w[subset remove].include?(type)
        tabs = workflow[1][:custom_options][:dashboard_tabs][:config][:set]
        errors += Orchestration::PlaybookValidator.validate_exposure(tabs)
      else
        errors += 1
        puts 'The workflow type - ' + type + ' - is not supported.'
      end
    when 'Isolation'
      if %w[all base].include?(type)
        # this is always valid
      elsif %w[subset remove].include?(type)
        tabs = workflow[1][:custom_options][:dashboard_tabs][:config][:set]
        errors += Orchestration::PlaybookValidator.validate_isolation(tabs)
      else
        errors += 1
        puts 'The workflow type - ' + type + ' - is not supported.'
      end
    else
      puts 'The workflow must be either Isolation or Exposure - ' + label + ' - is not supported.'
      errors += 1
    end
    errors
  end

  def self.validate_playbook(playbook)
    errors = 0
    if playbook[1][:label].empty?
      errors += 1
      puts 'The playbook label must have a value.'
    end
    if playbook[1][:workflows].nil?
      errors += 1
      puts 'The playbook must have a workflow.'
    else
      playbook[1][:workflows].each do |workflow|
        errors += Orchestration::PlaybookValidator.validate_workflow(workflow)
      end
    end

    errors
  end
end
