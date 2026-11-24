# CHAPTER 3
## SYSTEM DEVELOPMENT

### Tools and Technologies Used

#### Software
â€¢ **Flutter (Dart SDK)** â€“ cross-platform framework and programming language used to build the mobile application.
â€¢ **Visual Studio Code / Android Studio** â€“ primary Integrated Development Environments (IDEs) used for writing code, debugging, and building the application.
â€¢ **Google Firebase** â€“ cloud backend services:
  - *Firebase Authentication* â€“ for secure user sign-up, login, and email verification.
  - *Cloud Firestore* â€“ real-time cloud database for storing users, learning resources, sections, and borrowing records.
  - *Firebase Storage* â€“ cloud file storage for uploaded return photo proofs and profile images.
â€¢ **Mobile Scanner Package** â€“ Flutter camera library used for scanning equipment QR codes.
â€¢ **Git and GitHub** â€“ version control tools used for tracking code changes and project management.

#### Hardware
â€¢ **Laptop / Personal Computer** â€“ development workstation used for coding and system compilation.
â€¢ **Android Mobile Device (Smartphone with Camera)** â€“ physical test device used to test camera QR code scanning, photo uploads, and user interface responsiveness.
â€¢ **Android Emulator** â€“ virtual mobile device used for initial debugging and screen layout testing.

---

### Development Process

#### Requirements Gathering
System requirements were gathered by identifying common problems in high school resource management, such as manual logbook errors, delayed returns, uninspected equipment conditions, and uneven distribution of resources among classes. Functional requirements were established for four user roles: Students, Teachers, Property Custodians, and ICT Coordinators/Administrators.

#### Design
System diagrams and user interface wireframes were prepared to guide development. These included the System Flowchart, UML Use Case Diagram, and Entity Relationship Diagram (ERD). The user interface was designed with a focus on simplicity, role-based navigation, and clean layout for mobile screens.

#### Development
The application was programmed using Flutter and Dart, organized into models, services, screens, and reusable widgets. Key modules built include:
â€¢ User authentication with School ID and email verification.
â€¢ Learning resources inventory tracking (Textbooks, ICT equipment, Science kits, TVL tools).
â€¢ Section management with borrowing limits to prevent resource hoarding.
â€¢ Camera-based QR code scanning for fast borrowing and returns.
â€¢ Return verification workflow with photo proof upload and condition inspection (Good, Damaged, Missing).
â€¢ Activity logs and printable inventory summary reports.

Firebase services were integrated to provide real-time database updates and secure cloud storage.

#### Testing
The system was tested on both Android emulators and actual Android smartphones. Testing focused on verifying user login and role redirection, real-time stock updates in Firestore, camera performance during QR scanning, photo upload reliability during returns, and section limit enforcement. Bugs and user interface issues were identified and fixed to ensure stable system performance.
