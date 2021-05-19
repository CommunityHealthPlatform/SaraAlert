# frozen_string_literal: true

require 'test_case'

class CloseContactsControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  # --- BEFORE ACTION --- #

  test 'before action: authenticate user' do
    post :create, params: {}
    assert_redirected_to(new_user_session_path)

    put :update, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)

    put :destroy, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)
  end

  test 'before action: check user can create' do
    user = create(:enroller_user)
    sign_in user

    post :create, params: {}
    assert_response(:forbidden)

    sign_out user
  end

  test 'before action: check user can edit' do
    user = create(:enroller_user)
    sign_in user

    put :update, params: { id: 'test' }
    assert_response(:forbidden)

    put :destroy, params: { id: 'test' }
    assert_response(:forbidden)

    sign_out user
  end

  test 'before action: check patient valid (patient exists)' do
    user = create(:public_health_enroller_user)
    sign_in user

    post :create, params: { patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Close Contact cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :update, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Close Contact cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Close Contact cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check patient (current user can view patient)' do
    user = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    patient = create(:patient, creator: user_2)
    sign_in user

    post :create, params: { patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :update, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check close_contact' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    sign_in user

    put :update, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    put :destroy, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    sign_out user
  end

  # --- CREATE --- #

  test 'create: creates new close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    post :create, params: {
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    assert_response(:success)
    assert_equal(1, patient.close_contacts.count)
    assert_equal(1, patient.histories.count)

    close_contact = patient.close_contacts.first
    assert_equal(first_name, close_contact[:first_name])
    assert_equal(last_name, close_contact[:last_name])
    assert_equal(email, close_contact[:email])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User added a new close contact (ID: #{close_contact.id}).", history[:comment])

    sign_out user
  end

  # --- UPDATE --- #

  test 'update: updates existing close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, updated_at: 2.days.ago)

    sign_in user
    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    post :update, params: {
      id: close_contact.id,
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    close_contact.reload
    assert_response(:success)
    assert_in_delta(Time.now, close_contact.updated_at, 1) # assert updated
    assert_equal(1, patient.histories.count)

    close_contact = CloseContact.find(close_contact.id)
    assert_equal(first_name, close_contact[:first_name])
    assert_equal(last_name, close_contact[:last_name])
    assert_equal(email, close_contact[:email])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User edited a close contact (ID: #{close_contact.id}).", history[:comment])

    sign_out user
  end

  # --- DESTROY --- #

  test 'destroy: destroys existing close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, updated_at: 2.days.ago)
    delete_reason = 'some delete reason'

    sign_in user
    put :destroy, params: {
      id: close_contact.id,
      patient_id: patient.id,
      delete_reason: delete_reason
    }

    assert_response(:success)
    assert_equal(1, patient.histories.count)

    assert_raises(ActiveRecord::RecordNotFound) do
      close_contact = CloseContact.find(close_contact.id)
    end

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User deleted a close contact (ID: #{close_contact.id}, Name: #{close_contact.first_name} #{close_contact.last_name}"\
      ", Primary Telephone: #{close_contact.primary_telephone}, Email: #{close_contact.email}, Last Date of Exposure: "\
      "#{close_contact.last_date_of_exposure}, Assigned User: #{close_contact.assigned_user}, Notes: #{close_contact.notes}, "\
      "Contact Attempts: #{close_contact.contact_attempts}. Reason: #{delete_reason}.)", history[:comment])

    sign_out user
  end
end
