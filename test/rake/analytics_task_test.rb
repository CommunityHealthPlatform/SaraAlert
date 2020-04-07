require 'rake'
load 'lib/tasks/analytics.rake'

class AnalyticsTaskTest < ActiveSupport::TestCase

  @@monitorees = Patient.where('jurisdiction_id >= ?', 1).where('jurisdiction_id <= ?', 7)
  @@monitorees_by_exposure_week = Patient.where(jurisdiction_id: 8)
  @@monitorees_by_exposure_month = Patient.where(jurisdiction_id: 9)
  
  test "monitoree counts by total" do
    active_counts = monitoree_counts_by_total(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Overall Total', 'Total', 'Missing', 4)
    verify_monitoree_count(active_counts, 1, true, 'Overall Total', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 2, true, 'Overall Total', 'Total', 'Low', 2)
    verify_monitoree_count(active_counts, 3, true, 'Overall Total', 'Total', 'Medium', 4)
    verify_monitoree_count(active_counts, 4, true, 'Overall Total', 'Total', 'No Identified Risk', 4)
    assert_equal(5, active_counts.length)
    overall_counts = monitoree_counts_by_total(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Overall Total', 'Total', 'Missing', 4)
    verify_monitoree_count(overall_counts, 1, false, 'Overall Total', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 2, false, 'Overall Total', 'Total', 'Low', 4)
    verify_monitoree_count(overall_counts, 3, false, 'Overall Total', 'Total', 'Medium', 5)
    verify_monitoree_count(overall_counts, 4, false, 'Overall Total', 'Total', 'No Identified Risk', 4)
    assert_equal(5, overall_counts.length)
  end

  test "monitoree counts by monitoring status" do
    active_counts = monitoree_counts_by_monitoring_status(@@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Monitoring Status', 'Symptomatic', 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Monitoring Status', 'Non-Reporting', 'Missing', 2)
    verify_monitoree_count(active_counts, 2, true, 'Monitoring Status', 'Asymptomatic', 'Missing', 1)
    assert_equal(3, active_counts.length)
  end

  test "monitoree counts by age group" do
    active_counts = monitoree_counts_by_age_group(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Age Group', '0-19', 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Age Group', '0-19', 'High', 1)
    verify_monitoree_count(active_counts, 2, true, 'Age Group', '0-19', 'Low', 1)
    verify_monitoree_count(active_counts, 3, true, 'Age Group', '0-19', 'Medium', 2)
    verify_monitoree_count(active_counts, 4, true, 'Age Group', '0-19', 'No Identified Risk', 2)
    verify_monitoree_count(active_counts, 5, true, 'Age Group', '20-29', 'Missing', 2)
    verify_monitoree_count(active_counts, 6, true, 'Age Group', '30-39', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 7, true, 'Age Group', '40-49', 'Missing', 1)
    verify_monitoree_count(active_counts, 8, true, 'Age Group', '40-49', 'High', 1)
    verify_monitoree_count(active_counts, 9, true, 'Age Group', '40-49', 'Low', 1)
    verify_monitoree_count(active_counts, 10, true, 'Age Group', '40-49', 'Medium', 1)
    verify_monitoree_count(active_counts, 11, true, 'Age Group', '50-59', 'High', 1)
    verify_monitoree_count(active_counts, 12, true, 'Age Group', '60-69', 'Medium', 1)
    verify_monitoree_count(active_counts, 13, true, 'Age Group', '>=80', 'No Identified Risk', 1)
    assert_equal(14, active_counts.length)
    overall_counts = monitoree_counts_by_age_group(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Age Group', '0-19', 'Missing', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Age Group', '0-19', 'High', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Age Group', '0-19', 'Low', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Age Group', '0-19', 'Medium', 3)
    verify_monitoree_count(overall_counts, 4, false, 'Age Group', '0-19', 'No Identified Risk', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Age Group', '20-29', 'Missing', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Age Group', '30-39', 'Low', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Age Group', '30-39', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 8, false, 'Age Group', '40-49', 'Missing', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Age Group', '40-49', 'High', 1)
    verify_monitoree_count(overall_counts, 10, false, 'Age Group', '40-49', 'Low', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Age Group', '40-49', 'Medium', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Age Group', '50-59', 'High', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Age Group', '60-69', 'Low', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Age Group', '60-69', 'Medium', 1)
    verify_monitoree_count(overall_counts, 15, false, 'Age Group', '>=80', 'No Identified Risk', 1)
    assert_equal(16, overall_counts.length)
  end

  test "monitoree counts by sex" do
    active_counts = monitoree_counts_by_sex(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Sex', 'Missing', 'Medium', 1)
    verify_monitoree_count(active_counts, 1, true, 'Sex', 'Missing', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 2, true, 'Sex', 'Female', 'Missing', 2)
    verify_monitoree_count(active_counts, 3, true, 'Sex', 'Female', 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Sex', 'Female', 'Low', 1)
    verify_monitoree_count(active_counts, 5, true, 'Sex', 'Female', 'Medium', 1)
    verify_monitoree_count(active_counts, 6, true, 'Sex', 'Female', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 7, true, 'Sex', 'Male', 'Missing', 2)
    verify_monitoree_count(active_counts, 8, true, 'Sex', 'Male', 'High', 1)
    verify_monitoree_count(active_counts, 9, true, 'Sex', 'Male', 'Low', 1)
    verify_monitoree_count(active_counts, 10, true, 'Sex', 'Male', 'Medium', 1)
    verify_monitoree_count(active_counts, 11, true, 'Sex', 'Male', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 12, true, 'Sex', 'Unknown', 'High', 1)
    verify_monitoree_count(active_counts, 13, true, 'Sex', 'Unknown', 'Medium', 1)
    verify_monitoree_count(active_counts, 14, true, 'Sex', 'Unknown', 'No Identified Risk', 1)
    assert_equal(15, active_counts.length)
    overall_counts = monitoree_counts_by_sex(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Sex', 'Missing', 'Medium', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Sex', 'Missing', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Sex', 'Female', 'Missing', 2)
    verify_monitoree_count(overall_counts, 3, false, 'Sex', 'Female', 'High', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Sex', 'Female', 'Low', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Sex', 'Female', 'Medium', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Sex', 'Female', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Sex', 'Male', 'Missing', 2)
    verify_monitoree_count(overall_counts, 8, false, 'Sex', 'Male', 'High', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Sex', 'Male', 'Low', 1)
    verify_monitoree_count(overall_counts, 10, false, 'Sex', 'Male', 'Medium', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Sex', 'Male', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Sex', 'Unknown', 'High', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Sex', 'Unknown', 'Low', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Sex', 'Unknown', 'Medium', 2)
    verify_monitoree_count(overall_counts, 15, false, 'Sex', 'Unknown', 'No Identified Risk', 1)
    assert_equal(16, overall_counts.length)
  end

  test "monitoree counts by risk factor" do
    active_counts = monitoree_counts_by_risk_factor(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Risk Factor', 'Close Contact with Known Case', 'High', 1)
    verify_monitoree_count(active_counts, 1, true, 'Risk Factor', 'Close Contact with Known Case', 'Medium', 1)
    verify_monitoree_count(active_counts, 2, true, 'Risk Factor', 'Travel from Affected Country or Area', 'Missing', 1)
    verify_monitoree_count(active_counts, 3, true, 'Risk Factor', 'Travel from Affected Country or Area', 'High', 2)
    verify_monitoree_count(active_counts, 4, true, 'Risk Factor', 'Travel from Affected Country or Area', 'Medium', 2)
    verify_monitoree_count(active_counts, 5, true, 'Risk Factor', 'Travel from Affected Country or Area', 'No Identified Risk', 2)
    verify_monitoree_count(active_counts, 6, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Missing', 1)
    verify_monitoree_count(active_counts, 7, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'High', 2)
    verify_monitoree_count(active_counts, 8, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Medium', 1)
    verify_monitoree_count(active_counts, 9, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 10, true, 'Risk Factor', 'Common Exposure Cohort', 'High', 2)
    verify_monitoree_count(active_counts, 11, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'High', 2)
    verify_monitoree_count(active_counts, 12, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Medium', 1)
    verify_monitoree_count(active_counts, 13, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 14, true, 'Risk Factor', 'Laboratory Personnel', 'Medium', 1)
    verify_monitoree_count(active_counts, 15, true, 'Risk Factor', 'Laboratory Personnel', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 16, true, 'Risk Factor', 'Total', 'Missing', 2)
    verify_monitoree_count(active_counts, 17, true, 'Risk Factor', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 18, true, 'Risk Factor', 'Total', 'Medium', 2)
    verify_monitoree_count(active_counts, 19, true, 'Risk Factor', 'Total', 'No Identified Risk', 2)
    assert_equal(20, active_counts.length)
    overall_counts = monitoree_counts_by_risk_factor(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Risk Factor', 'Close Contact with Known Case', 'High', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Risk Factor', 'Close Contact with Known Case', 'Low', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Risk Factor', 'Close Contact with Known Case', 'Medium', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Missing', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Risk Factor', 'Travel from Affected Country or Area', 'High', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Low', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Medium', 2)
    verify_monitoree_count(overall_counts, 7, false, 'Risk Factor', 'Travel from Affected Country or Area', 'No Identified Risk', 2)
    verify_monitoree_count(overall_counts, 8, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Missing', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'High', 2)
    verify_monitoree_count(overall_counts, 10, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Low', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Medium', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Risk Factor', 'Healthcare Personnel', 'Low', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Risk Factor', 'Common Exposure Cohort', 'High', 2)
    verify_monitoree_count(overall_counts, 15, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'High', 2)
    verify_monitoree_count(overall_counts, 16, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Low', 1)
    verify_monitoree_count(overall_counts, 17, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Medium', 1)
    verify_monitoree_count(overall_counts, 18, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 19, false, 'Risk Factor', 'Laboratory Personnel', 'Low', 1)
    verify_monitoree_count(overall_counts, 20, false, 'Risk Factor', 'Laboratory Personnel', 'Medium', 1)
    verify_monitoree_count(overall_counts, 21, false, 'Risk Factor', 'Laboratory Personnel', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 22, false, 'Risk Factor', 'Total', 'Missing', 2)
    verify_monitoree_count(overall_counts, 23, false, 'Risk Factor', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 24, false, 'Risk Factor', 'Total', 'Low', 2)
    verify_monitoree_count(overall_counts, 25, false, 'Risk Factor', 'Total', 'Medium', 2)
    verify_monitoree_count(overall_counts, 26, false, 'Risk Factor', 'Total', 'No Identified Risk', 2)
    assert_equal(27, overall_counts.length)
  end

  test "monitoree counts by exposure country" do
    active_counts = monitoree_counts_by_exposure_country(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Exposure Country', 'China', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 1, true, 'Exposure Country', 'Faroe Islands', 'High', 1)
    verify_monitoree_count(active_counts, 2, true, 'Exposure Country', 'Faroe Islands', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 3, true, 'Exposure Country', 'Iceland', 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Exposure Country', 'Korea', 'Medium', 1)
    verify_monitoree_count(active_counts, 5, true, 'Exposure Country', 'Malaysia', 'Missing', 1)
    verify_monitoree_count(active_counts, 6, true, 'Exposure Country', 'Malaysia', 'High', 1)
    verify_monitoree_count(active_counts, 7, true, 'Exposure Country', 'Malaysia', 'Medium', 1)
    verify_monitoree_count(active_counts, 8, true, 'Exposure Country', 'Total', 'Missing', 2)
    verify_monitoree_count(active_counts, 9, true, 'Exposure Country', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 10, true, 'Exposure Country', 'Total', 'Medium', 2)
    verify_monitoree_count(active_counts, 11, true, 'Exposure Country', 'Total', 'No Identified Risk', 2)
    assert_equal(12, active_counts.length)
    overall_counts = monitoree_counts_by_exposure_country(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Exposure Country', 'Brazil', 'Low', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Exposure Country', 'China', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Exposure Country', 'Faroe Islands', 'High', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Exposure Country', 'Faroe Islands', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Exposure Country', 'Iceland', 'High', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Exposure Country', 'Malaysia', 'Missing', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Exposure Country', 'Malaysia', 'High', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Exposure Country', 'Malaysia', 'Low', 1)
    verify_monitoree_count(overall_counts, 8, false, 'Exposure Country', 'Malaysia', 'Medium', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Exposure Country', 'Total', 'Missing', 2)
    verify_monitoree_count(overall_counts, 10, false, 'Exposure Country', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 11, false, 'Exposure Country', 'Total', 'Low', 2)
    verify_monitoree_count(overall_counts, 12, false, 'Exposure Country', 'Total', 'Medium', 2)
    verify_monitoree_count(overall_counts, 13, false, 'Exposure Country', 'Total', 'No Identified Risk', 2)
    assert_equal(14, overall_counts.length)
  end

  test "monitoree counts by last exposure date" do
    active_counts = monitoree_counts_by_last_exposure_date(@@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Date', days_ago(27), 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Date', days_ago(27), 'Medium', 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Date', days_ago(26), 'High', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Date', days_ago(22), 'Low', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Date', days_ago(22), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 5, true, 'Last Exposure Date', days_ago(1), 'High', 1)
    assert_equal(6, active_counts.length)
    overall_counts = monitoree_counts_by_last_exposure_date(@@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Date', days_ago(27), 'Missing', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Date', days_ago(27), 'Medium', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Date', days_ago(26), 'High', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Date', days_ago(22), 'Low', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Date', days_ago(22), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Date', days_ago(1), 'High', 1)
    assert_equal(6, overall_counts.length)
  end

  test "monitoree counts by last exposure week" do
    active_counts = monitoree_counts_by_last_exposure_week(@@monitorees_by_exposure_week, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Week', weeks_ago(52), 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Week', weeks_ago(25), 'Low', 2)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Week', weeks_ago(19), 'Medium', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Week', weeks_ago(3), 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Week', weeks_ago(1), 'High', 1)
    assert_equal(5, active_counts.length)
    overall_counts = monitoree_counts_by_last_exposure_week(@@monitorees_by_exposure_week, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Week', weeks_ago(52), 'Missing', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Week', weeks_ago(25), 'Low', 2)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Week', weeks_ago(21), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Week', weeks_ago(19), 'Medium', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Week', weeks_ago(11), 'Medium', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Week', weeks_ago(3), 'High', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Last Exposure Week', weeks_ago(3), 'Low', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Last Exposure Week', weeks_ago(1), 'High', 1)
    assert_equal(8, overall_counts.length)
  end

  test "monitoree counts by last exposure month" do
    active_counts = monitoree_counts_by_last_exposure_month(@@monitorees_by_exposure_month, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Month', months_ago(13), 'Low', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Month', months_ago(11), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Month', months_ago(5), 'Low', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Month', months_ago(5), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Month', months_ago(2), 'Medium', 1)
    verify_monitoree_count(active_counts, 5, true, 'Last Exposure Month', months_ago(1), 'High', 1)
    verify_monitoree_count(active_counts, 6, true, 'Last Exposure Month', months_ago(1), 'Low', 1)
    assert_equal(7, active_counts.length)
    overall_counts = monitoree_counts_by_last_exposure_month(@@monitorees_by_exposure_month, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Month', months_ago(13), 'Low', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Month', months_ago(11), 'Medium', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Month', months_ago(11), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Month', months_ago(5), 'Low', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Month', months_ago(5), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Month', months_ago(2), 'Medium', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Last Exposure Month', months_ago(1), 'High', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Last Exposure Month', months_ago(1), 'Low', 1)
    assert_equal(8, overall_counts.length)
  end

  test "monitoree snapshots" do
    snapshots = all_monitoree_snapshots(@@monitorees, 1)
    verify_snapshot(snapshots, 0, 'Last 24 Hours', 3, 0, 1, 0, 2, 2, 1, 1, 1, 1, 1)
    verify_snapshot(snapshots, 2, 'Total', 20, 0, 3, 0, 3, 3, 2, 2, 2, 2, 2)
    snapshots = all_monitoree_snapshots(Patient.where(jurisdiction_id: 2), 2)
    verify_snapshot(snapshots, 0, 'Last 24 Hours', 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0)
    verify_snapshot(snapshots, 2, 'Total', 6, 2, 1, 2, 0, 0, 0, 0, 0, 1, 1)
  end

  def verify_monitoree_count(monitoree_counts, index, active_monitoring, category_type, category, risk_level, count)
    assert_equal(active_monitoring, monitoree_counts[index].active_monitoring, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category_type, monitoree_counts[index].category_type, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category, monitoree_counts[index].category, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(risk_level, monitoree_counts[index].risk_level, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(count, monitoree_counts[index].total, monitoree_count_err_msg(index, active_monitoring, category_type))
  end

  def verify_snapshot(snapshots, index, time_frame, new_enrollments, transferred_in, closed, transferred_out,
                      referral_for_medical_evaluation, document_completed_medical_evaluation, document_medical_evaluation_summary_and_plan,
                      referral_for_public_health_test, public_health_test_specimen_received_by_lab_results_pending,
                      results_of_public_health_test_positive, results_of_public_health_test_negative)
    assert_equal(time_frame, snapshots[index].time_frame, 'Time frame')
    assert_equal(new_enrollments, snapshots[index].new_enrollments, 'New enrollments')
    assert_equal(transferred_in, snapshots[index].transferred_in, 'Incoming transfers')
    assert_equal(closed, snapshots[index].closed, 'Closed patients')
    assert_equal(transferred_out, snapshots[index].transferred_out, 'Outgoing transfers')
    assert_equal(referral_for_medical_evaluation, snapshots[index].referral_for_medical_evaluation, 'Referral for Medical Evaluation')
    assert_equal(document_completed_medical_evaluation, snapshots[index].document_completed_medical_evaluation, 'Document Completed Medical Evaluation')
    assert_equal(document_medical_evaluation_summary_and_plan, snapshots[index].document_medical_evaluation_summary_and_plan, 'Document Medical Evaluation Summary and Plan')
    assert_equal(referral_for_public_health_test, snapshots[index].referral_for_public_health_test, 'Referral for Public Health Test')
    assert_equal(public_health_test_specimen_received_by_lab_results_pending, snapshots[index].public_health_test_specimen_received_by_lab_results_pending, 'Public Health Test Specimen Received by Lab - results pending')
    assert_equal(results_of_public_health_test_positive, snapshots[index].results_of_public_health_test_positive, 'Results of Public Health Test - positive')
    assert_equal(results_of_public_health_test_negative, snapshots[index].results_of_public_health_test_negative, 'Results of Public Health Test - negative')
  end

  def get_absolute_date(relative_date)
    eval(relative_date.tr('<%=  =>', ''))
  end

  def days_ago(num_days)
    num_days.days.ago.strftime('%F')
  end

  def weeks_ago(num_weeks)
    num_weeks.weeks.ago.beginning_of_week(start_day = :sunday).strftime('%F')
  end

  def months_ago(num_months)
    num_months.months.ago.beginning_of_month.strftime('%F')
  end

  def monitoree_count_err_msg(index, active_monitoring, category_type)
    "Incorrect count for #{category_type}: #{index} (#{active_monitoring ? 'active' : 'overall'})"
  end
end