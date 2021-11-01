class MonitoringProgram < ApplicationRecord
    # has_and_belongs_to_many :jurisdictions, include: false
    has_many :jurisdiction_monitoring_programs
    has_many :jurisdictions, through: :jursidiction_monitoring_programs
    has_many :monitoring_infos
end