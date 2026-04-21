import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// AppBar title for manual expense entry screen & Floating action button option - Manual expense entry
  ///
  /// In en, this message translates to:
  /// **'Add Expense Manually'**
  String get addExpense;

  /// Label for store name input field
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// Hint text for store name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Migros, A101'**
  String get storeNameHint;

  /// Label for date selection field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for category dropdown & selection
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Text on the AI category suggestion button
  ///
  /// In en, this message translates to:
  /// **'AI Suggest'**
  String get aiSuggest;

  /// Section header for adding a new product/item & Section header for adding a new product/item
  ///
  /// In en, this message translates to:
  /// **'ADD ITEM'**
  String get addItem;

  /// Label above product name input & Hint text for product name in manual add/edit sheet
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// Hint text in product name field
  ///
  /// In en, this message translates to:
  /// **'What did you buy?'**
  String get productNameHint;

  /// Hint text for price input field
  ///
  /// In en, this message translates to:
  /// **'Price (₺)'**
  String get price;

  /// Hint text for quantity input field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Button text to add product to the list
  ///
  /// In en, this message translates to:
  /// **'+ Add to List'**
  String get addToList;

  /// Header for the list of added products
  ///
  /// In en, this message translates to:
  /// **'PURCHASE LIST'**
  String get purchaseList;

  /// Text next to the number of items in purchase list
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get itemsCount;

  /// Helper text below purchase list header & detected products header
  ///
  /// In en, this message translates to:
  /// **'Tap item to edit  •  Swipe left to delete'**
  String get tapToEditSwipeToDelete;

  /// Empty state text when no products added yet
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// Label for the total amount section
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Text on the main save button at the bottom
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// Title of bottom sheet when adding a new item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemTitle;

  /// Title of bottom sheet when editing an existing item & Button to enable editing mode
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItemTitle;

  /// Validation error for price <= 0
  ///
  /// In en, this message translates to:
  /// **'Price must be > 0'**
  String get priceMustBeGreaterThanZero;

  /// Validation error for quantity <= 0
  ///
  /// In en, this message translates to:
  /// **'Qty must be > 0'**
  String get qtyMustBeGreaterThanZero;

  /// Error message when trying to save without store name
  ///
  /// In en, this message translates to:
  /// **'Store name cannot be empty'**
  String get storeNameCannotBeEmpty;

  /// Error message when trying to save with no products
  ///
  /// In en, this message translates to:
  /// **'Add at least one product'**
  String get addAtLeastOneProduct;

  /// Error message when adding product with invalid data
  ///
  /// In en, this message translates to:
  /// **'Enter valid product'**
  String get enterValidProduct;

  /// Prefix for AI category prediction error snackbar
  ///
  /// In en, this message translates to:
  /// **'AI error: '**
  String get aiError;

  /// AppBar title for Analytics screen & Button text to navigate to detailed Analytics screen
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Header for the weekly spending line chart section
  ///
  /// In en, this message translates to:
  /// **'Spending Trend'**
  String get spendingTrend;

  /// Label above the weekly line chart
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Header for the horizontal category budget cards
  ///
  /// In en, this message translates to:
  /// **'Category Budgets'**
  String get categoryBudgets;

  /// Placeholder text when no date range is selected
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get selectRange;

  /// Section header for monthly insights
  ///
  /// In en, this message translates to:
  /// **'MONTHLY INSIGHTS'**
  String get monthlyInsights;

  /// Label for the top spending category
  ///
  /// In en, this message translates to:
  /// **'HIGHEST SPENDING CATEGORY'**
  String get highestSpendingCategory;

  /// Label for average daily spending this month
  ///
  /// In en, this message translates to:
  /// **'AVERAGE DAILY SPEND (SO FAR THIS MONTH)'**
  String get averageDailySpend;

  /// Header for the top spending merchant card
  ///
  /// In en, this message translates to:
  /// **'Top Merchant'**
  String get topMerchant;

  /// Placeholder text shown when there is no data
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// Text after the number of transactions for top merchant
  ///
  /// In en, this message translates to:
  /// **'transaction'**
  String get transactionsCount;

  /// Suffix for average daily spend (e.g. ₺XX.XX / day)
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDay;

  /// Abbreviated day name for chart - Monday
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// Abbreviated day name for chart - Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// Abbreviated day name for chart - Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// Abbreviated day name for chart - Thursday
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// Abbreviated day name for chart - Friday
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// Abbreviated day name for chart - Saturday
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// Abbreviated day name for chart - Sunday
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// App title shown in the header of Home screen
  ///
  /// In en, this message translates to:
  /// **'Digital Receipt Wallet'**
  String get digitalReceiptWallet;

  /// Label for the total monthly spending in the summary card
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// Text shown when user has not set a monthly budget
  ///
  /// In en, this message translates to:
  /// **'No monthly budget set yet'**
  String get noMonthlyBudgetSetYet;

  /// Label for remaining budget amount
  ///
  /// In en, this message translates to:
  /// **'LIMIT LEFT'**
  String get limitLeft;

  /// Text shown on the budget usage chip (e.g. 65% USED)
  ///
  /// In en, this message translates to:
  /// **'USED'**
  String get percentUsed;

  /// Header for the recent transactions section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Button text to navigate to full transactions history
  ///
  /// In en, this message translates to:
  /// **'See History'**
  String get seeHistory;

  /// Empty state title when there are no receipts
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get noReceiptsYet;

  /// Empty state subtitle on home screen
  ///
  /// In en, this message translates to:
  /// **'Your scanned receipts will appear here'**
  String get yourScannedReceiptsWillAppearHere;

  /// Bottom navigation bar - Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bottom navigation bar - Reports tab label & AppBar title for Reports screen
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Bottom navigation bar - Settings tab label & AppBar title for Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Floating action button option - Scan receipt with camera & AppBar title for receipt scanning screen
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// Floating action button option - Upload PDF or receipt image
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt / PDF Statement'**
  String get uploadReceiptPdf;

  /// Main greeting title on the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Subtitle below the welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your receipts'**
  String get signInToManageYourReceipts;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Text on the main login button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Text on the button that navigates to sign up screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAnAccount;

  /// Generic fallback error message when login fails
  ///
  /// In en, this message translates to:
  /// **'Login error'**
  String get loginError;

  /// AppBar title for transaction detail screen
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// Section header for the list of purchased items
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Empty state message when no products are found in the transaction
  ///
  /// In en, this message translates to:
  /// **'No items recorded'**
  String get noItemsRecorded;

  /// Source label when transaction was created by scanning
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get scanned;

  /// Source label when transaction was created from PDF & Tab label for bank statement PDF upload
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// Source label when transaction was added manually
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// Label for the final total amount row
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// AppBar title for profile details screen & ListTile title for navigating to profile details
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// Label for the user's display name field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Hint text for display name input field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// Label for email address field with note about re-login
  ///
  /// In en, this message translates to:
  /// **'Email Address (Requires Re-login)'**
  String get emailAddress;

  /// Hint text for email input field
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get yourEmailHint;

  /// Label for current password field (when changing email or password)
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Hint text for current password when changing email
  ///
  /// In en, this message translates to:
  /// **'Required to change email'**
  String get requiredToChangeEmail;

  /// Section header for password change
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Hint text for current password field in change password section
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordHint;

  /// Hint text for new password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordHint;

  /// Hint text for confirm new password field
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// Success message when email change verification is sent
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Please check your inbox.'**
  String get verificationEmailSent;

  /// Success message after profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccessfully;

  /// Error message when display name is empty
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get nameCannotBeEmpty;

  /// Error message when new password is too short
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get newPasswordMustBeAtLeast6;

  /// Error message when new password and confirmation do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// Error message when current password is required but empty
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// Error message when trying to change email without entering password
  ///
  /// In en, this message translates to:
  /// **'Enter your password to change email.'**
  String get enterPasswordToChangeEmail;

  /// Error message for wrong password
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get incorrectPassword;

  /// Error message when new email is already taken
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailAlreadyInUse;

  /// Error message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get anErrorOccurred;

  /// Info text shown when user changes email
  ///
  /// In en, this message translates to:
  /// **'A verification email will be sent to the new address.'**
  String get aVerificationEmailWillBeSent;

  /// Text on the floating action button
  ///
  /// In en, this message translates to:
  /// **'Add Recurring'**
  String get addRecurring;

  /// Empty state title when there are no recurring transactions
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions'**
  String get noRecurringTransactions;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to add subscriptions, rent, etc.'**
  String get tapToAddSubscriptionsRentEtc;

  /// Section header for paused recurring transactions
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get paused;

  /// Badge text shown when a recurring payment is due within 3 days
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoon;

  /// Label before the next due date (Next: 15 Apr 2026)
  ///
  /// In en, this message translates to:
  /// **'Next:'**
  String get next;

  /// Title of the delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring'**
  String get deleteRecurring;

  /// Content of delete confirmation dialog. Use {{storeName}} as placeholder
  ///
  /// In en, this message translates to:
  /// **'Remove \"{storeName}\" from recurring transactions?'**
  String removeFromRecurring(Object storeName);

  /// Cancel button in delete dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button in confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title of the form sheet when adding a new recurring transaction
  ///
  /// In en, this message translates to:
  /// **'New Recurring'**
  String get newRecurring;

  /// Title of the form sheet when editing an existing recurring transaction
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring'**
  String get editRecurring;

  /// Label for store name field in recurring form
  ///
  /// In en, this message translates to:
  /// **'Name / Store'**
  String get nameOrStore;

  /// Label for amount field in recurring form
  ///
  /// In en, this message translates to:
  /// **'Amount (₺)'**
  String get amountTL;

  /// Label above frequency selection chips
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Label for start date picker in recurring form
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Label for optional note field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// Text on save button when creating new recurring
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Text on save button when editing recurring
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Tooltip for resume button on paused recurring card
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Tooltip for pause button on active recurring card
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Tooltip for edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Button label for adjusting monthly budget
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// Button label for setting budget alert
  ///
  /// In en, this message translates to:
  /// **'Set Alert'**
  String get setAlert;

  /// Shorter label used on the budget button
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get adjustBudget;

  /// Title of the budget alert bottom sheet (Turkish mixed for now, can be changed)
  ///
  /// In en, this message translates to:
  /// **'Set Alert'**
  String get alertAyari;

  /// Description text in alert bottom sheet. Use {percentage} as placeholder
  ///
  /// In en, this message translates to:
  /// **'Notify me when I have spent %{percentage} of my budget'**
  String alertDescription(Object percentage);

  /// Button to disable/remove budget alert
  ///
  /// In en, this message translates to:
  /// **'Cancel Alert'**
  String get cancelAlert;

  /// General save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Snackbar message when alert is cancelled
  ///
  /// In en, this message translates to:
  /// **'Alert removed'**
  String get alertRemoved;

  /// Success message when alert is set. Use {percentage} as placeholder
  ///
  /// In en, this message translates to:
  /// **'Alert set for %{percentage} of budget'**
  String alertSetFor(Object percentage);

  /// Success message after updating monthly budget
  ///
  /// In en, this message translates to:
  /// **'Budget updated to ₺{amount}'**
  String budgetUpdatedTo(Object amount);

  /// Error message when budget field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a budget amount'**
  String get pleaseEnterBudgetAmount;

  /// Error message when budget amount is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// Loading text while generating statement
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Button text for exporting monthly statement as PDF
  ///
  /// In en, this message translates to:
  /// **'Export Statement'**
  String get exportStatement;

  /// Error message when PDF generation fails
  ///
  /// In en, this message translates to:
  /// **'Statement could not be generated: {error}'**
  String statementCouldNotBeGenerated(Object error);

  /// Text shown when there is no previous month data for comparison
  ///
  /// In en, this message translates to:
  /// **'No data for previous month'**
  String get noDataForPreviousMonth;

  /// Word used in 'X% increase'
  ///
  /// In en, this message translates to:
  /// **'increase'**
  String get increase;

  /// Word used in 'X% decrease'
  ///
  /// In en, this message translates to:
  /// **'decrease'**
  String get decrease;

  /// Text shown when there is no change compared to previous month
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get noChange;

  /// Label for daily average spending
  ///
  /// In en, this message translates to:
  /// **'DAILY AVERAGE'**
  String get dailyAverage;

  /// Warning when user tries to set alert but notifications are off
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Please enable them from settings.'**
  String get notificationsAreDisabled;

  /// Placeholder text when no receipt photo is taken yet
  ///
  /// In en, this message translates to:
  /// **'No Image Captured'**
  String get noImageCaptured;

  /// Button text to capture a new receipt photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Button text to retake the receipt photo
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// Header for the section showing scanned data
  ///
  /// In en, this message translates to:
  /// **'Extraction Results'**
  String get extractionResults;

  /// Button to exit editing mode
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Small text shown when category is suggested by AI
  ///
  /// In en, this message translates to:
  /// **'AI suggested ⚡'**
  String get aiSuggested;

  /// Header for the list of scanned products
  ///
  /// In en, this message translates to:
  /// **'Detected Products'**
  String get detectedProducts;

  /// Empty state when no products were extracted from the receipt
  ///
  /// In en, this message translates to:
  /// **'No products detected'**
  String get noProductsDetected;

  /// Button to manually add a product
  ///
  /// In en, this message translates to:
  /// **'+ Add Item Manually'**
  String get addItemManually;

  /// Main button to save the scanned receipt
  ///
  /// In en, this message translates to:
  /// **'Save Receipt'**
  String get saveReceipt;

  /// Error message when trying to save without scanning
  ///
  /// In en, this message translates to:
  /// **'Please scan a receipt first'**
  String get pleaseScanReceiptFirst;

  /// Error when total amount is zero or negative
  ///
  /// In en, this message translates to:
  /// **'Total amount must be greater than 0'**
  String get totalMustBeGreaterThanZero;

  /// Title of bottom sheet when editing an existing product
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// Validation error for empty product name
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get nameRequired;

  /// Error when AI response is not valid JSON
  ///
  /// In en, this message translates to:
  /// **'Invalid receipt scan'**
  String get invalidReceiptScan;

  /// Error when no products or total found in scan
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a receipt'**
  String get thisDoesntLookLikeAReceipt;

  /// Prefix for general scan errors
  ///
  /// In en, this message translates to:
  /// **'Scan error: '**
  String get scanError;

  /// Section header for personal account settings
  ///
  /// In en, this message translates to:
  /// **'PERSONAL ACCOUNT'**
  String get personalAccount;

  /// Subtitle for Profile Details option
  ///
  /// In en, this message translates to:
  /// **'Change name, email, and avatar'**
  String get changeNameEmailAndAvatar;

  /// Section header for app preferences
  ///
  /// In en, this message translates to:
  /// **'APP PREFERENCES'**
  String get appPreferences;

  /// Title for notification settings
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Subtitle for push notifications
  ///
  /// In en, this message translates to:
  /// **'Alerts for large transactions'**
  String get alertsForLargeTransactions;

  /// Title for theme (light/dark) settings
  ///
  /// In en, this message translates to:
  /// **'Visual Theme'**
  String get visualTheme;

  /// Subtitle for theme switch
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark'**
  String get switchBetweenLightAndDark;

  /// Title for language selection
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE OPTIONS'**
  String get language;

  /// Subtitle for language selection
  ///
  /// In en, this message translates to:
  /// **'Select App Language'**
  String get selectAppLanguage;

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Error message when user denies notification permission
  ///
  /// In en, this message translates to:
  /// **'You must allow notifications.'**
  String get notificationsDisabledPermission;

  /// Message shown when user turns off notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications turned off. You can fully disable them from device settings.'**
  String get notificationsTurnedOff;

  /// Action button text in snackbar for opening app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get goToSettings;

  /// Main title on the sign up screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Subtitle below the create account title
  ///
  /// In en, this message translates to:
  /// **'Sign up to start managing your receipts'**
  String get signUpToStartManagingYourReceipts;

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Text on the main sign up button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// Text on the button that navigates to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAnAccount;

  /// Generic fallback error message for sign up failures
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Main slogan displayed on the splash screen
  ///
  /// In en, this message translates to:
  /// **'TRACK SMARTER. SPEND BETTER.'**
  String get splashSlogan;

  /// Title of the Transactions screen & Bottom navigation bar - Transactions tab label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Placeholder text for the search field
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// Menu item in the more options menu for navigating to recurring transactions & AppBar title and main screen title for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get recurringTransactions;

  /// Empty state title shown when there are no transactions
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// Empty state subtitle shown when there are no transactions
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here'**
  String get yourTransactionsWillAppearHere;

  /// Category filter option - shows all transactions
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get tech;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get healthcare;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get personalCare;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Household / Furniture'**
  String get householdFurniture;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Stationery'**
  String get stationery;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Vacation / Travel'**
  String get vacationTravel;

  /// Transaction category name
  ///
  /// In en, this message translates to:
  /// **'Taxes / Official Payments'**
  String get taxesOfficialPayments;

  /// Transaction category name - fallback category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Filter option in date filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Filter option in date filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Fallback text for date filter chip when custom dates are selected
  ///
  /// In en, this message translates to:
  /// **'Custom Date'**
  String get customDate;

  /// Header shown above transactions that occurred today (used in Transactions and Home screens)
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// Header shown above transactions that occurred yesterday (used in Transactions and Home screens)
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterday;

  /// AppBar title for Upload Receipt / PDF screen
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get uploadReceipt;

  /// Tab label for image/receipt upload
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Placeholder when no image is selected from gallery
  ///
  /// In en, this message translates to:
  /// **'No Image Selected'**
  String get noImageSelected;

  /// Button text to pick image from gallery
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// Button text to change already selected image
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// Header for PDF upload card
  ///
  /// In en, this message translates to:
  /// **'Upload Bank Statement'**
  String get uploadEkstre;

  /// Hint text when no PDF is selected
  ///
  /// In en, this message translates to:
  /// **'Select your bank statement'**
  String get selectBankStatement;

  /// Hint when PDF is already selected
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get changePdf;

  /// Button to start AI analysis of the PDF
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// Loading text while processing PDF
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// Label for total outgoing amount
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// Label for total incoming amount
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// Label for bank name in PDF summary
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// Label for statement period in PDF summary
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// Button to save all parsed PDF transactions
  ///
  /// In en, this message translates to:
  /// **'Save Transactions'**
  String get saveTransactions;

  /// Error when trying to save without selecting categories
  ///
  /// In en, this message translates to:
  /// **'Please select a category for all transactions'**
  String get pleaseSelectAllCategories;

  /// Error when PDF analysis returns no movements
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// Prefix for PDF processing errors
  ///
  /// In en, this message translates to:
  /// **'PDF Error: '**
  String get pdfError;

  /// Prefix for general upload errors
  ///
  /// In en, this message translates to:
  /// **'Upload error: '**
  String get uploadError;

  /// Frequency option for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// Frequency option for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// Frequency option for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// Frequency option for recurring transactions
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get frequencyYearly;

  /// Title for the monthly statement PDF
  ///
  /// In en, this message translates to:
  /// **'Monthly Statement'**
  String get monthlyStatement;

  /// Label for total spending amount
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get totalSpending;

  /// Label for the number of transactions in the statement
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionCount;

  /// Label for the budget usage section in the statement
  ///
  /// In en, this message translates to:
  /// **'Budget Used'**
  String get budgetUsed;

  /// Header for the category breakdown section in the statement
  ///
  /// In en, this message translates to:
  /// **'Category Summary'**
  String get categorySummary;

  /// Header for the transaction details section in the statement
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// Label for store name in transaction details
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// Label for amount in transaction details
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Credit line for the generated statement
  ///
  /// In en, this message translates to:
  /// **'Generated by Digital Receipt Wallet'**
  String get generatedBy;

  /// Base file name for the generated PDF statement (without extension)
  ///
  /// In en, this message translates to:
  /// **'monthly_statement'**
  String get statementFileName;

  /// No description provided for @budgetUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'%{value}'**
  String budgetUsedPercent(String value);

  /// Title for the push notification when user reaches 100% of their monthly budget
  ///
  /// In en, this message translates to:
  /// **'Budget Fully Used 💸'**
  String get notificationBudgetFullTitle;

  /// Body text for the push notification when user reaches 100% of their monthly budget
  ///
  /// In en, this message translates to:
  /// **'You have spent your entire monthly budget.'**
  String get notificationBudgetFullBody;

  /// Title for the push notification when a recurring transaction is processed
  ///
  /// In en, this message translates to:
  /// **'Recurring Transaction Processed 🔁'**
  String get notificationRecurringTitle;

  /// No description provided for @notificationRecurringBody.
  ///
  /// In en, this message translates to:
  /// **'{storeName} — {amount} ({category})'**
  String notificationRecurringBody(Object storeName, Object amount, Object category);

  /// Title for the push notification when user reaches their budget alert threshold (e.g. 80%)
  ///
  /// In en, this message translates to:
  /// **'Budget Alert ⚠️'**
  String get notificationBudgetAlertTitle;

  /// No description provided for @notificationBudgetAlertBody.
  ///
  /// In en, this message translates to:
  /// **'%{value} of your budget has been spent.'**
  String notificationBudgetAlertBody(Object value);

  /// Snackbar message when monthly budget is removed
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get budgetRemoved;

  /// Button text to remove monthly budget
  ///
  /// In en, this message translates to:
  /// **'Remove Budget'**
  String get removeBudget;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
