import React from 'react';
import { shallow } from 'enzyme';
import Viewers from '../../components/patient/Viewers';
import { mockPatient1, mockPatient2, mockPatient3 } from '../mocks/mockPatients';

function getWrapper(mockPatient, viewers) {
  return shallow(<Viewers patient_id={mockPatient.id} viewers={viewers} />);
}

describe('Viewers', () => {
  const wrapper1 = getWrapper(mockPatient1, []);
  const wrapper2 = getWrapper(mockPatient2, ["0@example.com"]);
  const wrapper3 = getWrapper(mockPatient3, ["1@example.com", "2@example.com"]);

  it('Properly renders a list of multiple viewers', () => {
    expect(wrapper3.find('#multiple-warning').text().includes('1@example.com')).toBeTruthy();
    expect(wrapper3.find('#multiple-warning').text().includes('2@example.com')).toBeTruthy();
    expect(wrapper3.find('#multiple-warning').text().includes('Multiple users currently have this monitoree')).toBeTruthy();
  });

  it('Properly renders a list of a single viewer', () => {
    expect(wrapper2.find('#multiple-warning').text().includes('0@example.com')).toBeTruthy();
    expect(wrapper2.find('#multiple-warning').text().includes('Another user currently has this monitoree')).toBeTruthy();
  });

  it('Properly renders a list of an empty list of viewers', () => {
    expect(wrapper1.hasClass('multiple-warning')).toBeFalsy()
  });
});
