class ApiConfig {
  // 1. သင့် AWS Public IP
  // static const String baseUrl = 'https://wriggly-willfully-chevron.ngrok-free.dev';
  static const String baseUrl = 'http://10.114.214.88:8000';

  // 3. Admin API Endpoints
  static const String loan_categories = '$baseUrl/api/loan-categories/';
  static const String category = '$baseUrl/api/category/';
  static const String add_category = '$baseUrl/api/add-category/';
  static const String dashboard = '$baseUrl/api/admin-dashboard-data/';
  static const String adminlogin = '$baseUrl/api/admin-login/';
  static const String confirmpayment = '$baseUrl/api/confirm-payment-request/';
  static const String rejectpayment = '$baseUrl/api/reject-payment-request/';
  static const String pendingpayment = '$baseUrl/api/pending-payment-requests/';
  static const String approvedhistory = '$baseUrl/api/approved-history/';
  static const String customers = '$baseUrl/api/customers/';
  static const String documentreviewlist =
      '$baseUrl/api/documents-review-list/';
  static const String processloandecision =
      '$baseUrl/api/process-loan-decision/';
  static const String userloandetail = '$baseUrl/api/user-loan-detail/';
  static const String saveloanhistory = '$baseUrl/api/save-loan-history/';
  static const String repaymentschedule = '$baseUrl/api/repayment-schedule/';
  static const String loan_payment_and_schedule =
      '$baseUrl/api/loan_payment_and_schedule/';
  static const String loansummary = '$baseUrl/api/loan-summary-report/';

  //User API Endpoints
  static const String loginUrl = '$baseUrl/api/login/';
  static const String updateprofile = '$baseUrl/api/update-profile/';
  static const String paymenthistory = '$baseUrl/api/payment-history/';
  static const String usercategory = '$baseUrl/api/user_category/';
  static const String homesummary = '$baseUrl/api/home-summary/';
  static const String notificationcount = '$baseUrl/api/notification-count/';
  static const String userprofile = '$baseUrl/api/user-profile/';
  static const String notifications = '$baseUrl/api/notifications/';
  static const String marknotification =
      '$baseUrl/api/mark-notifications-read/';
  static const String verifyotp = '$baseUrl/api/verify-otp/';
  static const String resendotp = '$baseUrl/api/resend-otp/';
  static const String paymentrequest = '$baseUrl/api/payment-request/';
  static const String calculate = '$baseUrl/api/calculate/';
  static const String register = '$baseUrl/api/register/';
  static const String userstatus = '$baseUrl/api/v2/check-user-status/';
  static const String usercheck = '$baseUrl/api/check-loan/';
}
