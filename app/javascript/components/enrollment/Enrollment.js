import React from 'react';
import PropTypes from 'prop-types';
import { Carousel } from 'react-bootstrap';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { debounce, pickBy, identity } from 'lodash';
import axios from 'axios';
import libphonenumber from 'google-libphonenumber';
import _ from 'lodash';

import Identification from './steps/Identification';
import Address from './steps/Address';
import Contact from './steps/Contact';
import Arrival from './steps/Arrival';
import AdditionalPlannedTravel from './steps/AdditionalPlannedTravel';
import ExposureInformation from './steps/ExposureInformation';
import CaseInformation from './steps/CaseInformation';
import MonitoringProgram from './steps/MonitoringProgram';
import Review from './steps/Review';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';
import { navQueryParam } from '../../utils/Navigation';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();
const MAX_STEPS = 8;

class Enrollment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      index: props.enrollment_step != undefined ? props.enrollment_step : props.edit_mode ? MAX_STEPS : 0,
      lastIndex: props.enrollment_step != undefined ? MAX_STEPS : null,
      direction: null,
      review_mode: false,
      enrollmentState: {
        patient: pickBy(props.patient, identity),
        propagatedFields: {},
        blocked_sms: props.blocked_sms,
        monitoring_infos: {},
        // first_positive_lab: props.first_positive_lab,
      },
      activeMonitoringInfoIndex: null,
      assigned_users: props.assigned_users,
    };
  }

  componentDidMount() {
    window.onbeforeunload = () => {
      return 'All progress will be lost. Are you sure?';
    };
  }

  setEnrollmentState = debounce(enrollmentState => {
    let currentEnrollmentState = this.state.enrollmentState;
    this.setState({
      enrollmentState: {
        patient: { ...currentEnrollmentState.patient, ...enrollmentState.patient },
        propagatedFields: { ...currentEnrollmentState.propagatedFields, ...enrollmentState.propagatedFields },
        blocked_sms: enrollmentState.blocked_sms,
        // first_positive_lab: enrollmentState.first_positive_lab,
        monitoring_infos: { ...currentEnrollmentState.monitoring_infos, ...enrollmentState.monitoring_infos },
      },
    });
  }, 1000);

  setMonitoringInfoIndex = index => {
    this.setState({ activeMonitoringInfoIndex: index });
  };

  updateAssignedUsers = jurisdictionId => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/jurisdictions/assigned_users', {
        query: {
          jurisdiction: jurisdictionId,
          scope: 'exact',
        },
      })
      .catch(() => {})
      .then(response => {
        if (response?.data?.assigned_users) {
          this.setState({ assigned_users: response.data.assigned_users });
        }
      });
  };

  handleConfirmDuplicate = async (data, groupMember, message, reenableButtons, confirmText) => {
    if (await confirmDialog(confirmText)) {
      data['bypass_duplicate'] = true;
      axios({
        method: this.props.edit_mode ? 'patch' : 'post',
        url: window.BASE_PATH + (this.props.edit_mode ? '/patients/' + this.props.patient.id : '/patients'),
        data: data,
      })
        .then(response => {
          toast.success(message, {
            onClose: () =>
              (location.href =
                `${window.BASE_PATH}/patients/` +
                (groupMember ? `${response['data']['responder_id']}/group` : response['data']['id']) +
                navQueryParam(this.props.workflow, true)),
          });
        })
        .catch(err => {
          reportError(err);
        });
    } else {
      window.onbeforeunload = () => {
        return 'All progress will be lost. Are you sure?';
      };
      reenableButtons();
    }
  };

  submit = (_event, groupMember, reenableButtons) => {
    window.onbeforeunload = null;

    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    // If enrolling, include ALL fields in diff keys. If editing, only include the ones that have changed
    let diffKeys = this.props.edit_mode
      ? Object.keys(this.state.enrollmentState.patient).filter(k => _.get(this.state.enrollmentState.patient, k) !== _.get(this.props.patient, k) || k === 'id')
      : Object.keys(this.state.enrollmentState.patient);

    let data = new Object({
      patient: this.props.parent_id ? this.state.enrollmentState.patient : _.pick(this.state.enrollmentState.patient, diffKeys),
      propagated_fields: this.state.enrollmentState.propagatedFields,
      monitoring_infos: this.state.enrollmentState.monitoring_infos,
    });

    data.patient.primary_telephone = data.patient.primary_telephone
      ? phoneUtil.format(phoneUtil.parse(data.patient.primary_telephone, 'US'), PNF.E164)
      : data.patient.primary_telephone;
    data.patient.secondary_telephone = data.patient.secondary_telephone
      ? phoneUtil.format(phoneUtil.parse(data.patient.secondary_telephone, 'US'), PNF.E164)
      : data.patient.secondary_telephone;
    const message = this.props.edit_mode ? 'Monitoree Successfully Updated.' : 'Monitoree Successfully Saved.';
    if (this.props.parent_id) {
      data['responder_id'] = this.props.parent_id;
    }
    if (this.props.cc_id) {
      data['cc_id'] = this.props.cc_id;
    }
    if (data.patient.symptom_onset !== undefined && data.patient.symptom_onset !== null && data.patient.symptom_onset !== this.props.patient.symptom_onset) {
      data.patient.user_defined_symptom_onset = true;
    }
    if (this.state.enrollmentState.first_positive_lab) {
      if (this.props.first_positive_lab) {
        let diffKeysLab = Object.keys(this.state.enrollmentState.first_positive_lab).filter(
          k => _.get(this.state.enrollmentState.first_positive_lab, k) !== _.get(this.props.first_positive_lab, k)
        );
        data['laboratory'] = { id: this.props.first_positive_lab.id, ..._.pick(this.state.enrollmentState.first_positive_lab, diffKeysLab) };
      } else {
        data['patient']['laboratories_attributes'] = [this.state.enrollmentState.first_positive_lab];
      }
    }
    data['bypass_duplicate'] = false;

    console.log(data);
    // axios({
    //   method: this.props.edit_mode ? 'patch' : 'post',
    //   url: window.BASE_PATH + (this.props.edit_mode ? '/patients/' + this.props.patient.id : '/patients'),
    //   data: data,
    // })
    //   .then(response => {
    //     if (response.data && response.data.is_duplicate) {
    //       const dupFieldData = response.data.duplicate_field_data;
    //       const patientType = this.state.enrollmentState.patient.isolation ? 'case' : 'monitoree';

    //       let text = `This ${patientType} already appears to exist in the system! `;

    //       if (dupFieldData) {
    //         // Format matching fields and associated counts for text display
    //         for (const fieldData of dupFieldData) {
    //           text += `There ${fieldData.count > 1 ? `are ${fieldData.count} records` : 'is 1 record'}  with matching values in the following field(s): `;
    //           let field;
    //           for (let i = 0; i < fieldData.fields.length; i++) {
    //             // parseInt() to satisfy eslint-security
    //             field = fieldData.fields[parseInt(i)];
    //             if (fieldData.fields.length > 1) {
    //               text += i == fieldData.fields.length - 1 ? `and ${field}. ` : `${field}, `;
    //             } else {
    //               text += `${field}. `;
    //             }
    //           }
    //         }
    //       }
    //       text += ` Are you sure you want to enroll this ${patientType}?`;

    //       // Duplicate, ask if want to continue with create
    //       this.handleConfirmDuplicate(data, groupMember, message, reenableButtons, text);
    //     } else {
    //       // Success, inform user and redirect to home
    //       toast.success(message, {
    //         onClose: () =>
    //           (location.href =
    //             `${window.BASE_PATH}/patients/` +
    //             (groupMember ? `${response['data']['responder_id']}/group` : response['data']['id']) +
    //             navQueryParam(this.props.workflow, true)),
    //       });
    //     }
    //   })
    //   .catch(err => {
    //     reportError(err);
    //   });
  };

  next = () => {
    window.scroll(0, 0);
    let index = this.state.index;
    let lastIndex = this.state.lastIndex;
    let delta =
      (this.state.enrollmentState.monitoring_infos[this.state.activeMonitoringInfoIndex]?.isolation && index === 5) ||
      (!this.state.enrollmentState.monitoring_infos[this.state.activeMonitoringInfoIndex]?.isolation && index === 6)
        ? 2
        : 1; // number of enrollment steps to skip (1 unless in isolation skipping exposure info on initial enrollment)

    if (lastIndex) {
      this.setState({ index: lastIndex, lastIndex: null });
    } else {
      this.setState({
        direction: 'next',
        index: index + delta,
        lastIndex: null,
        review_mode: index + delta === MAX_STEPS,
      });
    }
  };

  previous = () => {
    window.scroll(0, 0);
    let index = this.state.index;
    let delta = this.state.enrollmentState.monitoring_infos[this.state.activeMonitoringInfoIndex]?.isolation && index === 7 ? 2 : 1;
    this.setState({ direction: 'prev', index: index - delta, lastIndex: null }); // number of enrollment steps to skip (1 unless in isolation skipping exposure info on initial enrollment)
  };

  goto = (targetIndex, ignoreLastIndex) => {
    window.scroll(0, 0);
    let index = this.state.index;
    if (targetIndex > index) {
      this.setState({ direction: 'next', index: targetIndex, lastIndex: ignoreLastIndex ? null : index });
    } else if (targetIndex < index) {
      this.setState({ direction: 'prev', index: targetIndex, lastIndex: ignoreLastIndex ? null : index });
    }
  };

  review = () => {
    window.scroll(0, 0);
    let index = this.state.index;
    this.setState({
      direction: 'next',
      index: MAX_STEPS,
      lastIndex: index,
    });
  };

  render() {
    return (
      <React.Fragment>
        <Carousel
          controls={false}
          indicators={false}
          interval={null}
          keyboard={false}
          activeIndex={this.state.index}
          direction={this.state.direction}
          onSelect={() => {}}>
          <Carousel.Item>
            <Identification
              goto={this.goto}
              next={this.next}
              updateAssignedUsers={this.updateAssignedUsers}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
              race_options={this.props.race_options}
              jurisdiction_paths={this.props.jurisdiction_paths}
              has_dependents={this.props.has_dependents}
              authenticity_token={this.props.authenticity_token}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Address
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Contact
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              patient={this.props.patient}
              previous={this.previous}
              review={this.review}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
              blocked_sms={this.props.blocked_sms}
              edit_mode={this.props.edit_mode}
            />
          </Carousel.Item>
          <Carousel.Item>
            <MonitoringProgram
              next={this.next}
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              activeMonitoringInfoIndex={this.state.activeMonitoringInfoIndex}
              setMonitoringInfoIndex={this.setMonitoringInfoIndex}
              available_monitoring_programs={this.props.available_monitoring_programs}
              available_workflows={this.props.available_workflows}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Arrival
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
              activeMonitoringInfoIndex={this.state.activeMonitoringInfoIndex}
            />
          </Carousel.Item>
          <Carousel.Item>
            <AdditionalPlannedTravel
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
              activeMonitoringInfoIndex={this.state.activeMonitoringInfoIndex}
            />
          </Carousel.Item>
          <Carousel.Item>
            <ExposureInformation
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              patient={this.props.patient}
              has_dependents={this.props.has_dependents}
              assigned_users={this.state.assigned_users}
              first_positive_lab={this.props.first_positive_lab}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
              symptomatic_assessments_exist={this.props.symptomatic_assessments_exist}
              continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              edit_mode={this.props.edit_mode}
              activeMonitoringInfoIndex={this.state.activeMonitoringInfoIndex}
            />
          </Carousel.Item>
          <Carousel.Item>
            <CaseInformation
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              patient={this.props.patient}
              has_dependents={this.props.has_dependents}
              assigned_users={this.state.assigned_users}
              first_positive_lab={this.props.first_positive_lab}
              showPreviousButton={!this.props.edit_mode && !this.state.review_mode}
              activeMonitoringInfoIndex={this.state.activeMonitoringInfoIndex}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Review
              currentState={this.state.enrollmentState}
              previous={this.previous}
              goto={this.goto}
              submit={this.submit}
              setMonitoringInfoIndex={this.setMonitoringInfoIndex}
              canAddGroup={this.props.can_add_group}
              jurisdiction_paths={this.props.jurisdiction_paths}
              authenticity_token={this.props.authenticity_token}
              workflow={this.props.workflow}
              available_monitoring_programs={this.props.available_monitoring_programs}
            />
          </Carousel.Item>
        </Carousel>
        <ToastContainer position="top-center" autoClose={3000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  current_user: PropTypes.object,
  patient: PropTypes.object,
  propagated_fields: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  edit_mode: PropTypes.bool,
  enrollment_step: PropTypes.number,
  race_options: PropTypes.object,
  parent_id: PropTypes.number,
  cc_id: PropTypes.number,
  can_add_group: PropTypes.bool,
  has_dependents: PropTypes.bool,
  blocked_sms: PropTypes.bool,
  first_positive_lab: PropTypes.object,
  symptomatic_assessments_exist: PropTypes.bool,
  workflow: PropTypes.string,
  available_workflows: PropTypes.array,
  available_monitoring_programs: PropTypes.array,
  continuous_exposure_enabled: PropTypes.bool,
};

export default Enrollment;
