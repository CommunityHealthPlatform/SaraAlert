module Orchestration::PlaybookValidator 


  def self.validate_exposure(tabs)
    errors = 0
    options = [:symptomatic, :non_reporting, :asymptomatic, :pui, :closed, :transferred_in, :transferred_out, :all]
    tabs.each do |tab| 
      if (options.none? tab)
        errors += 1
        puts 'The selected option ' + tab.to_s + ' is not a supported tab in the Exposure workflow.'
      end
    end
    return errors
  end

  def self.validate_isolation(tabs)
    errors = 0
    options = [:requiring_review, :non_reporting, :reporting, :closed, :transferred_in, :transferred_out, :all]
    tabs.each do |tab| 
      if (options.none? tab)
        errors += 1
        puts 'The selected option ' + tab.to_s + ' is not a supported tab in the Isolation workflow.'
      end
    end
    return errors
  end

  def self.validate_workflow(workflow)
        errors = 0
        label = workflow[1][:label]
        type = workflow[1][:custom_options][:dashboard_tabs][:type];
        if label == 'Exposure'
          if type == 'all' 
          elsif type == 'subset'
            tabs = workflow[1][:custom_options][:dashboard_tabs][:config][:set]
            errors += Orchestration::PlaybookValidator.validate_exposure(tabs)
          else
            errors+=1
            puts 'The workflow type - ' + type + ' - is not supported.'
          end
        elsif label == 'Isolation'
          if type == 'all'  
            # this is always valid
          elsif type == 'subset'
            tabs = workflow[1][:custom_options][:dashboard_tabs][:config][:set]
            errors += Orchestration::PlaybookValidator.validate_isolation(tabs)
          else
            errors+=1
            puts 'The workflow type - ' + type + ' - is not supported.' 
          end
        else
          puts 'The workflow must be either Isolation or Exposure - ' + label + ' - is not supported.'
          errors+=1
        end
        return errors
  end

  def self.validate_playbook(playbook)
    errors = 0
    if playbook[1][:label].length < 1 
      errors+=1
      puts 'The playbook label must have a value.' 
    end 
    if playbook[1][:workflows].nil? 
      errors+=1      
      puts 'The playbook must have a workflow.' 
    else 
      playbook[1][:workflows].each do |workflow|
        errors += Orchestration::PlaybookValidator.validate_workflow(workflow)
      end
    end

    return errors  
  end
end