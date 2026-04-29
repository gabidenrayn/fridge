import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/account_model.dart';
import '../../models/family_request_model.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

class FamilyRequestScreen extends StatefulWidget {
  const FamilyRequestScreen({super.key});

  @override
  State<FamilyRequestScreen> createState() => _FamilyRequestScreenState();
}

class _FamilyRequestScreenState extends State<FamilyRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<AccountModel> _searchResults = [];
  List<FamilyRequestModel> _myRequests = [];
  bool _showSearch = true;

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userModel != null) {
      try {
        final requests = await context.read<AuthService>()
            .getUserRequests(authProvider.userModel!.id);
        setState(() {
          _myRequests = requests;
        });
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _searchFamilies(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await context.read<AuthService>()
          .searchFamilyAccounts(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching families: $e')),
        );
      }
    }
  }

  Future<void> _sendRequest(AccountModel family) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AuthService>().sendFamilyRequest(
            family.id,
            user.id,
            user.name,
            user.email,
            message: _messageController.text.trim().isEmpty 
                ? null 
                : _messageController.text.trim(),
          );

      setState(() {
        _isLoading = false;
        _searchController.clear();
        _messageController.clear();
        _searchResults.clear();
        _showSearch = false;
      });

      await _loadMyRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Join Family',
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          // Toggle buttons
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearch = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showSearch 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Search',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          color: _showSearch 
                              ? Colors.white 
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearch = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showSearch 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'My Requests',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          color: !_showSearch 
                              ? Colors.white 
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _showSearch ? _buildSearchView() : _buildRequestsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search family name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchFamilies,
          ),
          const SizedBox(height: 16),

          // Message field
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Optional message to family owner...',
              prefixIcon: const Icon(Icons.message),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Search results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final family = _searchResults[index];
                          return _FamilyCard(
                            family: family,
                            onSendRequest: () => _sendRequest(family),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _myRequests.isEmpty
          ? _buildNoRequestsState()
          : ListView.builder(
              itemCount: _myRequests.length,
              itemBuilder: (context, index) {
                final request = _myRequests[index];
                return _RequestCard(request: request);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for families to join',
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a family name in the search field above',
            style: GoogleFonts.nunito(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.send,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests sent yet',
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for families and send join requests',
            style: GoogleFonts.nunito(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final AccountModel family;
  final VoidCallback onSendRequest;

  const _FamilyCard({
    required this.family,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name,
                        style: GoogleFonts.exo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Family Account',
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Send Request',
                  style: GoogleFonts.exo2(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FamilyRequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case FamilyRequestStatus.pending:
        statusText = 'Pending';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case FamilyRequestStatus.accepted:
        statusText = 'Accepted';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case FamilyRequestStatus.rejected:
        statusText = 'Rejected';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request to join family',
                        style: GoogleFonts.exo2(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.exo2(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 8),
              Text(
                'Message: ${request.message}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
