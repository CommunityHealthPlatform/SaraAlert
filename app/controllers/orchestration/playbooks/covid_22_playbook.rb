# frozen_string_literal: true

# Covid22Playbook: tests 'remove' type works
module Orchestration::Playbooks::Covid22Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_22

  PLAYBOOK = {
    label: 'COVID-22',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'remove',
          config: {
            set: %i[symptomatic non_reporting],
            custom_options: {
              symptomatic: {
                label: 'Some random label'
              }
            }
          }
        },
        header_action_buttons: {
          type: 'remove',
          config: {
            set: %i[enroll import],
            custom_options: {
              import: {
                label: 'Import',
                type: 'subset',
                config: {
                  set: %i[saf]
                }
              },
              export: {
                label: 'Export',
                type: 'all',
                config: {
                  set: %i[saf]
                }
              }
            }
          }
        },
        dashboard_table_columns: {
          type: 'all',
          config: {
            custom_options: {
              symptomatic: {
                type: 'subset',
                config: {
                  set: %i[jurisdiction end_of_monitoring risk_level]
                }
              }
            }
          }

        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'base'
        },
        header_action_buttons: {
          type: 'all'
        }
      } }
    },
    general: {
      base: INFECTIOUS[:general], custom_options: {
        patient_page_sections: {
          type: 'all',
          config: {
            custom_options: {
            }
          }
        }
      }
    },
    system: {
      continuous_exposure_on: true,
      monitoring_period_days: 14,
      isolation_non_reporting_max_days: 7
    },
    other_properties: {

    }
  }.freeze
end
