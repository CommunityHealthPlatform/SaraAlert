import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment-timezone';
import reportError from '../util/ReportError';
import confirmDialog from '../util/ConfirmDialog';
import { formatTimestamp, time_ago_in_words } from '../../utils/DateTime';

class History extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editMode: false,
      loading: false,
      comment: '',
    };
  }

  handleEditComment = () => {
    this.setState({ editMode: true, comment: this.props.history.comment });
  };

  handleEditCancel = () => {
    this.setState({ editMode: false, comment: '' });
  };

  handleTextChange = event => {
    this.setState({ comment: event.target.value });
  };

  handleDeleteClick = async () => {
    const confirmText = `Are you sure you would like to delete this comment?`;
    const options = {
      okLabel: 'Confirm',
      cancelLabel: 'Cancel',
    };
    if (await confirmDialog(confirmText, options)) {
      this.handleDeleteSubmit();
    }
  };

  handleDeleteSubmit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .delete(window.BASE_PATH + '/histories/' + this.props.history.id)
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  handleEditSubmit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .patch(window.BASE_PATH + '/histories/' + this.props.history.id, {
          comment: this.state.comment,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  renderHistoryActionButtons = () => {
    return (
      <React.Fragment>
        <Card.Body>
          <Card.Text>{this.props.history.comment}</Card.Text>
        </Card.Body>
        <Card.Footer>
          <Button id={this.props.history.id} className="mr-2 btn btn-primary btn-square float-right" onClick={this.handleDeleteClick}>
            Delete
          </Button>
          <Button id={this.props.history.id} className="mr-2 btn btn-primary btn-square float-right" onClick={this.handleEditComment}>
            Edit
          </Button>
        </Card.Footer>
      </React.Fragment>
    );
  };

  renderEditMode = () => {
    return (
      <Card.Body>
        <textarea
          id="comment"
          name="comment"
          className="form-control"
          style={{ resize: 'none' }}
          rows="3"
          value={this.state.comment}
          onChange={this.handleTextChange}
        />
        <button
          className="mt-3 mr-2 btn btn-primary btn-square float-right"
          disabled={this.state.loading || this.state.comment === ''}
          onClick={this.handleEditSubmit}>
          <i className="fas fa-comment-dots"></i> Edit Comment
        </button>
        <button
          className="mt-3 mr-2 btn btn-primary btn-square float-right"
          disabled={this.state.loading || this.state.comment === ''}
          onClick={this.handleEditCancel}>
          <i className="fas fa-comment-dots"></i> Cancel Edit
        </button>
      </Card.Body>
    );
  };

  renderCommentControlButtons = () => {
    if (this.props.history.history_type == 'Comment') {
      if (this.state.editMode == true) {
        return this.renderEditMode();
      } else {
        return this.renderHistoryActionButtons();
      }
    } else {
      return (
        <Card.Body>
          <Card.Text>{this.props.history.comment}</Card.Text>
        </Card.Body>
      );
    }
  };

  render() {
    return (
      <React.Fragment>
        <Card className="card-square mt-4 mx-3 shadow-sm">
          <Card.Header>
            <b>{this.props.history.created_by}</b>, {time_ago_in_words(moment(this.props.history.created_at).toDate())} ago (
            {formatTimestamp(this.props.history.created_at)})
            <span className="float-right">
              <div className="badge-padding h5">
                <span className="badge badge-secondary">{this.props.history.history_type}</span>
              </div>
            </span>
          </Card.Header>
          {this.renderCommentControlButtons()}
        </Card>
      </React.Fragment>
    );
  }
}
History.propTypes = {
  history: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default History;
