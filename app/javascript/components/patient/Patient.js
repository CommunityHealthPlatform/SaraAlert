import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faChevronRight } from '@fortawesome/free-solid-svg-icons';

import BadgeHoH from './icons/BadgeHoH';
import InfoTooltip from '../util/InfoTooltip';
import { convertLanguageCodesToNames } from '../../utils/Languages';
import { formatName, formatPhoneNumberVisually, formatRace, isMinor } from '../../utils/Patient';
import FollowUpFlagPanel from './follow_up_flag/FollowUpFlagPanel';
import FollowUpFlagModal from './follow_up_flag/FollowUpFlagModal';
import { navQueryParam, patientHref } from '../../utils/Navigation';

class Patient extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: props.edit_mode || !props.collapse,
      expandNotes: false,
      expandArrivalNotes: false,
      expandPlannedTravelNotes: false,
      primaryLanguageDisplayName: null,
      showSetFlagModal: false,
    };
  }

  componentDidMount() {
    convertLanguageCodesToNames([this.props.details?.primary_language], this.props.authenticity_token, res => {
      this.setState({ primaryLanguageDisplayName: res[0] });
    });
  }

  componentDidUpdate(nextProps, prevState) {
    // The way that Enrollment is structured, this Patient component is not re-mounted when reviewing a Patient
    // We need to update the `primaryLanguageDisplayName`. We reset `primary_language` below to break out of the
    // infinite loop that not resetting it will cause. You cannot use `getDerivedStateFromProps` here due to the
    // async nature of convertLanguageCodesToNames()
    if (nextProps.details?.primary_language !== prevState.details?.primary_language) {
      convertLanguageCodesToNames([nextProps.details?.primary_language], this.props.authenticity_token, res => {
        this.setState({
          details: { ...nextProps.details, primary_language: nextProps.details?.primary_language },
          primaryLanguageDisplayName: res[0],
        });
      });
    }
  }

  /**
   * Renders the edit link depending on if the user is coming from the monitoree details section or summary of the enrollment wizard.
   * @param {String} section - title of the monitoree details section
   * @param {Number} enrollmentStep - the number of the step for the section within the enrollment wizard
   */
  renderEditLink(section, enrollmentStep) {
    let sectionId = `edit-${section.replace(/\s+/g, '_').toLowerCase()}-btn`;
    if (section === 'Case Information') {
      sectionId = 'edit-potential_exposure_information-btn';
    }
    if (this.props.goto) {
      return (
        <div className="edit-link">
          <Button variant="link" id={sectionId} className="py-0" onClick={() => this.props.goto(enrollmentStep)} aria-label={`Edit ${section}`}>
            Edit
          </Button>
        </div>
      );
    } else {
      return (
        <div className="edit-link">
          <a
            href={`${window.BASE_PATH}/patients/${this.props.details.id}/edit?step=${enrollmentStep}${navQueryParam(this.props.workflow, false)}`}
            id={sectionId}
            aria-label={`Edit ${section}`}>
            Edit
          </a>
        </div>
      );
    }
  }

  render() {
    if (!this.props.details) {
      return <React.Fragment>No monitoree details to show.</React.Fragment>;
    }

    const showDomesticAddress =
      this.props.details.address_line_1 ||
      this.props.details.address_line_2 ||
      this.props.details.address_city ||
      this.props.details.address_state ||
      this.props.details.address_zip ||
      this.props.details.address_county;

    return (
      <React.Fragment>
        <Row id="monitoree-details-header" className="mb-3">
          {this.props.can_modify_subject_status && !this.props.edit_mode && this.props.details.follow_up_reason && (
            <FollowUpFlagPanel
              patient={this.props.details}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              authenticity_token={this.props.authenticity_token}
              other_household_members={this.props.other_household_members}
              bulkAction={false}
            />
          )}
          <Col sm={12}>
            <h3>
              <span aria-label={formatName(this.props.details)} className="pr-2">
                {formatName(this.props.details)}
              </span>
            </h3>
          </Col>
          <Col sm={12}>
            <div className="jurisdiction-user-box float-right">
              <div id="jurisdiction-path">
                <b>
                  <span className="d-none d-md-inline">Assigned</span> Jurisdiction:
                </b>{' '}
                {this.props.jurisdiction_paths[this.props.details.jurisdiction_id] || '--'}
              </div>
              <div id="assigned-user">
                <b>Assigned User:</b> {this.props.details.assigned_user || '--'}
              </div>
            </div>
          </Col>
        </Row>
        <Row>
          <Col id="identification" lg={14} className="col-xxl-12">
            <div className="section-header">
              <h4 className="section-title">Identification</h4>
              {this.renderEditLink('Identification', 0)}
            </div>
            <Row>
              <Col sm={10} className="item-group">
                <div>
                  <b>DOB:</b> <span>{this.props.details.date_of_birth && moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                  {this.props.details.date_of_birth && isMinor(this.props.details.date_of_birth) && <span className="text-danger"> (Minor)</span>}
                </div>
                <div>
                  <b>Age:</b> <span>{this.props.details.age || '--'}</span>
                </div>
                <div>
                  <b>Language:</b> <span>{this.state.primaryLanguageDisplayName || '--'}</span>
                </div>
                <div>
                  <b>Sara Alert ID:</b> <span>{this.props.details.id || '--'}</span>
                </div>
              </Col>
              <Col sm={14} className="item-group">
                <div>
                  <b>Birth Sex:</b> <span>{this.props.details.sex || '--'}</span>
                </div>
                <div>
                  <b>Gender Identity:</b> <span>{this.props.details.gender_identity || '--'}</span>
                </div>
                <div>
                  <b>Sexual Orientation:</b> <span>{this.props.details.sexual_orientation || '--'}</span>
                </div>
                <div>
                  <b>Race:</b> <span>{formatRace(this.props.details)}</span>
                </div>
                <div>
                  <b>Ethnicity:</b> <span>{this.props.details.ethnicity || '--'}</span>
                </div>
                <div>
                  <b>Nationality:</b> <span>{this.props.details.nationality || '--'}</span>
                </div>
              </Col>
            </Row>
          </Col>
          <Col id="contact-information" lg={10} className="col-xxl-12">
            <div className="section-header">
              <h4 className="section-title">Contact Information</h4>
              {this.renderEditLink('Contact Information', 2)}
            </div>
            <div className="item-group">
              {this.props.details.date_of_birth && isMinor(this.props.details.date_of_birth) && (
                <React.Fragment>
                  <span className="text-danger">Monitoree is a minor</span>
                  {!this.props.details.head_of_household && this.props.hoh && (
                    <div>
                      View contact info for Head of Household:
                      <a className="pl-1" href={patientHref(this.props.hoh.id, this.props.workflow)}>
                        {formatName(this.props.hoh)}
                      </a>
                    </div>
                  )}
                </React.Fragment>
              )}
              <div>
                <b>Phone:</b> <span>{this.props.details.primary_telephone ? `${formatPhoneNumberVisually(this.props.details.primary_telephone)}` : '--'}</span>
                {this.props.details.blocked_sms && (
                  <span className="font-weight-bold pl-2">
                    SMS Blocked
                    <InfoTooltip tooltipTextKey="blockedSMS" location="top" />
                  </span>
                )}
              </div>
              <div>
                <b>Preferred Contact Time:</b> <span>{this.props.details.preferred_contact_time || '--'}</span>
              </div>
              <div>
                <b>Primary Telephone Type:</b> <span>{this.props.details.primary_telephone_type || '--'}</span>
              </div>
              <div>
                <b>Email:</b> <span>{this.props.details.email || '--'}</span>
              </div>
              <div>
                <b>Preferred Reporting Method:</b>{' '}
                {(!this.props.details.blocked_sms || !this.props.details.preferred_contact_method?.includes('SMS')) && (
                  <span>{this.props.details.preferred_contact_method || '--'}</span>
                )}
                {this.props.details.blocked_sms && this.props.details.preferred_contact_method?.includes('SMS') && (
                  <span className="font-weight-bold text-danger">
                    {this.props.details.preferred_contact_method}
                    <InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="top" />
                  </span>
                )}
              </div>
            </div>
          </Col>
        </Row>
        {!this.props.edit_mode && (
          <div className="details-expander mb-3">
            <Button
              id="details-expander-link"
              variant="link"
              className="p-0"
              aria-label="Show address"
              onClick={() => this.setState({ expanded: !this.state.expanded })}>
              <FontAwesomeIcon className={this.state.expanded ? 'chevron-opened' : 'chevron-closed'} icon={faChevronRight} />
              <span className="pl-2">{this.state.expanded ? 'Hide' : 'Show'} address</span>
            </Button>
            <span className="dashed-line"></span>
          </div>
        )}
        <Collapse in={this.state.expanded}>
          <div>
            <Row>
              <Col id="address" lg={14} xl={12} className="col-xxxl-10">
                <div className="section-header">
                  <h4 className="section-title">Address</h4>
                  {this.renderEditLink('Address', 1)}
                </div>
                {!showDomesticAddress && <div className="none-text">None</div>}
                {showDomesticAddress && (
                  <Row>
                    {showDomesticAddress && (
                      <Col sm={24} className="item-group">
                        <p className="subsection-title">Home Address (USA)</p>
                        <div>
                          <b>Address 1:</b> <span>{this.props.details.address_line_1 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 2:</b> <span>{this.props.details.address_line_2 || '--'}</span>
                        </div>
                        <div>
                          <b>Town/City:</b> <span>{this.props.details.address_city || '--'}</span>
                        </div>
                        <div>
                          <b>State:</b> <span>{this.props.details.address_state || '--'}</span>
                        </div>
                        <div>
                          <b>Zip:</b> <span>{this.props.details.address_zip || '--'}</span>
                        </div>
                        <div>
                          <b>County:</b> <span>{this.props.details.address_county || '--'}</span>
                        </div>
                      </Col>
                    )}
                  </Row>
                )}
              </Col>
            </Row>
          </div>
        </Collapse>
        {this.state.showSetFlagModal && (
          <FollowUpFlagModal
            show={this.state.showSetFlagModal}
            patient={this.props.details}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            authenticity_token={this.props.authenticity_token}
            other_household_members={this.props.other_household_members}
            close={() => this.setState({ showSetFlagModal: false })}
            clear_flag={false}
          />
        )}
      </React.Fragment>
    );
  }
}

Patient.propTypes = {
  current_user: PropTypes.object,
  details: PropTypes.object,
  hoh: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  goto: PropTypes.func,
  edit_mode: PropTypes.bool,
  collapse: PropTypes.bool,
  other_household_members: PropTypes.array,
  can_modify_subject_status: PropTypes.bool,
  authenticity_token: PropTypes.string,
  workflow: PropTypes.string,
};

export default Patient;
