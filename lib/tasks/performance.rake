
# frozen_string_literal: true

namespace :perf do
  desc 'Completely populate the performance database'
  task populate: :environment do
    unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
      puts 'PERFORMANCE=true bundle exec rails db:drop db:create db:schema:load admin:import_or_update_jurisdictions perf:populate'
      raise 'This task is only for use in a development environment' 
    end

    raise 'This task is meant to run ONLY on a new database' if Patient.count > 0 || User.count > 0

    Rake::Task["perf:setup_performance_test_users"].invoke
  end

  desc 'Configure the users in the database for performance testing'
  task populate_and_simulate_patients: :environment do
    # Configurable variables
    target_patients = (ENV['PATIENT_COUNT']|| 1_000).to_i
    days = (ENV['DAYS'] || 14).to_i

    # Calculated variables
    num_prototype_patients = [(target_patients * 0.1).to_i, 30_000].min

    ENV['LIMIT'] = num_prototype_patients.to_s
    # Reduce num_prototype_patients here since demo:populate grows new patient count with each day
    ENV['COUNT'] = (ENV['COUNT'] || (num_prototype_patients * 0.85) / days).to_i.to_s
    Rake::Task["demo:populate"].invoke

    ENV['COUNT'] = (target_patients - num_prototype_patients).to_s
    Rake::Task["demo:create_bulk_data"].invoke
    # prototype_patients = generate_prototype_patients(num_prototype_patients, counties)
  end

  desc 'Configure the users in the database for performance testing'
  task setup_performance_test_users: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_jurisdictions = Jurisdiction.count
    puts "Creating users for #{num_jurisdictions} jurisdictions\n"

    if !(num_jurisdictions > 50)
      puts ' Jurisdictions were not found! Make sure to run `PERFORMANCE=true bundle exec rake admin:import_or_update_jurisdictions`'
      exit(1)
    end

    num_users = User.count
    unless num_users.zero?
      puts 'This task should only be run when no users exist!'
      puts "There are currently #{num_users} users."
      exit(1)
    end
    users = []

    # Super User at the USA level
    usa = Jurisdiction.find_by_name('USA')
    usa_user = User.create!(
      email: "#{usa.unique_identifier}_super_user@example.com",
      password: '1234567ab!',
      role: Roles::SUPER_USER,
      jurisdiction_id: usa.id,
      force_password_change: false,
      authy_enabled: false,
      authy_enforced: false
    )

    prototype_user = {
      email: usa_user[:email],
      encrypted_password: usa_user[:encrypted_password],
      sign_in_count: usa_user[:sign_in_count],
      current_sign_in_at: usa_user[:current_sign_in_at],
      last_sign_in_at: usa_user[:last_sign_in_at],
      current_sign_in_ip: usa_user[:current_sign_in_ip],
      last_sign_in_ip: usa_user[:last_sign_in_ip],
      failed_attempts: usa_user[:failed_attempts],
      locked_at: usa_user[:locked_at],
      force_password_change: usa_user[:force_password_change],
      jurisdiction_id: usa_user[:jurisdiction_id],
      password_changed_at: usa_user[:password_changed_at],
      created_at: usa_user[:created_at],
      updated_at: usa_user[:updated_at],
      authy_id: usa_user[:authy_id],
      last_sign_in_with_authy: usa_user[:last_sign_in_with_authy],
      authy_enabled: usa_user[:authy_enabled],
      authy_enforced: usa_user[:authy_enforced],
      api_enabled: usa_user[:api_enabled],
      role: usa_user[:role],
      is_api_proxy: usa_user[:is_api_proxy]
    }

    index = 0
    Jurisdiction.all.pluck(:id, :unique_identifier).each do |id, unique_identifier|
      # Create one enroller, admin, public_health, contact_tracer per jurisdiction. Users with these roles are not a large percentage.
      users << create_user(prototype_user, "#{unique_identifier}_enroller@example.com", Roles::ENROLLER, id)
      users << create_user(prototype_user, "#{unique_identifier}_admin@example.com", Roles::ADMIN, id)
      users << create_user(prototype_user, "#{unique_identifier}_epi@example.com", Roles::PUBLIC_HEALTH, id)
      users << create_user(prototype_user, "#{unique_identifier}_contact_tracer@example.com", Roles::CONTACT_TRACER, id)

      # Very few analysts
      users << create_user(prototype_user, "#{unique_identifier}_analyst@example.com", Roles::ANALYST, id) if index % 1 == 10

      # Create 35-times that many public-health enrollers (based on production data)
      35.times do |phe_number|
        users << create_user(prototype_user, "#{unique_identifier}_#{phe_number}_epi_enroller@example.com", Roles::PUBLIC_HEALTH_ENROLLER, id)
      end

      index += 1
    end

    # Import all users
    puts 'Importing all users... '
    User.import users, validate: false

    # Api testing
    OauthApplication.create!(
      name: 'performance-test',
      redirect_uri: 'http://localhost:3000/redirect',
      scopes: 'user/Patient.* user/Observation.read user/QuestionnaireResponse.read',
      uid: 'performance-test-oauth-app-uid',
      secret: 'performance-test-oauth-app-secret'
    ) if OauthApplication.find_by_uid('performance-test-oauth-app-uid').nil?
  end

  def create_user(prototype_user, email, role, jurisdiction_id)
    prototype_user.merge({
      email: email,
      role: role,
      jurisdiction_id: jurisdiction_id
    })
  end

  def create_fake_timestamp(from, to = from + 1.day)
    Faker::Time.between(from: from, to: to > Time.now ? Time.now : to)
  end

  ##
  # Generate patients that can be slighly modified and then imported later
  #
  # Each patient will additionally need
  # - id
  # - responder_id
  # - submission_token
  # - symptom_onset (if isolation)
  # - extended_isolation (if isolation)
  # - last_date_of_exposure (if not continuous exposure or isolation)
  # - updated_at
  # - created_at
  #
  def generate_prototype_patients(num_patients, counties)
    patients = []
    public_health_ids = User.where(role: 'enroller').pluck(:id)
    jurisdiction_ids = Jurisdiction.pluck(:id)
    dummy_submission_token = SecureRandom.urlsafe_base64[0, 10]
    num_patients.times do |i|
      print("\rGenerating prototype patients... #{i + 1} of #{num_patients}")
      patient = Patient.new()
      patient[:sex] = 'Unknown'
      patient[:gender_identity] = 'Chose not to disclose'
      patient[:sexual_orientation] = 'Choose not to disclose'
      patient[:first_name] = i.to_s
      patient[:middle_name] = i.to_s
      patient[:last_name] = i.to_s
      patient[:age] = rand(1..100)
      patient[:date_of_birth] = Date.today - patient[:age].years
      patient[:white] = true
      patient[:black_or_african_american] = true
      patient[:american_indian_or_alaska_native] = true
      patient[:asian] = true
      patient[:native_hawaiian_or_other_pacific_islander] = true
      patient[:ethnicity] = nil
      patient[:primary_language] = 'English'
      patient[:secondary_language] = 'Spanish'
      patient[:interpretation_required] = false
      patient[:nationality] = 'American'
      patient[:user_defined_id_statelocal] = "EX-#{i}"
      patient[:user_defined_id_cdc] = i.to_s
      patient[:user_defined_id_nndss] = i.to_s
      # -------------------------------------------
      patient[:preferred_contact_method] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_method].sample
      patient[:preferred_contact_time] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_time].sample if patient[:preferred_contact_method] != 'E-mailed Web Link'
      patient[:primary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:preferred_contact_method] != 'E-mailed Web Link'
      patient[:primary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:primary_telephone_type].sample if patient[:primary_telephone]
      patient[:secondary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:primary_telephone]
      patient[:secondary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:secondary_telephone_type].sample if patient[:secondary_telephone]
      patient[:email] = "#{i}fake@example.com" if patient[:preferred_contact_method] == 'E-mailed Web Link'
      # -------------------------------------------
      patient[:address_line_1] = 'Address line 1'
      patient[:address_city] = 'Address city'
      patient[:address_state] = counties.keys.sample
      patient[:address_line_2] = 'Secondary address'
      patient[:address_zip] = '12345'
      patient[:address_county] = 'Address county'
      patient[:monitored_address_line_1] = patient[:address_line_1]
      patient[:monitored_address_city] = patient[:address_city]
      patient[:monitored_address_state] = patient[:address_state]
      patient[:monitored_address_line_2] = patient[:address_line_2]
      patient[:monitored_address_zip] = patient[:address_zip]
      patient[:monitored_address_county] = patient[:address_county]
      patient[:monitored_address_line_1] = 'Monitored address line 1'
      patient[:monitored_address_city] = 'Monitored address city'
      patient[:monitored_address_state] = patient[:address_state]
      patient[:monitored_address_line_2] = 'Monitored address line 2'
      patient[:monitored_address_zip] = '12345'
      patient[:monitored_address_county] = 'Monitored address county'
      patient[:foreign_address_line_1] = 'Foreign address line 1'
      patient[:foreign_address_city] = 'Foreign address city'
      patient[:foreign_address_country] = 'Foreign address country'
      patient[:foreign_address_line_2] = 'Foreign address line 2'
      patient[:foreign_address_zip] = 'Foreign address zip'
      patient[:foreign_address_line_3] = 'Foreign address line 3'
      patient[:foreign_address_state] = 'Foreign address state'
      patient[:foreign_monitored_address_line_1] = 'Foreign monitored address line 1'
      patient[:foreign_monitored_address_city] = 'Foreign address city'
      patient[:foreign_monitored_address_state] = 'Foreign monitored address state'
      patient[:foreign_monitored_address_line_2] = 'Foreign monitored address line 2'
      patient[:foreign_monitored_address_zip] = 'Foreign monitored address zip'
      patient[:foreign_monitored_address_county] = 'Foreign monitored address county'
      patient[:port_of_origin] = 'port of origin'
      patient[:date_of_departure] = rand(2).days.ago
      patient[:source_of_report] = 'Other'
      patient[:source_of_report_specify] = 'Specify'
      patient[:flight_or_vessel_number] = 'flight or vessel number'
      patient[:flight_or_vessel_carrier] = 'flight or vessel carrier'
      patient[:port_of_entry_into_usa] = 'Port of entry into usa'
      patient[:date_of_arrival] = Date.today
      patient[:travel_related_notes] = 'Travel notes'
      patient[:additional_planned_travel_type] = 'Domestic'
      patient[:additional_planned_travel_destination_state] = 'Planned travel state'
      patient[:additional_planned_travel_destination] = 'Planned travel destination'
      patient[:additional_planned_travel_port_of_departure] = 'Planned travel departure city'
      patient[:additional_planned_travel_start_date] = rand(6).days.from_now
      patient[:additional_planned_travel_end_date] = patient[:additional_planned_travel_start_date] + rand(10).days
      patient[:additional_planned_travel_related_notes] = 'Planned travel notes'

      # Potential Exposure Info
      patient[:isolation] = rand < 0.75
      if patient[:isolation]
        # patient[:symptom_onset] = today - rand(10).days
        # patient[:extended_isolation] = today + rand(10).days if rand < 0.3
        patient[:user_defined_symptom_onset] = true
      else
        patient[:continuous_exposure] = rand < 0.3
        # patient[:last_date_of_exposure] = today - rand(5).days unless patient[:continuous_exposure]
      end
      patient[:potential_exposure_location] = 'Potential exposure location'
      patient[:potential_exposure_country] = 'Potential exposure country'
      patient[:exposure_notes] = 'Exposure notes'
      patient[:contact_of_known_case] = true
      patient[:contact_of_known_case_id] = '1'
      patient[:member_of_a_common_exposure_cohort] = true
      patient[:member_of_a_common_exposure_cohort_type] = 'Cohort type'
      patient[:travel_to_affected_country_or_area] = true
      patient[:laboratory_personnel] = true
      patient[:laboratory_personnel_facility_name] = 'Laboratory facility name'
      patient[:healthcare_personnel] = true
      patient[:healthcare_personnel_facility_name] = 'Health care facility name'
      patient[:crew_on_passenger_or_cargo_flight] = true
      patient[:was_in_health_care_facility_with_known_cases] = true
      patient[:was_in_health_care_facility_with_known_cases_facility_name] = 'Health care facility name'
      # --------------------------------------------------
      patient[:jurisdiction_id] = jurisdiction_ids.sample
      patient[:assigned_user] = rand(999_999)
      patient[:exposure_risk_assessment] = ValidationHelper::VALID_PATIENT_ENUMS[:exposure_risk_assessment].sample
      patient[:monitoring_plan] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_plan].sample
      # ---------------------------------------------------
      patient[:submission_token] = dummy_submission_token
      patient[:creator_id] = public_health_ids.sample
      patient[:responder_id] = 1 # temporarily set responder_id to 1 to pass schema validation
      # patient_ts = create_fake_timestamp(today, today)
      patient[:created_at] = DateTime.now
      patient[:updated_at] = DateTime.now

      # Update monitoring status
      patient[:case_status] = patient[:isolation] ? ['Confirmed', 'Probable'].sample : ['Suspect', 'Unknown', 'Not a Case', nil].sample
      patient[:monitoring] = rand < 0.95
      patient[:closed_at] = patient[:updated_at] unless patient[:monitoring]
      patient[:monitoring_reason] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_reason].sample if patient[:monitoring].nil?
      patient[:public_health_action] = patient[:isolation] || rand < 0.8 ? 'None' : ValidationHelper::VALID_PATIENT_ENUMS[:public_health_action].sample
      patient[:pause_notifications] = rand < 0.1
      patient[:last_assessment_reminder_sent] = rand(7).days.ago if rand < 0.3

      patients << patient.to_json
    end
  end
end
