# CHAPTER 2
## SYSTEM ANALYSIS AND DESIGN

### System Description
The application allows school constituents to register, log in, manage school learning resources, and track borrowing and return transactions using a mobile device. Borrowers (students and teachers) can search for available equipment, scan QR codes to borrow items quickly, track their due dates, and upload photo proof when returning items. Property Custodians can add and update inventory items, monitor stock levels, inspect uploaded return photos, and record item conditions (Good Condition or requiring Payment, Repair, or Replacement). Administrators and ICT Coordinators have additional privileges to manage user accounts, organize sections, set section borrowing limits, and view activity logs and inventory reports. All data is stored securely in a cloud database (Google Firebase) and synchronized across devices when an internet connection is available.

---

### System Flow
The overall system flow of the application is as follows:

```text
Start â†’ Login â†’ Role Dashboard â†’ Select Feature â†’ Process Data â†’ Save / Update Database â†’ View Results â†’ Logout
```

<!-- DITO ILALAGAY ANG IMAGE NG SYSTEM FLOWCHART -->
> **[ILAGAY DITO ANG IMAGE: Figure 2.1 â€“ System Flowchart of EduTrack PHS]**
*(I-paste dito ang iyong EduTrack PHS â€” System Flowchart image)*

**Detailed flow:** Upon launching the application, the user is presented with a homepage and login screen. After successful authentication and account verification, the user is directed to the main dashboard corresponding to their role (Student, Teacher, Property Custodian, or Administrator). From the dashboard, users can select features such as browsing resources, scanning a QR code to borrow, viewing active due dates, or submitting return photo proof. Property Custodians inspect returns and update stock, while Administrators manage sections and view logs. After performing the desired action and saving data to Firebase, the user can view results, check notifications, and eventually log out of the system.

---

### Use Case Diagram
The system involves the following actors and functions:

<!-- DITO ILALAGAY ANG IMAGE NG USE CASE DIAGRAM -->
> **[ILAGAY DITO ANG IMAGE: Figure 2.2 â€“ Use Case Diagram of EduTrack PHS]**
*(I-paste dito ang iyong Use Case Diagram na may stickman actors)*

#### Actors:
â€¢ **Borrower (Student / Teacher)** â€“ searches resources, scans QR codes to borrow, tracks due dates, and submits return photo proof.
â€¢ **Property Custodian** â€“ manages inventory stock, inspects returned items through uploaded photos, and records item conditions and corrective actions.
â€¢ **Administrator (ICT Coordinator)** â€“ manages user accounts, creates sections, sets section borrowing limits, and views system logs and audit reports.

#### Functions / Use Cases:
â€¢ **Register & Login** â€“ create an account with email verification, School ID, and log in securely.
â€¢ **Manage Profile & Sections** â€“ update personal profile and view assigned grade levels and sections.
â€¢ **Browse & Search Resources** â€“ view learning equipment by category and check available quantities.
â€¢ **Scan QR Code** â€“ use the phone camera to scan item tags for fast borrowing and return lookup.
â€¢ **Borrow Equipment** â€“ request and check out items within allowable section limits.
â€¢ **Return Item with Photo Proof** â€“ submit return requests with an attached photo showing item condition.
â€¢ **Verify Returns** â€“ inspect photo proof and evaluate item status (Good Condition, Payment, Repair, or Replacement).
â€¢ **Handle Appeals & Disputes** â€“ submit and review explanations for flagged or disputed items.
â€¢ **Manage Inventory** â€“ add, edit, categorize, and update stock counts of school resources.
â€¢ **Manage Sections & Limits** â€“ create sections and set maximum borrowing limits to share resources fairly.
â€¢ **View Reports & Logs** â€“ generate inventory summaries and track account activity logs.

---

### Database Design
The application uses Firebase Cloud Firestore for cloud data storage. The main entities and their relationships are described below.

#### ERD Overview
**Entities:** Users, Learning Resources (Inventory Items), Sections, and Borrow Transactions.

<!-- DITO ILALAGAY ANG IMAGE NG ERD -->
> **[ILAGAY DITO ANG IMAGE: Figure 2.3 â€“ Entity Relationship Diagram (ERD) of EduTrack PHS]**
*(I-paste dito ang iyong ERD diagram na may Sections, Users, Resources, at Borrow_Transactions)*

**Relationships:**
â€¢ Each **Section** has a grade level, a defined borrowing limit, and multiple assigned **Users** (students and teachers).
â€¢ A **User** belongs to a Section and can initiate multiple **Borrow Transactions**.
â€¢ Each **Borrow Transaction** links one **User** to a specific **Learning Resource**, recording borrow dates, due dates, return photo proof, and condition status.
â€¢ A **Property Custodian** manages multiple **Learning Resources** and reviews **Borrow Transactions** for return approval.

---

### Database Tables

#### Table: Users
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | Unique User ID (Firebase Auth UID) |
| `fullName` | Text | Full name of the user |
| `email` | Text | Registered email address |
| `schoolId` | String | Official school identification number |
| `role` | Text | User role (student / teacher / property custodian / ict coordinator) |
| `departmentOrSection`| Text | Assigned section or department name |
| `sectionId` | String | Reference ID of the assigned section |
| `status` | Text | Account status (Active / Inactive) |
| `createdAt` | Timestamp | Account creation date and time |

#### Table: Learning Resources (Inventory Items)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique resource document ID |
| `itemName` | Text | Name of the learning resource or equipment |
| `itemCode` | String | Unique barcode / QR code identifier |
| `mainCategory` | Text | Category (Textbooks, ICT Devices, Science Kits, TVL Tools) |
| `totalQuantity` | Integer | Total registered quantity of the item |
| `availableQuantity` | Integer | Current quantity available for borrowing |
| `storageLocation` | Text | Physical room or cabinet where the item is stored |
| `description` | Text | Detailed specifications and item description |

#### Table: Sections
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique section ID |
| `name` | Text | Name of the section (e.g., Diamond, STEM-A) |
| `gradeLevel` | Text | Grade level (e.g., Grade 7, Grade 11) |
| `maxActiveBorrowQuantity` | Integer | Maximum items the section can borrow at one time |
| `currentActiveBorrowQuantity` | Integer | Number of items currently borrowed by the section |
| `isActive` | Boolean | Status indicating if the section is currently active |

#### Table: Borrow Transactions
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique transaction ID |
| `resourceId` | String | Reference ID of the borrowed resource |
| `resourceName` | Text | Name of the borrowed resource |
| `userId` | String | Reference ID of the borrower |
| `userName` | Text | Name of the borrower |
| `userRole` | Text | Role of the borrower (student / teacher) |
| `borrowDate` | Timestamp | Date and time the item was borrowed |
| `expectedReturnDate` | Timestamp | Scheduled due date for return |
| `actualReturnDate` | Timestamp | Date and time the item was returned |
| `status` | Text | Transaction status (pending, borrowed, returned, return_rejected) |
| `returnType` | Text | Return condition type (good_condition, payment_proof, repaired_proof, replacement_proof) |
| `returnProofImage` | Text | Storage URL of the uploaded return photo proof |
| `itemConditionNotes`| Text | Notes on the condition of the returned item |

---

### User Interface Design
The application features a clean, simple, and modern user interface. The main screens include:

â€¢ **Homepage & Splash Screen** â€“ displays the EduTrack PHS title, system overview, and access portal button.
â€¢ **Login & Registration Screens** â€“ email and password authentication with School ID and email verification.
â€¢ **Role-Based Dashboards** â€“ dedicated home screens showing statistics, active borrowings, and notifications for each user role.
â€¢ **Resource Catalog Screen** â€“ displays available items with category filtering, search bar, and live quantity counts.
â€¢ **QR Camera Scanner Screen** â€“ built-in scanner to identify equipment instantly for quick borrowing and returns.
â€¢ **My Borrowings & Return Screen** â€“ displays active borrowed items, due dates, and a form to upload photo proof upon return.
â€¢ **Custodian Return Verification Screen** â€“ screen for property custodians to inspect return photos and evaluate item condition.
â€¢ **Section Management Screen** â€“ administrative screen for adding sections, assigning teachers, and setting borrowing limits.
â€¢ **Reports & System Logs Screen** â€“ screens for viewing transaction history, user activity logs, and printable inventory reports.

*(Note: Actual screenshots and mockups are included in Appendix A.)*
