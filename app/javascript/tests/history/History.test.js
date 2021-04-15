import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import _ from 'lodash';
import History from '../../components/history/History.js'
import { mockHistory1, mockHistory2 } from '../mocks/mockHistories'
import { formatTimestamp, formatRelativePast } from '../../utils/DateTime';


const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

describe('History', () => {
  it('Properly renders non-comment histories', () => {
    const wrapper = shallow(<History key={mockHistory1.id} history={mockHistory1} authenticity_token={authyToken} />);
    console.log(wrapper.html());
    const divEditId = "#edit-history-item-" + mockHistory1.id;
    const divDeleteId = "#delete-history-item-" + mockHistory1.id;
    expect(wrapper.find('b').exists()).toBeTruthy();
    expect(wrapper.find('b').text()).toEqual(mockHistory1.created_by);
    expect(wrapper.find('.h5').find('span').text()).toEqual(mockHistory1.history_type);
    expect(wrapper.text().includes(formatTimestamp(mockHistory1.created_at))).toBeTruthy();
    expect(wrapper.text().includes(formatRelativePast(mockHistory1.created_at))).toBeTruthy();
    expect(wrapper.find(divEditId).exists()).toBeFalsy();
    expect(wrapper.find(divDeleteId).exists()).toBeFalsy();
  });

  it('Properly renders comment histories', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory2.id;
    const divDeleteId = "delete-history-item-" + mockHistory2.id;
    expect(wrapper.find('b').text()).toEqual(mockHistory2.created_by);
    expect(wrapper.find('#' + divEditId).exists()).toBeTruthy();
    expect(wrapper.find('#' + divEditId).find('span').text()).toEqual('You may edit comments you have added');
    expect(wrapper.find('[data-for="'+divEditId+'"]').find(Button).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divEditId+'"]').find(Button).find('i').hasClass('fa-edit')).toBeTruthy();
    expect(wrapper.find('#' + divDeleteId).exists()).toBeTruthy();
    expect(wrapper.find('#' + divDeleteId).find('span').text()).toEqual('You may delete comments you have added');
    expect(wrapper.find('[data-for="'+divDeleteId+'"]').find(Button).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divDeleteId+'"]').find(Button).find('i').hasClass('fa-trash')).toBeTruthy();

  });

  it('Clicking the edit button properly updates state, displays edit mode, and allows edit submission', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const handleEditSubmitSpy = jest.spyOn(wrapper.instance(), "handleEditSubmit");
    const divEditId = "edit-history-item-" + mockHistory2.id;
    const changedCommentValue = "this has been changed";
    expect(wrapper.state().editMode).toBeFalsy();
    wrapper.find('[data-for="'+divEditId+'"]').find(Button).simulate('click');
    expect(wrapper.state().editMode).toBeTruthy();
    expect(wrapper.find('#comment').exists()).toBeTruthy();
    wrapper.find('#comment').simulate('change', {target: {value: changedCommentValue}});
    wrapper.update();
    expect(wrapper.find('#comment').prop('value')).toEqual(changedCommentValue);
    expect(wrapper.find('[aria-label="Submit Edit History Comment"]').exists()).toBeTruthy();
    wrapper.find('[aria-label="Submit Edit History Comment"]').simulate('click');
    expect(handleEditSubmitSpy).toBeCalled();
  });


  it('Clicking the cancel button reverts from edit mode to original view', () => {
    const wrapper = shallow(<History key={mockHistory2.id} history={mockHistory2} authenticity_token={authyToken} />);
    const divEditId = "edit-history-item-" + mockHistory2.id;
    const divDeleteId = "delete-history-item-" + mockHistory2.id;
    expect(wrapper.state().editMode).toBeFalsy();
    wrapper.find('[data-for="'+divEditId+'"]').find(Button).simulate('click');
    expect(wrapper.state().editMode).toBeTruthy();
    wrapper.find('[aria-label="Cancel Edit History Comment"]').simulate('click');
    expect(wrapper.find('#comment').exists()).toBeFalsy();
    expect(wrapper.find('b').text()).toEqual(mockHistory2.created_by);
    expect(wrapper.find('#' + divEditId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divEditId+'"]').exists()).toBeTruthy();
    expect(wrapper.find('#' + divDeleteId).exists()).toBeTruthy();
    expect(wrapper.find('[data-for="'+divDeleteId+'"]').exists()).toBeTruthy();
    expect(wrapper.state().editMode).toBeFalsy();

  });
});