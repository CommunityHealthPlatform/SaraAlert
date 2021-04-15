import React from 'react'
import { shallow } from 'enzyme';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import InfoTooltip from '../../components/util/InfoTooltip';
import Select from 'react-select';
import _ from 'lodash';
import HistoryList from '../../components/history/HistoryList.js'
import History from '../../components/history/History.js'
import { mockPatient1} from '../mocks/mockPatients'
import { mockHistory1, mockHistory2 } from '../mocks/mockHistories'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';


describe('HistoryList', () => {
  it('Properly renders all history components', () => {
    const wrapper = shallow(<HistoryList patient_id={mockPatient1.id} histories={[mockHistory1, mockHistory2]} authenticity_token={authyToken} 
      history_types={{enrollment: "Enrollment", comment: "Comment"}}/>);
    expect(wrapper.find('#histories').exists()).toBeTruthy();
    expect(wrapper.find('#histories').find('span').text()).toEqual('History ');
    expect(wrapper.find('#histories').find('textarea').exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('history');
    expect(wrapper.find('#filters').exists()).toBeTruthy();
    expect(wrapper.find('#filters').find({name: 'Creator Filters'}).exists()).toBeTruthy();
    expect(wrapper.find('#filters').find({name: 'Filters'}).exists()).toBeTruthy();
    wrapper.setState({pageOfHistories: wrapper.state().filteredHistories});
    wrapper.update();
    expect(wrapper.find(History).length).toEqual(2);
    expect(wrapper.find('textarea').exists()).toBeTruthy();
    expect(wrapper.find('button').exists()).toBeTruthy();
    expect(wrapper.find('button').find('i').hasClass('fa-comment-dots')).toBeTruthy();
  });
  
  it('Properly updates comment input field and submits new comment', () => {
    const wrapper = shallow(<HistoryList patient_id={mockPatient1.id} histories={[mockHistory1, mockHistory2]} authenticity_token={authyToken} 
      history_types={{enrollment: "Enrollment", comment: "Comment"}}/>);
    const submitSpy = jest.spyOn(wrapper.instance(), "submit");
    wrapper.find('textarea').simulate('change', {target: {value: 'adding a comment'}});
    expect(wrapper.find('textarea').prop('value')).toEqual('adding a comment');
    wrapper.find('button').simulate('click');
    wrapper.update();
    expect(submitSpy).toBeCalled();
  });
});