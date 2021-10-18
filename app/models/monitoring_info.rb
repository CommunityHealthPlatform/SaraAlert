class MonitoringInfo < ApplicationRecord
    belongs_to :monitoring_program
    belongs_to :patient
    has_many :assessments
end
