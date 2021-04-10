import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import _ from 'lodash';
import History from '../../components/history/History.js'
import { mockHistory1, mockHistory2 } from '../mocks/mockHistories'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

beforeEach(() => {
  window.BASE_PATH = ""
})

describe('History', () => {
  it('Properly renders non-comment histories', () => {
    const wrapper = shallow(<History key={mockHistory1.id} history={mockHistory1} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory1.id;
    const divDeleteId = "delete-history-item-" + mockHistory1.id;
    expect(wrapper.find('b').exists()).toBeTruthy();
    expect(wrapper.find('b').text()).toEqual(mockHistory1.created_by);
    expect(wrapper.find('.h5').find('span').text()).toEqual(mockHistory1.history_type);
    expect(wrapper.find('#' + divEditId).exists()).toBeFalsy();
    expect(wrapper.find('#' + divDeleteId).exists()).toBeFalsy();
  });

  it('Properly renders comment histories', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory2.id;
    const divDeleteId = "delete-history-item-" + mockHistory2.id;
    expect(wrapper.find('b').text()).toEqual(mockHistory2.created_by);
    expect(wrapper.find('#' + divEditId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divEditId+'"]').exists()).toBeTruthy();
    expect(wrapper.find('#' + divDeleteId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divDeleteId+'"]').exists()).toBeTruthy();
  });

  it('Clicking edit properly displays the field', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory2.id;
    wrapper.find('[data-for="'+divEditId+'"]').find(Button).simulate('click');
    expect(wrapper.find('#comment').exists()).toBeTruthy();
  });

  it('Canceling edit properly restores original view', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory2.id;
    const divDeleteId = "delete-history-item-" + mockHistory2.id;
    wrapper.find('[data-for="'+divEditId+'"]').find(Button).simulate('click');
    wrapper.find('[aria-label="Cancel Edit History Comment"]').simulate('click');
    expect(wrapper.find('#comment').exists()).toBeFalsy();
    expect(wrapper.find('b').text()).toEqual(mockHistory2.created_by);
    expect(wrapper.find('#' + divEditId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divEditId+'"]').exists()).toBeTruthy();
    expect(wrapper.find('#' + divDeleteId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divDeleteId+'"]').exists()).toBeTruthy();
  });
});