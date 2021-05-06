
# frozen_string_literal: true

namespace :perf do
  desc 'Completely populate the performance database'
  task populate: :environment do
    unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
      puts 'bundle exec rails db:drop db:create db:schema:load admin:import_or_update_jurisdictions perf:populate'
      raise 'This task is only for use in a development environment' 
    end

    raise 'This task is meant to run ONLY on a new database' if Patient.count > 0 || User.count > 0

    ENV['PERFORMANCE'] = 'true'
    Rake::Task["perf:setup_performance_test_users"].invoke
    Rake::Task["perf:populate_and_simulate_patients"].invoke
  end

  desc 'Configure the users in the database for performance testing'
  task populate_and_simulate_patients: :environment do
    # Configurable variables
    target_patients = (ENV['PATIENT_COUNT']|| 50_000).to_i
    days = (ENV['DAYS'] || 14).to_i

    # Calculated variables
    num_prototype_patients = [(target_patients * 0.1).to_i, 30_000].min

    ENV['LIMIT'] = num_prototype_patients.to_s
    # Reduce num_prototype_patients here since demo:populate grows new patient count with each day
    ENV['COUNT'] = (ENV['COUNT'] || (num_prototype_patients * 0.85) / days).to_i.to_s
    # Rake::Task["demo:populate"].invoke

    ENV['COUNT'] = (target_patients - num_prototype_patients).to_s
    Rake::Task["demo:create_bulk_data"].invoke
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
end
