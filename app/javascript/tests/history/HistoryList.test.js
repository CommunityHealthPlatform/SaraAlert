import React from 'react'
import { shallow } from 'enzyme';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import HistoryList from '../../components/history/HistoryList.js'
import { mockPatient1} from '../mocks/mockPatients'
import { mockHistory1, mockHistory2 } from '../mocks/mockHistories'
import { nameFormatter, formatDate } from '../util.js'

const goToMock = jest.fn();
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

beforeEach(() => {
  window.BASE_PATH = ""
})

describe('HistoryList', () => {
  it('Properly renders all history components', () => {
    const wrapper = shallow(<HistoryList patient_id={mockPatient1.id} histories={[]} authenticity_token={authyToken} 
      history_types={{enrollment: "Enrollment", comment: "Comment"}}/>);
    expect(wrapper.find('#histories').exists()).toBeTruthy();
    expect(wrapper.find('#histories').find('span').text()).toEqual('History ');
    expect(wrapper.find('#histories').find('textarea').exists()).toBeTruthy();
  });
});