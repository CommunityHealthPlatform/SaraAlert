# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

# Time Threshold: 260 seconds
benchmark(
  name: 'SendAssessmentsJob',
  time_threshold: 260,
  setup: proc { Timecop.travel(Time.now.utc.change(hour: 21)) },
  teardown: proc { Timecop.return }
) { SendAssessmentsJob.perform_now }