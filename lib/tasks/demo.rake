# frozen_string_literal: true

namespace :demo do
  desc 'Clear all sidekiq queues'
  task clear_sidekiq: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    puts 'Clearing sidekiq...'
    require 'sidekiq/api'
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::DeadSet.new.clear
    puts 'sidekiq cleared!'
  end

  desc 'Backup the database'
  task backup_database: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    username = ActiveRecord::Base.configurations.configurations[1].config['username']
    database = ActiveRecord::Base.configurations.configurations[1].config['database']
    system "mysqldump --opt --user=#{username} #{database} > sara_database_#{Time.now.to_i}.sql"
  end

  desc 'Restore the database'
  task restore_database: :environment do
    # Example usage: rake demo:restore_database FILE=sara_database_1606835867.sql
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    raise 'FILE environment variable must be set to run this task' if ENV['FILE'].nil?
    username = ActiveRecord::Base.configurations.configurations[1].config['username']
    database = ActiveRecord::Base.configurations.configurations[1].config['database']
    system "mysql --user=#{username} #{database} < #{ENV['FILE']}"
  end

  # Duplicate existing monitoree data
  # Note: comment out `around_save :inform_responder, if: :responder_id_changed?` in app/models/patient.rb to speed up process
  desc 'Generate N many more monitorees based on existing data'
  task create_bulk_data: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    raise 'This task requires patients to be present in the DB!' unless Patient.count > 0

    num_patients = (ENV['COUNT'] || 100000).to_i
    num_threads = (ENV['FORKS'] || 8).to_i

    Patient.uncached do
      # Found that forks were consistently performing drastically differently when id's were not shuffled
      # i.e. fork 1 was always the slowest between 5 to 10 p/s and fork 8 was always the fastest between 20 to 25 p/s
      # After shuffling, all forks end up at a much more similar 9 to 10 p/s
      patients = Patient.where('patients.responder_id = patients.id')
          .includes(
            :histories,
            :transfers,
            :laboratories,
            :vaccines,
            :close_contacts,
            :contact_attempts,
            assessments: { reported_condition: :symptoms },
            dependents: [
              :histories,
              :transfers,
              :laboratories,
              :vaccines,
              :close_contacts,
              :contact_attempts,
              { assessments: { reported_condition: :symptoms } }
            ]
          )
          .limit(num_patients)

      max_ids = {
        patients: Patient.maximum(:id),
        assessments: Assessment.maximum(:id),
        reported_conditions: ReportedCondition.maximum(:id),
        symptoms: Symptom.maximum(:id),
        histories: History.maximum(:id),
        transfers: Transfer.maximum(:id),
        laboratories: Laboratory.maximum(:id),
        close_contacts: CloseContact.maximum(:id),
        contact_attempts: ContactAttempt.maximum(:id)
      }
      # NEED TO INVESTIGATE IF THIS IS NECESSARY TO IMPORT EVERY X PATIENTS TO CONSERVE MEMORY
      # 6 GB usage @ 30k patients
      # 5 GB usage @ 25k patients
      # 3 GB usage @ 15k patients
      std_num_patient_import_threshold = 1000
      num_patient_import_threshold = std_num_patient_import_threshold
      results = blank_results
      t1 = Time.now
      num_to_create = num_patients
      # Patients per second appears to be mainly bottlenecked by the time it
      # takes to fetch all of the patient and related data from MySQL.
      # report = MemoryProfiler.report do
      while results[:patients_created] < num_to_create do
        break if results[:patients_created] >= num_to_create

        patients.find_in_batches(batch_size: 100) do |group|
          break if results[:patients_created] >= num_to_create
          group.each do |patient|
            break if results[:patients_created] >= num_to_create
            deep_duplicate_patient(max_ids, results, patient)
            print "\r#{(results[:patients_created] / (Time.now - t1)).truncate(2)} patients/sec | #{results[:patients_created]}/#{num_to_create} patients           "

            # Import in batches
            if results[:patients_created] > num_patient_import_threshold
              import_deep_duplicate(results)
              num_patient_import_threshold = results[:patients_created] + std_num_patient_import_threshold
              total_created = results[:patients_created]
              results = blank_results
              results[:patients_created] = total_created
            end
          end
        end
      end
      # end
      # report.pretty_print(scale_bytes: true)

      import_deep_duplicate(results)

      elapsed = Time.now - t1
    puts "\n\nCreated #{results[:patients_created]} patients in #{elapsed} seconds. (#{(results[:patients_created] / elapsed).truncate(2)} patients / sec)"
    end
  end

  desc 'Configure the database for demo use'
  task setup: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    #####################################

    print 'Gathering jurisdictions...'

    jurisdictions = {}

    jurisdictions[:usa] = Jurisdiction.where(name: 'USA').first
    jurisdictions[:state1] = Jurisdiction.where(name: 'State 1').first
    jurisdictions[:state2] = Jurisdiction.where(name: 'State 2').first
    jurisdictions[:county1] = Jurisdiction.where(name: 'County 1').first
    jurisdictions[:county2] = Jurisdiction.where(name: 'County 2').first
    jurisdictions[:county3] = Jurisdiction.where(name: 'County 3').first
    jurisdictions[:county4] = Jurisdiction.where(name: 'County 4').first

    if jurisdictions.has_value?(nil)
      puts ' Demonstration jurisdictions were not found! Make sure to run `bundle exec rake admin:import_or_update_jurisdictions` with the demonstration jurisdictions.yml'
      exit(1)
    end

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    enroller1 = User.create(email: 'state1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    enroller2 = User.create(email: 'localS1C1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    enroller3 = User.create(email: 'localS1C2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    enroller4 = User.create(email: 'state2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    enroller5 = User.create(email: 'localS2C3_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county3], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    enroller6 = User.create(email: 'localS2C4_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county4], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    ph1 = User.create(email: 'state1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    ph2 = User.create(email: 'localS1C1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    ph3 = User.create(email: 'localS1C2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    ph4 = User.create(email: 'state2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    ph5 = User.create(email: 'localS2C3_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county3], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    ph6 = User.create(email: 'localS2C4_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county4], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    phe1 = User.create(email: 'epi_enroller_all@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    phe2 = User.create(email: 'state1_epi_enroller@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    admin1 = User.create(email: 'admin1@example.com', password: '1234567ab!', role: Roles::ADMIN, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    analyst1 = User.create(email: 'analyst_all@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    analyst2 = User.create(email: 'state1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    analyst3 = User.create(email: 'localS1C1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating super users...'

    super_user1 = User.create(email: 'usa_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    super_user2 = User.create(email: 'state1_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating contract tracer users...'

    contact_tracer1 = User.create(email: 'usa_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    contact_tracer2 = User.create(email: 'state1_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating demo Doorkeeper OAuth application...'

    OauthApplication.create(name: 'demo', redirect_uri: 'http://localhost:3000/redirect', scopes: 'user/Patient.* user/Observation.read user/QuestionnaireResponse.read', uid: 'demo-oauth-app-uid', secret: 'demo-oauth-app-secret')

    puts ' done!'

    #####################################

    printf("\n")
  end

  desc 'Add synthetic patient/monitoree data to the database for an initial time period in days'
  task populate: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    # Remove analytics that are created in admin:import_or_update_jurisdictions task
    Analytic.delete_all

    limit = (ENV['LIMIT'] || 1_500_000).to_i
    days = (ENV['DAYS'] || 14).to_i
    num_patients_today = (ENV['COUNT'] || 25).to_i
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all
    assigned_users_range = (1..9_999).to_a.freeze
    assigned_users = Hash[jurisdictions.pluck(:id).map {|id| [id, assigned_users_range]}]
    case_ids = Hash[jurisdictions.pluck(:id).map { |id| [id, 15.times.map { |n| Faker::Number.leading_zero_number(digits: 8) }] }]

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))
    available_lang_codes = Languages.all_languages.keys.to_a.map(&:to_s)

    # Freeze beginning of day outside loop to prevent problems when script is called over midnight
    beginning_of_today = DateTime.now.beginning_of_day
    created_patients = 0

    # Get symptoms for each jurisdiction
    # Used in demo_populate_assessments
    print 'Fetching threshold_conditions for all jurisdictions... '
    threshold_conditions = {}
    jurisdictions.each do |jurisdiction|
      threshold_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
      threshold_conditions[jurisdiction[:id]] = {
        hash: threshold_condition[:threshold_condition_hash],
        symptoms: threshold_condition.symptoms
      }
    end
    puts 'done.'

    days.times do |day|
      if limit - created_patients <= 0
        puts "Patient limit of #{limit} has been reached!"
        break
      end

      # Calculate number of days ago
      days_ago = days - day
      beginning_of_day = beginning_of_today - days_ago.days

      # Create the patients for this day
      printf("Simulating day #{day + 1} (#{beginning_of_day.to_date}):\n")

      # Populate patients, assessments, laboratories, transfers, histories, analytics
      demo_populate_day(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions)
      created_patients += num_patients_today

      # Cases increase 10-20% every day
      num_patients_today += (num_patients_today * (0.1 + (rand / 10))).round
      # Protect from going over the patient limit
      num_patients_today = limit - created_patients if limit - (created_patients + num_patients_today) <= 0

      printf("\n")
    end
  end
  
  desc 'Add synthetic patient/monitoree data to the database for a single day (today)'
  task update: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_patients_today = (ENV['COUNT'] || 25).to_i * 20
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all
    assigned_users = Hash[jurisdictions.map { |jur| [jur[:id], jur.assigned_users] }]
    case_ids = Hash[jurisdictions.map { |jur| [jur[:id], jur.immediate_patients.where.not(contact_of_known_case_id: nil).distinct.pluck(:contact_of_known_case_id).sort] }]

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))
    available_lang_codes = Languages.all_languages.keys.to_a.map(&:to_s)

    printf("Simulating today\n")

    # Get symptoms for each jurisdiction
    # Used in demo_populate_assessments
    print 'Fetching threshold_conditions for all jurisdictions... '
    threshold_conditions = {}
    jurisdictions.each do |jurisdiction|
      threshold_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
      threshold_conditions[jurisdiction[:id]] = {
        hash: threshold_condition[:threshold_condition_hash],
        symptoms: threshold_condition.symptoms
      }
    end
    puts 'done.'

    demo_populate_day(DateTime.now.beginning_of_day, num_patients_today, 0, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions)
  end

  def demo_populate_day(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions)
    # Transactions speeds things up a bit
    ActiveRecord::Base.transaction do
      # Patients created before today
      existing_patients = Patient.monitoring_open.where('created_at < ?', beginning_of_day)

      # Create patients
      demo_populate_patients(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, counties, available_lang_codes)

      # Create assessments
      demo_populate_assessments(beginning_of_day, days_ago, existing_patients, threshold_conditions)

      # Create laboratories
      demo_populate_laboratories(beginning_of_day, days_ago, existing_patients)

      # Create vaccinations
      demo_populate_vaccines(beginning_of_day, days_ago, existing_patients)

      # Create close contacts
      demo_populate_close_contacts(beginning_of_day, days_ago, existing_patients)

      # Create transfers
      demo_populate_transfers(beginning_of_day, existing_patients, jurisdictions, assigned_users)

      # Create close contacts
      demo_populate_close_contacts(beginning_of_day, days_ago, existing_patients)

      # Create contact attempts
      demo_populate_contact_attempts(beginning_of_day, existing_patients)
    end

    # Needs to be in a separate transaction
    ActiveRecord::Base.transaction do
      # Update linelist fields
      demo_populate_linelists
    end

    # Cache analytics
    demo_cache_analytics(beginning_of_day) if cache_analytics
  end

  def performance_populate_patients(num_patients_today)
    printf('Generating patients...')
    patients = []
    public_health_ids = User.where(role: 'enroller').pluck(:id)
    num_patients_today.times do |i|
      patient = Patient.new()
      patient[:sex] = 'Unknown'
      patient[:gender_identity] = 'Chose not to disclose'
      patient[:sexual_orientation] = 'Choose not to disclose'
      patient[:first_name] = i.to_s
      patient[:middle_name] = i.to_s
      patient[:last_name] = i.to_s
      patient[:age] = ((Date.today - patient[:date_of_birth]) / 365.25).round
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
      patient[:isolation] = days_ago > 10 ? rand < 0.9 : rand < 0.4
      if patient[:isolation]
        patient[:symptom_onset] = today - rand(10).days
        patient[:user_defined_symptom_onset] = true
      else
        patient[:continuous_exposure] = rand < 0.3
        patient[:last_date_of_exposure] = today - rand(5).days unless patient[:continuous_exposure]
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
      patient[:jurisdiction_id] = jurisdictions.sample[:id]
      patient[:assigned_user] = rand(999_999)
      patient[:exposure_risk_assessment] = ValidationHelper::VALID_PATIENT_ENUMS[:exposure_risk_assessment].sample
      patient[:monitoring_plan] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_plan].sample
      # ---------------------------------------------------
      patient[:submission_token] = SecureRandom.urlsafe_base64[0, 10]
      patient[:creator_id] = public_health_ids.sample
      patient[:responder_id] = 1 # temporarily set responder_id to 1 to pass schema validation
      patient_ts = create_fake_timestamp(today, today)
      patient[:created_at] = patient_ts
      patient[:updated_at] = patient_ts

      # Update monitoring status
      patient[:extended_isolation] = today + rand(10).days if patient[:isolation] && rand < 0.3
      patient[:case_status] = patient[:isolation] ? ['Confirmed', 'Probable'].sample : ['Suspect', 'Unknown', 'Not a Case', nil].sample
      patient[:monitoring] = rand < 0.95
      patient[:closed_at] = patient[:updated_at] unless patient[:monitoring]
      patient[:monitoring_reason] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_reason].sample if patient[:monitoring].nil?
      patient[:public_health_action] = patient[:isolation] || rand < 0.8 ? 'None' : ValidationHelper::VALID_PATIENT_ENUMS[:public_health_action].sample
      patient[:pause_notifications] = rand < 0.1
      patient[:last_assessment_reminder_sent] = rand(7).days.ago if rand < 0.3

      patients << patient
    end
  end

  def demo_populate_patients(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, counties, available_lang_codes)
    territory_names = ['American Samoa', 'District of Columbia', 'Federated States of Micronesia', 'Guam', 'Marshall Islands', 'Northern Mariana Islands',
                       'Palau', 'Puerto Rico', 'Virgin Islands'].freeze

    printf("Generating monitorees...")
    patients = []
    histories = []
    enroller_ids = User.all.where(role: 'enroller').pluck(:id)
    enroller_emails = User.all.where(role: 'enroller').pluck(:email)
    num_patients_today.times do |i|
      printf("\rGenerating monitoree #{i + 1} of #{num_patients_today}...") unless ENV['APP_IN_CI']
      patient = Patient.new()

      # Identification
      sex = Faker::Gender.binary_type
      patient[:sex] = rand < 0.9 ? sex : 'Unknown' if rand < 0.9
      patient[:gender_identity] = ValidationHelper::VALID_PATIENT_ENUMS[:gender_identity].sample if rand < 0.7
      patient[:sexual_orientation] = ValidationHelper::VALID_PATIENT_ENUMS[:sexual_orientation].sample if rand < 0.6
      patient[:first_name] = "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
      patient[:middle_name] = "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
      patient[:date_of_birth] = Faker::Date.birthday(min_age: 1, max_age: 85)
      patient[:age] = ((Date.today - patient[:date_of_birth]) / 365.25).round
      if rand < 0.9
        exclusive = rand < 0.75
        ValidationHelper::RACE_OPTIONS[exclusive ? :exclusive : :non_exclusive].map { |option| option[:race] }.sample(exclusive ? 1 : rand(0..4)).each { |race| patient[race] = true }
      end
      patient[:ethnicity] = rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino'
      patient[:primary_language] = rand < 0.7 ? 'eng' : available_lang_codes.sample
      patient[:secondary_language] = available_lang_codes.sample if rand < 0.4
      patient[:interpretation_required] = rand < 0.15
      patient[:nationality] = Faker::Nation.nationality if rand < 0.6
      patient[:user_defined_id_statelocal] = "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:user_defined_id_cdc] = Faker::Code.npi if rand < 0.2
      patient[:user_defined_id_nndss] = Faker::Code.rut if rand < 0.2

      # Contact Information
      patient[:preferred_contact_method] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_method].sample
      patient[:preferred_contact_time] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_time].sample if patient[:preferred_contact_method] != 'E-mailed Web Link' && rand < 0.6
      patient[:primary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:preferred_contact_method] != 'E-mailed Web Link' || rand < 0.5
      patient[:primary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:primary_telephone_type].sample if patient[:primary_telephone]
      patient[:secondary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:primary_telephone] && rand < 0.5
      patient[:secondary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:secondary_telephone_type].sample if patient[:secondary_telephone]
      patient[:email] = "#{rand(1000000000..9999999999)}fake@example.com" if patient[:preferred_contact_method] == 'E-mailed Web Link' || rand < 0.5

      # Address
      if rand < 0.8
        patient[:address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:address_city] = Faker::Address.city if rand < 0.95
        patient[:address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
        patient[:address_line_2] = Faker::Address.secondary_address if rand < 0.4
        patient[:address_zip] = Faker::Address.zip_code if rand < 0.95
        if rand < 0.85 && counties.key?(patient[:address_state])
          patient[:address_county] = rand < 0.95 ? counties[patient[:address_state]].sample : Faker::Address.community
        end
        if rand < 0.7
          patient[:monitored_address_line_1] = patient[:address_line_1]
          patient[:monitored_address_city] = patient[:address_city]
          patient[:monitored_address_state] = patient[:address_state]
          patient[:monitored_address_line_2] = patient[:address_line_2]
          patient[:monitored_address_zip] = patient[:address_zip]
          patient[:monitored_address_county] = patient[:address_county]
        else
          patient[:monitored_address_line_1] = Faker::Address.street_address if rand < 0.95
          patient[:monitored_address_city] = Faker::Address.city if rand < 0.95
          patient[:monitored_address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
          patient[:monitored_address_line_2] = Faker::Address.secondary_address if rand < 0.4
          patient[:monitored_address_zip] = Faker::Address.zip_code if rand < 0.95
          if rand < 0.85 && counties.key?(patient[:monitored_address_state])
            patient[:monitored_address_county] = rand < 0.95 ? counties[patient[:monitored_address_state]].sample : Faker::Address.community
          end
        end
      else
        patient[:foreign_address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:foreign_address_city] = Faker::Nation.capital_city if rand < 0.95
        patient[:foreign_address_country] = Faker::Address.country if rand < 0.95
        patient[:foreign_address_line_2] = Faker::Address.secondary_address if rand < 0.6
        patient[:foreign_address_zip] = Faker::Address.zip_code if rand < 0.95
        patient[:foreign_address_line_3] = Faker::Address.secondary_address if patient[:foreign_address_line_2] && rand < 0.4
        patient[:foreign_address_state] = Faker::Address.community if rand < 0.7
        patient[:foreign_monitored_address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:foreign_monitored_address_city] = Faker::Nation.capital_city if rand < 0.95
        patient[:foreign_monitored_address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
        patient[:foreign_monitored_address_line_2] = Faker::Address.secondary_address if rand < 0.4
        patient[:foreign_monitored_address_zip] = Faker::Address.zip_code if rand < 0.95
        if rand < 0.85 && counties.key?(patient[:foreign_monitored_address_state])
          patient[:foreign_monitored_address_county] = rand < 0.95 ? counties[patient[:foreign_monitored_address_state]].sample : Faker::Address.community
        end
      end

      # Arrival information
      if rand < 0.7
        patient[:port_of_origin] = Faker::Address.city
        patient[:date_of_departure] = beginning_of_day - (rand < 0.3 ? 1.day : 0.days)
        patient[:source_of_report] = ValidationHelper::VALID_PATIENT_ENUMS[:source_of_report].sample if rand < 0.7
        patient[:source_of_report_specify] = Faker::TvShows::SiliconValley.invention if patient[:source_of_report] == 'Other'
        patient[:flight_or_vessel_number] = "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}"
        patient[:flight_or_vessel_carrier] = "#{Faker::Name.first_name} Airlines"
        patient[:port_of_entry_into_usa] = Faker::Address.city
        patient[:date_of_arrival] = beginning_of_day
        patient[:travel_related_notes] = Faker::GreekPhilosophers.quote if rand < 0.3
      end

      # Additional planned travel
      if rand < 0.3
        if rand < 0.7
          patient[:additional_planned_travel_type] = 'Domestic'
          patient[:additional_planned_travel_destination_state] = rand > 0.5 ? Faker::Address.state : territory_names[rand(territory_names.count)]
        else
          patient[:additional_planned_travel_type] = 'International'
          patient[:additional_planned_travel_destination_country] = Faker::Address.country
        end
        patient[:additional_planned_travel_destination] = Faker::Address.city
        patient[:additional_planned_travel_port_of_departure] = Faker::Address.city
        patient[:additional_planned_travel_start_date] = beginning_of_day + rand(6).days
        patient[:additional_planned_travel_end_date] = patient[:additional_planned_travel_start_date] + rand(10).days
        patient[:additional_planned_travel_related_notes] = Faker::ChuckNorris.fact if rand < 0.4
      end

      # Potential Exposure Info
      patient[:isolation] = days_ago > 10 ? rand < 0.9 : rand < 0.4
      if patient[:isolation]
        if rand < 0.7
          patient[:symptom_onset] = beginning_of_day - rand(10).days
          patient[:user_defined_symptom_onset] = true
        end
      else
        patient[:continuous_exposure] = rand < 0.3
        patient[:last_date_of_exposure] = beginning_of_day - rand(5).days unless patient[:continuous_exposure]
      end
      patient[:potential_exposure_location] = Faker::Address.city if rand < 0.7
      patient[:potential_exposure_country] = Faker::Address.country if rand < 0.8
      patient[:exposure_notes] = Faker::Games::LeagueOfLegends.quote if rand < 0.5
      patient[:jurisdiction_id] = jurisdictions.sample[:id]
      patient[:assigned_user] = assigned_users[patient[:jurisdiction_id]].sample if rand < 0.8
      patient[:exposure_risk_assessment] = ValidationHelper::VALID_PATIENT_ENUMS[:exposure_risk_assessment].sample
      patient[:monitoring_plan] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_plan].sample
      if rand < 0.85
        patient[:contact_of_known_case] = rand < 0.5
        patient[:contact_of_known_case_id] = case_ids[patient[:jurisdiction_id]].sample(rand(1..3)).join(', ') if patient[:contact_of_known_case] && rand < 0.9
        patient[:member_of_a_common_exposure_cohort] = rand < 0.35
        patient[:member_of_a_common_exposure_cohort_type] = Faker::Superhero.name if patient[:member_of_a_common_exposure_cohort] && rand < 0.5
        patient[:travel_to_affected_country_or_area] = rand < 0.1
        patient[:laboratory_personnel] = rand < 0.25
        patient[:laboratory_personnel_facility_name] = Faker::Company.name if patient[:laboratory_personnel] && rand < 0.5
        patient[:healthcare_personnel] = rand < 0.2
        patient[:healthcare_personnel_facility_name] = Faker::FunnyName.name if patient[:healthcare_personnel] && rand < 0.5
        patient[:crew_on_passenger_or_cargo_flight] = rand < 0.25
        patient[:was_in_health_care_facility_with_known_cases] = rand < 0.15
        patient[:was_in_health_care_facility_with_known_cases_facility_name] = Faker::GreekPhilosophers.name if patient[:was_in_health_care_facility_with_known_cases] && rand < 0.15
      end

      # Other fields populated upon enrollment
      patient[:submission_token] = SecureRandom.urlsafe_base64[0, 10]
      patient[:creator_id] = enroller_ids.sample
      patient[:responder_id] = 1 # temporarily set responder_id to 1 to pass schema validation
      patient_ts = create_fake_timestamp(beginning_of_day)
      patient[:created_at] = patient_ts
      patient[:updated_at] = patient_ts

      # Update monitoring status
      patient[:extended_isolation] = beginning_of_day + rand(10).days if patient[:isolation] && rand < 0.3
      patient[:case_status] = patient[:isolation] ? ['Confirmed', 'Probable'].sample : ['Suspect', 'Unknown', 'Not a Case', nil].sample
      patient[:monitoring] = rand < 0.95
      patient[:closed_at] = patient[:updated_at] unless patient[:monitoring]
      patient[:monitoring_reason] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_reason].sample if patient[:monitoring].nil?
      patient[:public_health_action] = patient[:isolation] || rand < 0.8 ? 'None' : ValidationHelper::VALID_PATIENT_ENUMS[:public_health_action].sample
      patient[:pause_notifications] = rand < 0.1
      patient[:last_assessment_reminder_sent] = beginning_of_day - rand(7).days if rand < 0.3

      patients << patient
    end
    print ' importing monitorees...'
    Patient.import! patients
    new_patients = Patient.where('created_at >= ?', beginning_of_day)
    new_patients.update_all('responder_id = id')

    # Create household members (10-20% of patients are managed by a HoH)
    print ' setting dependents...'
    new_children = new_patients.limit(new_patients.count * rand(10..20) / 100).order('RAND()')
    new_parents = new_patients - new_children
    new_children_updates =  new_children.map { |new_child|
      parent = new_parents.sample
      { responder_id: parent[:id], jurisdiction_id: parent[:jurisdiction_id] }
    }
    Patient.update(new_children.map { |p| p[:id] }, new_children_updates)

    # Create first positive lab for patients with no reported symptoms
    laboratories = []
    asymptomatic_cases = new_patients.where(isolation: true, symptom_onset: nil)
    user_emails = Hash[User.where(id: asymptomatic_cases.distinct.pluck(:creator_id)).pluck(:id, :email)]
    asymptomatic_cases.each do |patient|
      laboratories << Laboratory.new(
        patient_id: patient[:id],
        lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'].sample,
        specimen_collection: create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day),
        report: create_fake_timestamp(beginning_of_day),
        result: 'positive',
        created_at: patient[:created_at],
        updated_at: patient[:created_at]
      )
      histories << History.new(
        patient_id: patient[:id],
        created_by: user_emails[patient[:creator_id]],
        comment: "User added a new lab result.",
        history_type: 'Lab Result',
        created_at: patient[:created_at],
        updated_at: patient[:created_at]
      )
    end
    Laboratory.import! laboratories

    puts "\n" unless ENV['APP_IN_CI']
    new_patients.each_with_index do |patient, i|
      printf("\rGenerating histories for monitoree #{i + 1} of #{new_patients.size}...") unless ENV['APP_IN_CI']
      # enrollment
      histories << History.new(
        patient_id: patient[:id],
        created_by: enroller_emails.sample,
        comment: 'User enrolled monitoree.',
        history_type: 'Enrollment',
        created_at: patient[:created_at],
        updated_at: patient[:created_at],
      )
      # monitoring status
      histories << History.new(
        patient_id: patient[:id],
        created_by: enroller_emails.sample,
        comment: "User changed monitoring status to \"Not Monitoring\". Reason: #{patient[:monitoring_reason]}",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:monitoring]
      # exposure risk assessment
      histories << History.new(
        created_by: enroller_emails.sample,
        comment: "User changed exposure risk assessment to \"#{patient[:exposure_risk_assessment]}\".",
        patient_id: patient[:id],
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:exposure_risk_assessment].nil?
      # case status
      histories << History.new(
        patient_id: patient[:id],
        created_by: enroller_emails.sample,
        comment: "User changed case status to \"#{patient[:case_status]}\", and chose to \"Continue Monitoring in Isolation Workflow\".",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:case_status].nil?
      # public health action
      histories << History.new(
        patient_id: patient[:id],
        created_by: enroller_emails.sample,
        comment: "User changed latest public health action to \"#{patient[:public_health_action]}\".",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:public_health_action] == 'None'
      # pause notifications
      histories << History.new(
        patient_id: patient[:id],
        created_by: enroller_emails.sample,
        comment: "User paused notifications for this monitoree.",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:pause_notifications] == false
    end
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_assessments(beginning_of_day, days_ago, existing_patients, threshold_conditions)
    printf("Generating assessments...")
    assessments = []
    assessment_receipts = []
    histories = []
    public_health_emails = User.where(role: 'public_health').pluck(:email)
    patient_jur_ids_and_sub_tokens = existing_patients.limit(existing_patients.count * rand(55..60) / 100).order('RAND()').pluck(:id, :jurisdiction_id, :submission_token)
    patient_jur_ids_and_sub_tokens.each_with_index do |(patient_id, jur_id, sub_token), index|
      printf("\rGenerating assessment #{index+1} of #{patient_jur_ids_and_sub_tokens.length}...") unless ENV['APP_IN_CI']
      assessment_ts = create_fake_timestamp(beginning_of_day)
      assessments << Assessment.new(
        patient_id: patient_id,
        symptomatic: false,
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      assessment_receipts << AssessmentReceipt.new(
        submission_token: sub_token,
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: 'Sara Alert System',
        comment: "Sara Alert sent a report reminder to this monitoree via Telephone call.",
        history_type: History::HISTORY_TYPES[:report_reminder],
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_emails.sample,
        comment: "User created a new report.",
        history_type: 'Report Created',
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
    end

    # Create assessment receipts and replace any existing ones
    AssessmentReceipt.where(submission_token: assessment_receipts.map{ |assessment_receipt| assessment_receipt[:submission_token] }).destroy_all
    AssessmentReceipt.import! assessment_receipts
    Assessment.import! assessments
    printf(" done.\n")

    # Get symptoms for each jurisdiction
    # threshold_conditions = {}
    # jurisdictions.each do |jurisdiction|
    #   threshold_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
    #   threshold_conditions[jurisdiction[:id]] = {
    #     hash: threshold_condition[:threshold_condition_hash],
    #     symptoms: threshold_condition.symptoms
    #   }
    # end

    printf("Generating condition for assessments...")
    reported_conditions = []
    new_assessments = Assessment.where('assessments.created_at >= ?', beginning_of_day).joins(:patient)
    new_assessments.each_with_index do |assessment, index|
      printf("\rGenerating condition for assessment #{index+1} of #{new_assessments.length}...") unless ENV['APP_IN_CI']
      reported_conditions << ReportedCondition.new(
        assessment_id: assessment[:id],
        threshold_condition_hash: threshold_conditions[assessment.patient.jurisdiction_id][:hash],
        created_at: assessment[:created_at],
        updated_at: assessment[:updated_at]
      )
    end
    ReportedCondition.import! reported_conditions
    printf(" done.\n")

    # Create earlier symptom onset dates to meet isolation symptomatic non test based requirement
    symptomatic_assessments = new_assessments.where('patients.symptom_onset IS NOT NULL')
                                             .or(
                                               new_assessments.where('patients.isolation = ?', false)
                                             )
                                             .where('patient_id % 4 <> 0')
                                             .limit(new_assessments.count * (days_ago > 10  ? rand(75..80) : rand(20..25)) / 100)
                                             .order('RAND()')

    printf("Generating symptoms for assessments...")
    symptoms = []
    new_reported_conditions = ReportedCondition.where('conditions.created_at >= ?', beginning_of_day).joins(assessment: :reported_condition)
    new_reported_conditions.each_with_index do |reported_condition, index|
      printf("\rGenerating symptoms for assessment #{index+1} of #{new_reported_conditions.length}...") unless ENV['APP_IN_CI']
      threshold_symptoms = threshold_conditions[reported_condition.assessment.patient.jurisdiction_id][:symptoms]
      symptomatic_assessment = symptomatic_assessments.include?(reported_condition.assessment)
      num_symptomatic_symptoms = ((rand ** 2) * threshold_symptoms.length).floor # creates a distribution favored towards fewer symptoms
      symptomatic_symptoms = symptomatic_assessment ? threshold_symptoms.to_a.shuffle[1..num_symptomatic_symptoms] : []

      threshold_symptoms.each do |threshold_symptom|
        symptomatic_symptom = %w[fever used-a-fever-reducer].include?(threshold_symptom[:name]) && rand < 0.8 ? false : symptomatic_symptoms.include?(threshold_symptom)
        symptoms << Symptom.new(
          condition_id: reported_condition[:id],
          name: threshold_symptom[:name],
          label: threshold_symptom[:label],
          notes: threshold_symptom[:notes],
          type: threshold_symptom[:type],
          bool_value: threshold_symptom[:type] == 'BoolSymptom' ? symptomatic_symptom : nil,
          float_value: threshold_symptom[:type] == 'FloatSymptom' ? ((threshold_symptom.value || 0) + rand(10.0) * (symptomatic_symptom ? -1 : 1)) : nil,
          int_value: threshold_symptom[:type] == 'IntSymptom' ? ((threshold_symptom.value || 0 )+ rand(10) * (symptomatic_symptom ? -1 : 1)) : nil,
          created_at: reported_condition[:created_at],
          updated_at: reported_condition[:updated_at]
        )
      end
    end
    Symptom.import! symptoms
    printf(" done.\n")

    printf("Updating symptomatic statuses...")
    assessment_symptomatic_statuses = {}
    patient_symptom_onset_date_updates = {}
    symptomatic_patients_without_symptom_onset_ids = Patient.where(id: symptomatic_assessments.pluck(:patient_id), symptom_onset: nil).ids
    symptomatic_assessments.each_with_index do |assessment, index|
      printf("\rUpdating symptomatic status #{index+1} of #{symptomatic_assessments.length}...") unless ENV['APP_IN_CI']
      if assessment.symptomatic?
        assessment_symptomatic_statuses[assessment[:id]] = { symptomatic: true }
        patient_symptom_onset_date_updates[assessment[:patient_id]] = { symptom_onset: assessment[:created_at] }
      end
    end
    Assessment.update(assessment_symptomatic_statuses.keys, assessment_symptomatic_statuses.values)
    Patient.update(patient_symptom_onset_date_updates.keys, patient_symptom_onset_date_updates.values)
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_laboratories(beginning_of_day, days_ago, existing_patients)
    printf("Generating laboratories...")
    laboratories = []
    histories = []
    public_health_emails = User.where(role: 'public_health').pluck(:email)
    isolation_patients = existing_patients.where(isolation: true)
    if days_ago > 10
      patient_ids_lab = isolation_patients.limit(isolation_patients.count * rand(90..95) / 100).order('RAND()').pluck(:id)
    else
      patient_ids_lab = isolation_patients.limit(isolation_patients.count * rand(20..30) / 100).order('RAND()').pluck(:id)
    end
    patient_ids_lab.each_with_index do |patient_id, index|
      printf("\rGenerating laboratory #{index+1} of #{patient_ids_lab.length}...") unless ENV['APP_IN_CI']
      lab_ts = create_fake_timestamp(beginning_of_day)
      if days_ago > 10
        result = (Array.new(12, 'positive') + ['negative', 'indeterminate', 'other']).sample
      elsif patient_id % 4 == 0
        result = ['negative', 'indeterminate', 'other'].sample
      else
        result = (Array.new(1, 'positive') + Array.new(1, 'negative') + ['indeterminate', 'other']).sample
      end
      laboratories << Laboratory.new(
        patient_id: patient_id,
        lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'].sample,
        specimen_collection: create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day),
        report: create_fake_timestamp(beginning_of_day),
        result: result,
        created_at: lab_ts,
        updated_at: lab_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_emails.sample,
        comment: "User added a new lab result.",
        history_type: 'Lab Result',
        created_at: lab_ts,
        updated_at: lab_ts
      )
    end
    Laboratory.import! laboratories
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_vaccines(beginning_of_day, days_ago, existing_patients)
    printf("Generating vaccinations...")
    vaccines = []
    histories = []
    patient_ids = existing_patients.limit(existing_patients.count * rand(15..25) / 100).order('RAND()').pluck(:id)
    public_health_emails = User.where(role: 'public_health').pluck(:email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating vaccine #{index+1} of #{patient_ids.length}...")
      vaccine_ts = create_fake_timestamp(beginning_of_day)
      group_name = Vaccine.group_name_options.sample
      notes = rand < 0.5 ? Faker::Games::LeagueOfLegends.quote : nil
      vaccines << Vaccine.new(
        patient_id: patient_id,
        group_name: group_name,
        product_name: Vaccine.product_name_options(group_name).sample,
        administration_date: create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day + 1.day),
        dose_number: Vaccine::DOSE_OPTIONS.sample,
        notes: notes,
        created_at: vaccine_ts,
        updated_at: vaccine_ts
      )

      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_emails.sample,
        comment: "User added a new vaccine.",
        history_type: History::HISTORY_TYPES[:vaccination],
        created_at: vaccine_ts,
        updated_at: vaccine_ts
      )
    end
    Vaccine.import! vaccines
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_close_contacts(beginning_of_day, days_ago, existing_patients)
    printf("Generating close contacts...")
    close_contacts = []
    histories = []
    patient_ids = existing_patients.limit(existing_patients.count * rand(15..25) / 100).order('RAND()').pluck(:id)
    enrolled_close_contacts_ids = existing_patients.where.not(id: patient_ids).limit(existing_patients.count * rand(5..15) / 100).order('RAND()').pluck(:id)
    enrolled_close_contacts = Patient.where(id: enrolled_close_contacts_ids).pluck(:id, :first_name, :last_name, :primary_telephone, :email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating close contact #{index+1} of #{patient_ids.length}...") unless ENV['APP_IN_CI']
      close_contact_ts = create_fake_timestamp(beginning_of_day)
      close_contact = {
        patient_id: patient_id,
        created_at: close_contact_ts,
        updated_at: close_contact_ts,
        notes: rand < 0.7 ? Faker::Hacker.say_something_smart : nil,
        contact_attempts: rand < 0.4 ? rand(1..5) : nil
      }
      if index < enrolled_close_contacts.size
        close_contact[:enrolled_id] = enrolled_close_contacts[index][0]
        close_contact[:first_name] = enrolled_close_contacts[index][1]
        close_contact[:last_name] = enrolled_close_contacts[index][2]
        close_contact[:primary_telephone] = enrolled_close_contacts[index][3]
        close_contact[:email] = enrolled_close_contacts[index][4]
      else
        close_contact[:enrolled_id] = nil
        close_contact[:first_name] = "#{rand < 0.5 ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
        close_contact[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
        close_contact[:primary_telephone] = rand < 0.85 ? "+155555501#{rand(9)}#{rand(9)}" : nil
        close_contact[:email] = rand < 0.75 ? "#{rand(1000000000..9999999999)}fake@example.com" : nil
      end
      close_contacts << close_contact
      histories << History.new(
        patient_id: patient_id,
        created_by: 'Sara Alert System',
        comment: "User created a new close contact.",
        history_type: 'Close Contact'
      )
    end
    CloseContact.import! close_contacts
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_transfers(beginning_of_day, existing_patients, jurisdictions, assigned_users)
    printf("Generating transfers...")
    transfers = []
    histories = []
    patient_updates = {}
    public_health_ids = User.where(role: 'public_health').pluck(:id)
    public_health_emails = User.where(role: 'public_health').pluck(:email)
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path)]
    patients_transfer = existing_patients.limit(existing_patients.count * rand(5..10) / 100).order('RAND()').pluck(:id, :jurisdiction_id, :assigned_user)
    patients_transfer.each_with_index do |(patient_id, jur_id, assigned_user), index|
      printf("\rGenerating transfer #{index+1} of #{patients_transfer.length}...") unless ENV['APP_IN_CI']
      transfer_ts = create_fake_timestamp(beginning_of_day)
      to_jurisdiction = (jurisdictions.ids - [jur_id]).sample
      patient_updates[patient_id] = {
        jurisdiction_id: to_jurisdiction,
        assigned_user: assigned_user.nil? ? nil : assigned_users[to_jurisdiction].sample
      }
      transfers << Transfer.new(
        patient_id: patient_id,
        to_jurisdiction_id: to_jurisdiction,
        from_jurisdiction_id: jur_id,
        who_id: public_health_ids.sample,
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_emails.sample,
        comment: "User changed jurisdiction from \"#{jurisdiction_paths[jur_id]}\" to #{jurisdiction_paths[to_jurisdiction]}.",
        history_type: 'Monitoring Change',
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
    end
    Patient.update(patient_updates.keys, patient_updates.values)
    Transfer.import! transfers
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_close_contacts(beginning_of_day, days_ago, existing_patients)
    printf("Generating close contacts...")
    close_contacts = []
    histories = []
    patient_ids = existing_patients.limit(existing_patients.count * rand(15..25) / 100).order('RAND()').pluck(:id)
    public_health_emails = User.where(role: 'public_health').pluck(:email)
    enrolled_close_contacts_ids = existing_patients.where.not(id: patient_ids).limit(existing_patients.count * rand(5..15) / 100).order('RAND()').pluck(:id)
    enrolled_close_contacts = Patient.where(id: enrolled_close_contacts_ids).pluck(:id, :first_name, :last_name, :primary_telephone, :email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating close contact #{index+1} of #{patient_ids.length}...") unless ENV['APP_IN_CI']
      close_contact_ts = create_fake_timestamp(beginning_of_day)
      close_contact = {
        patient_id: patient_id,
        created_at: close_contact_ts,
        updated_at: close_contact_ts,
        notes: rand < 0.7 ? Faker::Hacker.say_something_smart : nil,
        contact_attempts: rand < 0.4 ? rand(1..5) : nil
      }
      if index < enrolled_close_contacts.size
        close_contact[:enrolled_id] = enrolled_close_contacts[index][0]
        close_contact[:first_name] = enrolled_close_contacts[index][1]
        close_contact[:last_name] = enrolled_close_contacts[index][2]
        close_contact[:primary_telephone] = enrolled_close_contacts[index][3]
        close_contact[:email] = enrolled_close_contacts[index][4]
      else
        close_contact[:enrolled_id] = nil
        close_contact[:first_name] = "#{rand < 0.5 ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
        close_contact[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
        close_contact[:primary_telephone] = rand < 0.85 ? "+155555501#{rand(9)}#{rand(9)}" : nil
        close_contact[:email] = rand < 0.75 ? "#{rand(1000000000..9999999999)}fake@example.com" : nil
      end
      close_contacts << close_contact
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_emails.sample,
        comment: "User created a new close contact.",
        history_type: 'Close Contact',
        created_at: close_contact_ts,
        updated_at: close_contact_ts
      )
    end
    CloseContact.import! close_contacts
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_contact_attempts(beginning_of_day, existing_patients)
    printf("Generating contact attempts...")
    contact_attempts = []
    histories = []
    public_health_users = User.where(role: 'public_health').pluck(:id, :email)
    patients_contact_attempts = existing_patients.limit(existing_patients.count * rand(10..20) / 100).order('RAND()').pluck(:id)
    patients_contact_attempts.each_with_index do |patient_id, index|
      printf("\rGenerating contact attempt #{index+1} of #{patients_contact_attempts.length}...") unless ENV['APP_IN_CI']
      successful = rand < 0.45
      note = rand < 0.65 ? " #{Faker::TvShows::GameOfThrones.quote}" : ''
      contact_attempt_ts = create_fake_timestamp(beginning_of_day)
      manual_attempt = rand < 0.7
      user = public_health_users.sample
      if manual_attempt
        contact_attempts << ContactAttempt.new(
          patient_id: patient_id,
          user_id: user[0],
          successful: successful,
          note: note,
          created_at: contact_attempt_ts,
          updated_at: contact_attempt_ts
        )
      end
      histories << History.new(
        patient_id: patient_id,
        created_by: manual_attempt ? user[1] : 'Sara Alert System',
        comment: "#{successful ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{note}",
        history_type: 'Contact Attempt',
        created_at: contact_attempt_ts,
        updated_at: contact_attempt_ts
      )
    end
    ContactAttempt.import! contact_attempts
    History.import! histories

    printf(" done.\n")
  end

  def demo_populate_linelists
    # populate :latest_assessment_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(created_at) AS latest_assessment_at
        FROM assessments
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_assessment_at = t.latest_assessment_at
    SQL

    # populate :latest_assessment_symptomatic
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      JOIN (
        SELECT assessments.patient_id
        FROM assessments
        JOIN (
          SELECT patient_id, MAX(created_at) AS latest_assessment_at
          FROM assessments
          GROUP BY patient_id
        ) latest_assessments
        ON assessments.patient_id = latest_assessments.patient_id
        AND assessments.created_at = latest_assessments.latest_assessment_at
        WHERE assessments.symptomatic = TRUE
      ) latest_symptomatic_assessments
      ON patients.id = latest_symptomatic_assessments.patient_id
      SET patients.latest_assessment_symptomatic = TRUE
    SQL

    # populate :latest_fever_or_fever_reducer_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT assessments.patient_id, MAX(assessments.created_at) AS latest_fever_or_fever_reducer_at
        FROM assessments
        INNER JOIN conditions ON assessments.id = conditions.assessment_id
        INNER JOIN symptoms ON conditions.id = symptoms.condition_id
        WHERE (symptoms.name = 'fever' OR symptoms.name = 'used-a-fever-reducer') AND symptoms.bool_value = true
        GROUP BY assessments.patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_fever_or_fever_reducer_at = t.latest_fever_or_fever_reducer_at
    SQL

    # populate :first_positive_lab_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MIN(specimen_collection) AS first_positive_lab_at
        FROM laboratories
        WHERE result = 'positive'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.first_positive_lab_at = t.first_positive_lab_at
    SQL

    # populate :negative_lab_count
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS negative_lab_count
        FROM laboratories
        WHERE result = 'negative'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.negative_lab_count = t.negative_lab_count
    SQL

    # populate :latest_transfer_at and :latest_transfer_from
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT transfers.patient_id, transfers.from_jurisdiction_id AS transferred_from, latest_transfers.transferred_at
        FROM transfers
        INNER JOIN (
          SELECT patient_id, MAX(created_at) AS transferred_at
          FROM transfers
          GROUP BY patient_id
        ) latest_transfers ON transfers.patient_id = latest_transfers.patient_id
          AND transfers.created_at = latest_transfers.transferred_at
      ) t ON patients.id = t.patient_id
      SET patients.latest_transfer_from = t.transferred_from, patients.latest_transfer_at = t.transferred_at
    SQL
  end

  def demo_cache_analytics(beginning_of_day)
    printf("Caching analytics...")
    Rake::Task["analytics:cache_current_analytics"].reenable
    Rake::Task["analytics:cache_current_analytics"].invoke
    # Add time onto update time for more realistic reports
    Analytic.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeCount.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeSnapshot.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeMap.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    printf(" done.\n")
  end

  def create_fake_timestamp(from, to = from + 1.day)
    Faker::Time.between(from: from, to: to > Time.now ? Time.now : to)
  end

  def duplicate_timestamps(from, to)
    to.created_at = from.created_at
    to.updated_at = from.updated_at
  end

  def duplicate_collection(collection, new_pat, max_ids, results, hash_key)
    collection.each do |resource|
        max_ids[hash_key] += 1
        new_resource = resource.dup
        new_resource.id = max_ids[hash_key]
        duplicate_timestamps(resource, new_resource)
        new_resource.patient_id = new_pat.id
        results[hash_key] << new_resource
    end
  end

  # Duplicate patient and all nested relations and change last name
  def deep_duplicate_patient(max_ids, results, patient, responder_id: nil)
    max_ids[:patients] += 1

    results[:patients_created] += 1
    new_patient_id = max_ids[:patients]

    new_patient = patient.dup
    new_patient.id = new_patient_id
    new_patient.responder_id = responder_id || new_patient_id
    # new_patient.last_name = "#{new_patient.last_name}#{last_name_num}"
    # new_patient.submission_token = new_patient.new_submission_token
    new_patient.submission_token = SecureRandom.urlsafe_base64[0, 10]
    duplicate_timestamps(patient, new_patient)
    results[:patients] << new_patient
    # new_patient.update(responder_id: new_patient.id) if responder_id.nil?
    patient.dependents.each do |p|
      if p.id != p.responder_id
         deep_duplicate_patient(max_ids, results, p, responder_id: new_patient_id)
      end
    end if patient.head_of_household
    patient.assessments.each do |assessment| 
        # Assessment
        max_ids[:assessments] += 1
        new_assessment = assessment.dup
        new_assessment.id = max_ids[:assessments]
        new_assessment.patient_id = new_patient.id
        duplicate_timestamps(assessment, new_assessment)
        results[:assessments] << new_assessment

        # Reported Condition
        max_ids[:reported_conditions] += 1
        rep_condition = assessment.reported_condition
        new_reported_condition = rep_condition.dup
        new_reported_condition.id = max_ids[:reported_conditions]
        new_reported_condition.assessment_id = new_assessment.id
        duplicate_timestamps(rep_condition, new_reported_condition)
        results[:reported_conditions] << new_reported_condition

        # Symptoms
        assessment.reported_condition.symptoms.each do |s|
          max_ids[:symptoms] += 1
          news = s.dup
          duplicate_timestamps(s, news)
          news.condition_id = new_reported_condition.id
          news.id = max_ids[:symptoms]
          results[:symptoms] << news
        end
    end

    # Just changing the ID and timestamps on these collections, so no need to validate
    # History.import duplicate_collection(patient.histories, patient, new_patient), validate: false
    # Transfer.import duplicate_collection(patient.transfers, patient, new_patient), validate: false
    # Laboratory.import duplicate_collection(patient.laboratories, patient, new_patient), validate: false
    # CloseContact.import duplicate_collection(patient.close_contacts, patient, new_patient), validate: false
    # ContactAttempt.import duplicate_collection(patient.contact_attempts, patient, new_patient), validate: false
    
    duplicate_collection(patient.histories, new_patient, max_ids, results, :histories)
    duplicate_collection(patient.transfers, new_patient, max_ids, results, :transfers)
    duplicate_collection(patient.laboratories, new_patient, max_ids, results, :laboratories)
    duplicate_collection(patient.close_contacts, new_patient, max_ids, results, :close_contacts)
    duplicate_collection(patient.contact_attempts, new_patient, max_ids, results, :contact_attempts)

    results
  end

  def blank_results
    {
      patients_created: 0,
      patients: [],
      assessments: [],
      reported_conditions: [],
      symptoms:[],
      histories: [],
      transfers: [],
      laboratories: [],
      close_contacts: [],
      contact_attempts: []
    }
  end

  # def merge_deep_duplicate(results_1, results_2)
  #   {
  #     patients_created: results_1[:patients_created] + results_2[:patients_created],
  #     patients: results_1[:patients] + results_2[:patients],
  #     assessments: results_1[:assessments] + results_2[:assessments],
  #     reported_conditions: results_1[:reported_conditions] + results_2[:reported_conditions],
  #     symptoms: results_1[:symptoms] + results_2[:symptoms],
  #     histories: results_1[:histories] + results_2[:histories],
  #     transfers: results_1[:transfers] + results_2[:transfers],
  #     laboratories: results_1[:laboratories] + results_2[:laboratories],
  #     close_contacts: results_1[:close_contacts] + results_2[:close_contacts],
  #     contact_attempts: results_1[:contact_attempts] + results_2[:contact_attempts]
  #   }
  # end

  def import_deep_duplicate(results)
    puts "\rImporting #{results[:patients].size} patients...                                                                                  "
    Patient.import results[:patients], validate: false
    Assessment.import results[:assessments], validate: false
    ReportedCondition.import results[:reported_conditions], validate: false
    Symptom.import results[:symptoms], validate: false
    History.import results[:histories], validate: false
    Transfer.import results[:transfers], validate: false
    Laboratory.import results[:laboratories], validate: false
    CloseContact.import results[:close_contacts], validate: false
    ContactAttempt.import results[:contact_attempts], validate: false

    results[:patients] = []
    results[:assessments] = []
    results[:reported_conditions] = []
    results[:symptoms] = []
    results[:histories] = []
    results[:transfers] = []
    results[:laboratories] = []
    results[:close_contacts] = []
    results[:contact_attempts] = []
  end
end
