import 'package:flutter/material.dart';

enum UserRole {
  student('Student', Icons.school_outlined),
  teacher('Teacher', Icons.person_outlined),
  custodian('Property Custodian', Icons.verified_user_outlined),
  ictCoordinator('ICT Coordinator', Icons.admin_panel_settings_outlined);

  const UserRole(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum AccountStatus {
  active('Active', Colors.green),
  inactive('Inactive', Colors.grey),
  suspended('Suspended', Colors.red);

  const AccountStatus(this.label, this.color);
  final String label;
  final Color color;
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.department,
    this.avatarColor,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final AccountStatus status;
  final String department;
  final Color? avatarColor;
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;
  AccountStatus? _statusFilter;

  // Sample data - in real app, this would come from a database/service
  final List<UserAccount> _allUsers = [
    UserAccount(
      id: 'USR-001',
      fullName: 'John Rexter',
      email: 'john.rexter@school.edu',
      role: UserRole.student,
      status: AccountStatus.active,
      department: 'Grade 11 STEM',
      avatarColor: Colors.blue,
    ),
    UserAccount(
      id: 'USR-002',
      fullName: 'Maria Santos',
      email: 'maria.santos@school.edu',
      role: UserRole.teacher,
      status: AccountStatus.active,
      department: 'Science Dept',
      avatarColor: Colors.purple,
    ),
    UserAccount(
      id: 'USR-003',
      fullName: 'Pedro Reyes',
      email: 'pedro.reyes@school.edu',
      role: UserRole.custodian,
      status: AccountStatus.active,
      department: 'Property Management',
      avatarColor: Colors.orange,
    ),
    UserAccount(
      id: 'USR-004',
      fullName: 'Ana Garcia',
      email: 'ana.garcia@school.edu',
      role: UserRole.student,
      status: AccountStatus.inactive,
      department: 'Grade 12 ABM',
      avatarColor: Colors.teal,
    ),
    UserAccount(
      id: 'USR-005',
      fullName: 'Carlos Mendoza',
      email: 'carlos.mendoza@school.edu',
      role: UserRole.ictCoordinator,
      status: AccountStatus.active,
      department: 'ICT Department',
      avatarColor: Colors.indigo,
    ),
  ];

  List<UserAccount> get _filteredUsers {
    return _allUsers.where((user) {
      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        final matchesSearch =
            user.fullName.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.id.toLowerCase().contains(searchQuery);
        if (!matchesSearch) return false;
      }

      // Role filter
      if (_selectedRoleFilter != null) {
        if (user.role != _selectedRoleFilter) return false;
      }

      // Status filter
      if (_statusFilter != null) {
        if (user.status != _statusFilter) return false;
      }

      return true;
    }).toList();
  }

  void _showAddUserModal() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final departmentController = TextEditingController();
    UserRole selectedRole = UserRole.student;
    AccountStatus selectedStatus = AccountStatus.active;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address / User ID *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'System Role *',
                          border: OutlineInputBorder(),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Icon(role.icon, size: 20),
                                const SizedBox(width: 8),
                                Text(role.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Department
                      TextField(
                        controller: departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Grade/Section or Department (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<AccountStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Account Status',
                          border: OutlineInputBorder(),
                        ),
                        items: AccountStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty ||
                              emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in all required fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'User "${nameController.text.trim()}" created successfully!',
                              ),
                            ),
                          );
                        },
                        child: const Text('Create User'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(UserAccount user) {
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final departmentController = TextEditingController(text: user.department);
    UserRole selectedRole = user.role;
    AccountStatus selectedStatus = user.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User "${nameController.text}" updated.'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete the account for "${user.fullName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account for "${user.fullName}" deleted.'),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(UserAccount user) {
    final newStatus = user.status == AccountStatus.active
        ? AccountStatus.inactive
        : AccountStatus.active;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus == AccountStatus.active ? 'Reactivate' : 'Deactivate',
        ),
        content: Text(
          '${newStatus == AccountStatus.active ? 'Reactivate' : 'Deactivate'} account for "${user.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account ${newStatus == AccountStatus.active ? 'reactivated' : 'deactivated'} for "${user.fullName}".',
                  ),
                ),
              );
            },
            child: Text(
              newStatus == AccountStatus.active ? 'Reactivate' : 'Deactivate',
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name, email, or ID...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Role Filters
                  FilterChip(
                    label: const Text('All Users'),
                    selected: _selectedRoleFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Students'),
                    selected: _selectedRoleFilter == UserRole.student,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.student
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Teachers'),
                    selected: _selectedRoleFilter == UserRole.teacher,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.teacher
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Custodians'),
                    selected: _selectedRoleFilter == UserRole.custodian,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.custodian
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ICT Coordinators'),
                    selected: _selectedRoleFilter == UserRole.ictCoordinator,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.ictCoordinator
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Status Filter
                  FilterChip(
                    label: Text(
                      _statusFilter == null
                          ? 'All Status'
                          : _statusFilter!.label,
                    ),
                    selected: _statusFilter != null,
                    onSelected: (selected) {
                      setState(() {
                        _statusFilter = selected ? AccountStatus.active : null;
                      });
                    },
                    selectedColor:
                        _statusFilter?.color.withValues(alpha: 0.2) ??
                        Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: _statusFilter?.color ?? Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No users found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UserCard(
                          user: user,
                          onEdit: () => _showEditUserDialog(user),
                          onToggleStatus: () => _toggleUserStatus(user),
                          onDelete: () => _showDeleteConfirmation(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserModal,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final UserAccount user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor:
                    user.avatarColor ??
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _getInitials(user.fullName),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          user.role.icon,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${user.role.label} • ${user.department}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: user.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.status.label,
                  style: TextStyle(
                    color: user.status.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Action Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onToggleStatus();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit User Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(Icons.toggle_on, size: 20),
                        SizedBox(width: 8),
                        Text('Toggle Status'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}

int min(int a, int b) => a < b ? a : b;
