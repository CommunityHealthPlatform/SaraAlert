module Orchestration::Playbooks::Covid191Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_191

  PLAYBOOK = {
    label: 'COVID-191',    
    system: {
      continuous_exposure_on: true
    },
    other_properties: {
    }
  }
end
