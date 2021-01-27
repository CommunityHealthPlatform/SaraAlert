import React from 'react'
import { shallow, mount } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import InfoTooltip from '../../components/util/InfoTooltip';
import CloseContact from '../../components/close_contact/CloseContact.js'
import { mockPatient1 } from '../mocks/mockPatients'
import { mockCloseContact1, mockCloseContact2 } from '../mocks/mockCloseContact'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [ 123234, 512678, 910132 ]
const testInputValues = [
  { field: 'first_name', value: 'Anthony', inputType: 'FormControl' },
  { field: 'last_name', value: 'Stark', inputType: 'FormControl' },
  { field: 'primary_telephone', value: '1234567890', inputType: 'PhoneInput' },
  { field: 'email', value: 'tinman@starkindustries.com', inputType: 'FormControl' },
  { field: 'last_date_of_exposure', value: '2020-05-16', inputType: 'DateInput' },
  { field: 'assigned_user', value: ASSIGNED_USERS[0], inputType: 'FormControl' },
  { field: 'notes', value: 'Inevitable', inputType: 'FormControl' },
]

function getShallowWrapper(closeContact) {
  return shallow(<CloseContact authenticity_token={authyToken} patient={mockPatient1} close_contact={closeContact}
    can_enroll_patient_close_contacts={true} assigned_users={ASSIGNED_USERS}  />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CloseContact', () => {
  it('Properly renders all main components for empty close contact', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    expect(emptyCCWrapper.find('div').at(0).text()).toContain('Add New Close Contact');

    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    expect(emptyCCWrapper.state('first_name')).toEqual('')
    expect(emptyCCWrapper.state('last_name')).toEqual('')
    expect(emptyCCWrapper.state('primary_telephone')).toEqual('')
    expect(emptyCCWrapper.state('email')).toEqual('')
    expect(emptyCCWrapper.state('last_date_of_exposure')).toEqual(null)
    expect(emptyCCWrapper.state('assigned_user')).toEqual(null)
    expect(emptyCCWrapper.state('notes')).toEqual('')
    expect(emptyCCWrapper.state('enrolled_id')).toEqual(null)
    expect(emptyCCWrapper.state('contact_attempts')).toEqual(0)
  });

  it('Properly renders all main components for already existing close contact', () => {
    const alreadyExistingCCWrapper = getShallowWrapper(mockCloseContact2);
    expect(alreadyExistingCCWrapper.find('div').at(0).text()).toContain('Edit Contact Attempt');
    expect(alreadyExistingCCWrapper.find('div').at(2).text()).toContain('View Record');

    expect(alreadyExistingCCWrapper.state('showModal')).toBeFalsy();
    expect(alreadyExistingCCWrapper.state('first_name')).toEqual(mockCloseContact2.first_name || '')
    expect(alreadyExistingCCWrapper.state('last_name')).toEqual(mockCloseContact2.last_name || '')
    expect(alreadyExistingCCWrapper.state('primary_telephone')).toEqual(mockCloseContact2.primary_telephone || '')
    expect(alreadyExistingCCWrapper.state('email')).toEqual(mockCloseContact2.email || '')
    expect(alreadyExistingCCWrapper.state('last_date_of_exposure')).toEqual(mockCloseContact2.last_date_of_exposure || null)
    expect(alreadyExistingCCWrapper.state('assigned_user')).toEqual(mockCloseContact2.assigned_user || null)
    expect(alreadyExistingCCWrapper.state('notes')).toEqual(mockCloseContact2.notes || '')
    expect(alreadyExistingCCWrapper.state('contact_attempts')).toEqual(mockCloseContact2.contact_attempts || 0)
  });

  it('Properly renders the modal if button is clicked', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    emptyCCWrapper.find(Button).simulate('click');
    expect(emptyCCWrapper.state('showModal')).toBeTruthy();
    expect(emptyCCWrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(emptyCCWrapper.find(Modal.Header).find('.sr-only').text()).toEqual('Close Contact');
    expect(emptyCCWrapper.find(Modal.Header).find('ModalTitle').text()).toEqual('Close Contact');
    expect(emptyCCWrapper.find(Modal.Body).exists()).toBeTruthy();
    // Using `toContain` instead of `toEqual` to avoid any whitespace issues
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormLabel').text()).toContain(`First Name *`);
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormLabel').text()).toContain(`Last Name *`);
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(2).find('FormLabel').text()).toContain(`Phone Number`);
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormLabel').text()).toContain(`Email`);
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(4).find('FormLabel').text()).toContain(`Last Date of Exposure`);
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(5).find('FormLabel').text()).toContain(`Assigned User`); // There's also the InfoTooltip
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(5).find('FormLabel').containsMatchingElement(<InfoTooltip />)).toBeTruthy();
    expect(emptyCCWrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('assignedUser');

    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormLabel').at(0).text()).toContain('Notes');
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormLabel').at(1).text()).toContain('2000 characters remaining');
    expect(emptyCCWrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(emptyCCWrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(emptyCCWrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Create');
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeTruthy()
  });

  it('Properly renders empty fields when an empty close contact is used as a prop', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    const handleChangeSpy = jest.spyOn(emptyCCWrapper.instance(), 'handleChange');
    const handleDateChangeSpy = jest.spyOn(emptyCCWrapper.instance(), 'handleDateChange');

    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    emptyCCWrapper.find(Button).simulate('click');
    expect(emptyCCWrapper.state('showModal')).toBeTruthy();

    // This iteration assumes the testInputValues order matches the order of the elements in the DOM
    testInputValues.forEach((iv, index) => {
      if (iv.inputType === 'DateInput') {
        emptyCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', iv.value)
        expect(handleDateChangeSpy).toHaveBeenCalled();
      } else {
        emptyCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', { target: { id: iv.field, value: iv.value } })
        expect(handleChangeSpy).toHaveBeenCalled();
      }
      expect(emptyCCWrapper.state(iv.field)).toEqual(iv.value);
    })
  });

  it('Properly creates the correct assigned user dropdown options', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    emptyCCWrapper.find(Button).simulate('click');
    ASSIGNED_USERS.forEach((user, userIndex) => {
      expect(emptyCCWrapper.find(Modal.Body).find('option').at(userIndex).text()).toEqual(`${user}`);
    })
  });

  it('Properly clears any values in the modal on close (for empty close contact)', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    emptyCCWrapper.find(Button).simulate('click');
    expect(emptyCCWrapper.state('showModal')).toBeTruthy();

    // This iteration assumes the testInputValues order matches the order of the elements in the DOM
    testInputValues.forEach((iv, index) => {
      if (iv.inputType === 'DateInput') {
        emptyCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', iv.value)
      } else {
        emptyCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', { target: { id: iv.field, value: iv.value } })
      }
    })

    emptyCCWrapper.find(Button).at(1).simulate('click');
    // Once the modal is closed, the values should default back to their nulled out original values
    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    expect(emptyCCWrapper.state('first_name')).toEqual(mockCloseContact1.first_name || '')
    expect(emptyCCWrapper.state('last_name')).toEqual(mockCloseContact1.last_name || '')
    expect(emptyCCWrapper.state('primary_telephone')).toEqual(mockCloseContact1.primary_telephone || '')
    expect(emptyCCWrapper.state('email')).toEqual(mockCloseContact1.email || '')
    expect(emptyCCWrapper.state('last_date_of_exposure')).toEqual(mockCloseContact1.last_date_of_exposure || null)
    expect(emptyCCWrapper.state('assigned_user')).toEqual(mockCloseContact1.assigned_user || null)
    expect(emptyCCWrapper.state('notes')).toEqual(mockCloseContact1.notes || '')
  });

  it('Properly resets any values in the modal to the default (for existing close contact)', () => {
    const existingCCWrapper = getShallowWrapper(mockCloseContact2);
    expect(existingCCWrapper.state('showModal')).toBeFalsy();
    existingCCWrapper.find(Button).at(0).simulate('click');
    expect(existingCCWrapper.state('showModal')).toBeTruthy();

    // This iteration assumes the testInputValues order matches the order of the elements in the DOM
    testInputValues.forEach((iv, index) => {
      if (iv.inputType === 'DateInput') {
        existingCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', iv.value)
      } else {
        existingCCWrapper.find(Modal.Body).find('Row').at(index).find(iv.inputType).simulate('change', { target: { id: iv.field, value: iv.value } })
      }
    })

    existingCCWrapper.find(Button).at(3).simulate('click');
    // Once the modal is closed, the values should default back to their nulled out original values
    expect(existingCCWrapper.state('showModal')).toBeFalsy();
    expect(existingCCWrapper.state('first_name')).toEqual(mockCloseContact2.first_name || '')
    expect(existingCCWrapper.state('last_name')).toEqual(mockCloseContact2.last_name || '')
    expect(existingCCWrapper.state('primary_telephone')).toEqual(mockCloseContact2.primary_telephone || '')
    expect(existingCCWrapper.state('email')).toEqual(mockCloseContact2.email || '')
    expect(existingCCWrapper.state('last_date_of_exposure')).toEqual(mockCloseContact2.last_date_of_exposure || null)
    expect(existingCCWrapper.state('assigned_user')).toEqual(mockCloseContact2.assigned_user || null)
    expect(existingCCWrapper.state('notes')).toEqual(mockCloseContact2.notes || '')
  });

  it('Enables submit button when first and last name are not empty', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    emptyCCWrapper.find(Button).simulate('click');
    expect(emptyCCWrapper.state('showModal')).toBeTruthy();
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeTruthy()
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').simulate('change', { target: { id: 'first_name', value: 'Anthony' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeTruthy()
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'last_name', value: 'Stark' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeFalsy()

    // The only two required fields are first_name and last_name
    // Ensure that nulling out the first_name makes it disabled again
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').simulate('change', { target: { id: 'first_name', value: '' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeTruthy()
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').simulate('change', { target: { id: 'first_name', value: 'Anthony' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeFalsy()

    // Ensure that nulling out the last_name makes it disabled again
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').simulate('change', { target: { id: 'last_name', value: '' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeTruthy()
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').simulate('change', { target: { id: 'last_name', value: 'Stark' } })
    expect(emptyCCWrapper.find(Button).at(2).props().disabled).toBeFalsy()
  });

  it('Properly calls submit when the button is clicked', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    const submitSpy = jest.spyOn(emptyCCWrapper.instance(), 'submit');
    emptyCCWrapper.find(Button).simulate('click'); //open the modal
    emptyCCWrapper.find(Button).at(2).simulate('click') //click submit
    expect(submitSpy).toHaveBeenCalledTimes(1)
  });

  it('Properly renders accurate count of characters remaining for notes field', () => {
    const emptyCCWrapper = getShallowWrapper(mockCloseContact1);
    const testNoteString = 'The Strongest Avenger'
    expect(emptyCCWrapper.state('showModal')).toBeFalsy();
    emptyCCWrapper.find(Button).simulate('click');
    expect(emptyCCWrapper.state('showModal')).toBeTruthy();
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormLabel').at(0).text()).toContain('Notes');
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormLabel').at(1).text()).toContain('2000 characters remaining');
    emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormControl').simulate('change', { target: { id: 'notes', value: testNoteString } })
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(6).find('FormLabel').at(1).text()).toContain(`${2000-testNoteString.length} characters remaining`);
  })

});