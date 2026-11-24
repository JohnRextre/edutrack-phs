CHAPTER 1
Introduction
The project entitled â€œEduTrack PHS: School Learning Resources Inventory and Borrowing Management System with Return Verificationâ€ is a mobile application developed to help high schools organize educational resources, manage borrowing transactions, and regulate equipment distribution across different grade levels and sections.
In high schools, learning resources like textbooks, science laboratory kits, ICT devices, and TVL tools are shared among many students and classes. Managing these items through manual logbooks or paper slips often causes problems such as inaccurate records, missing items, uninspected returns, and one class borrowing too many items while others are left with none.
EduTrack PHS provides a modern and simple solution through mobile technology. The application allows users to check available resources, borrow items quickly using QR code scanning, and submit photo proof upon return for proper inspection. Additionally, it provides section management with customizable borrowing limits to ensure that school resources are distributed fairly among all grade levels and sections.

Project Objectives
General Objective
To develop a mobile application that manages school learning resource inventory, automates borrowing workflows, return condition verification, report generation, and supports fair resource distribution across high school sections.
Specific Objectives
1.	To design a simple and role-based interface for students, teachers, property custodians, and school administrators.
2.	To provide an organized inventory system for categorizing and monitoring school resources and equipment stock availability.
3.	To manage section allocations and borrowing limits restricting students to one active instance per resource to prevent resources hoarding.
4.	To automate the borrowing process through camera-based QR code scanning and due date tracking.
5.	To establish a return verification workflow that records return conditions and tracks required corrective actions (Good Condition or Payment, Repair, and Replacement) when items are damaged or lost.
6.	To secure user accounts and track transactions using role-based access, activity logs, and inventory reports.

Scope of the Project
The application covers the following features:
â€¢	User Registration and Login: Account creation with email verification, School ID, and user roles (Student, Teacher, Property Custodian, ICT Coordinator).
â€¢	Dashboard: Home screens showing available items, active borrowings, and notifications.
â€¢	Inventory Management: Adding, editing, searching, and categorizing school equipment, books, and tools.
â€¢	Section Management: Adding sections, assigning teachers, and setting borrowing limits per section.
â€¢	QR Code Scanning: Quick item scanning for borrowing and returning equipment using the phone camera.
â€¢	Borrowing System: Checking item availability, setting due dates, and monitoring active borrowed items.
â€¢	Return Verification: Uploading photos of returned items so custodians can check if an item is in good condition, damaged, or missing.
â€¢	Dispute and Appeal Handling: Submitting and reviewing appeals for damaged or flagged items.
â€¢	Reports and History: Viewing borrowing history, activity logs, and summary reports.

Limitations
â€¢	Internet connectivity is required to save and update data real-time in Cloud Firestore and Firebase Authentication services.
â€¢	Android Platform Only developed and tested for Android mobile devices.
â€¢	Camera Required a working phone camera for scanning QR codes and taking return photos.
â€¢	Limited to School Users the system is designed only manages school-owned inventory and does not track personal student or teacher property.
â€¢	Photo verification relies on manual custodian evaluation of uploaded images.
â€¢	No Cash Payments does not handle payments or fines inside the application.
