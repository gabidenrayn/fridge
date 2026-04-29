import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/family_request_model.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  bool _isLoading = false;
  List<FamilyRequestModel> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userModel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await context.read<AuthService>()
          .getPendingRequests(authProvider.userModel!.id);
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await context.read<AuthService>().acceptFamilyRequest(requestId);
      await _loadPendingRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await context.read<AuthService>().rejectFamilyRequest(requestId);
      await _loadPendingRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final account = authProvider.accountModel;

    if (account == null || account.type.name != 'family') {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Family Management',
            style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(
          child: Text('You need a family account to access this feature'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Family Management',
          style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      return _RequestCard(
                        request: request,
                        onAccept: () => _acceptRequest(request.id),
                        onReject: () => _rejectRequest(request.id),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people want to join your family,\nyou\'ll see their requests here',
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

class _RequestCard extends StatelessWidget {
  final FamilyRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: GoogleFonts.exo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.requesterEmail,
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${_formatDate(request.createdAt)}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message!,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.exo2(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.exo2(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
