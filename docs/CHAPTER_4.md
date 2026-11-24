# CHAPTER 4
## RESULTS AND TESTING

### System Features

#### Feature 1: User Registration and Authentication
**Description:**
Allows students, teachers, property custodians, and administrators to register using their School ID, full name, and email address. The system validates inputs, requires email verification, and assigns the appropriate user role.
*Screenshot: (See Appendix A â€“ Registration Screen)*

#### Feature 2: Login
**Description:**
Allows secure access to the application using registered credentials. After successful authentication, users are redirected automatically to their assigned role dashboard.
*Screenshot: (See Appendix A â€“ Login Screen)*

#### Feature 3: Role-Based Dashboards
**Description:**
Displays customized home screens based on the user's role. Borrowers can see available items and active borrowings; Custodians can monitor stock and pending returns; Administrators can view system stats, sections, and activity logs.
*Screenshot: (See Appendix A â€“ Dashboard Screen)*

#### Feature 4: Learning Resources Inventory Management
**Description:**
Allows property custodians to view, add, edit, and categorize school equipment, textbooks, science kits, and TVL tools. Users can search by name or code and filter by category or availability.
*Screenshot: (See Appendix A â€“ Resources Screen)*

#### Feature 5: QR Code Scanning and Automated Borrowing
**Description:**
Enables borrowers to scan an equipment QR code using their phone camera to view item details instantly and submit a borrow request within allowable section limits.
*Screenshot: (See Appendix A â€“ QR Scanner Screen)*

#### Feature 6: Return Verification with Photo Proof
**Description:**
Requires borrowers to take and upload a photo of the returned item. Property Custodians inspect the photo to verify item condition (Good Condition, or requiring Payment, Repair, or Replacement).
*Screenshot: (See Appendix A â€“ Return Verification Screen)*

#### Feature 7: Section and Borrowing Limit Management
**Description:**
Allows administrators to create grade levels and sections, assign teachers, and enforce section borrowing limits to prevent resource hoarding.
*Screenshot: (See Appendix A â€“ Section Management Screen)*

#### Feature 8: Reports and System Logs
**Description:**
Provides summary reports on inventory status, active borrowings, overdue items, and system audit logs for administrative monitoring.
*Screenshot: (See Appendix A â€“ Reports Screen)*

---

### Functional Testing

The following test cases were executed to verify system functionality:

| Test Case | Expected Result | Status |
| :--- | :--- | :--- |
| Register User | Account created with email verification sent | Passed |
| User Login | User authenticated and routed to correct role dashboard | Passed |
| Browse & Search Items | List of items filtered and displayed with available quantities | Passed |
| QR Code Scan | Camera recognizes code and displays item details | Passed |
| Borrow Resource | Item checked out and section borrowing limit updated | Passed |
| Upload Return Photo | Photo uploaded and return request marked as pending review | Passed |
| Verify Return Condition | Custodian inspects photo, sets condition status, and updates stock | Passed |
| Set Section Limits | Administrator sets limit and system blocks requests exceeding cap | Passed |
| View System Reports | Inventory summaries and activity logs generated correctly | Passed |
| User Logout | User session ended and returned to login screen | Passed |

---

### Evaluation

#### Strengths
â€¢ Clean, simple, and easy-to-navigate user interface.
â€¢ Fast borrowing process using camera QR code scanning.
â€¢ Better accountability through photo proof verification during returns.
â€¢ Section borrowing limits ensure fair sharing of equipment across classes.
â€¢ Real-time data updates and secure cloud storage using Google Firebase.

#### Weaknesses
â€¢ Internet dependent (requires an active connection to sync with Firebase).
â€¢ Limited platform support (Android mobile devices only).
â€¢ Requires an operational device camera for QR scanning and photo proof.
