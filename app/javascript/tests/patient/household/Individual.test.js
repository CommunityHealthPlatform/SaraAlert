import React from 'react';
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import Individual from '../../../components/patient/household/Individual';
import MoveToHousehold from '../../../components/patient/household/actions/MoveToHousehold';
import EnrollHouseholdMember from '../../../components/patient/household/actions/EnrollHouseholdMember';
import HouseholdMemberTable from '../../../components/patient/household/utils/HouseholdMemberTable';
import { mockPatient3 } from '../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';

describe('Individual', () => {
  it('Properly renders all main components', () => {
    const wrapper1 = shallow(<Individual patient={mockPatient3} can_add_group={true} authenticity_token={mockToken} />);
    const wrapper2 = shallow(<Individual patient={mockPatient3} can_add_group={false} authenticity_token={mockToken} />);

    // if user can add group
    expect(wrapper1.find(Row).length).toEqual(2);
    expect(wrapper1.find(Row).at(0).text()).toEqual('This monitoree is not a member of a household.');
    expect(wrapper1.find(MoveToHousehold).exists()).toBeTruthy();
    expect(wrapper1.find(EnrollHouseholdMember).exists()).toBeTruthy();
    expect(wrapper1.find(EnrollHouseholdMember).prop('isHoh')).toBeFalsy();
    expect(wrapper1.find(HouseholdMemberTable).exists()).toBeFalsy();

    // if user can't add group
    expect(wrapper2.find(Row).length).toEqual(2);
    expect(wrapper2.find(Row).at(0).text()).toEqual('This monitoree is not a member of a household.');
    expect(wrapper2.find(MoveToHousehold).exists()).toBeTruthy();
    expect(wrapper2.find(EnrollHouseholdMember).exists()).toBeFalsy();
    expect(wrapper2.find(HouseholdMemberTable).exists()).toBeFalsy();
  });
});
