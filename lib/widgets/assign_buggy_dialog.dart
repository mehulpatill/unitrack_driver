import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignBuggyDialog extends StatefulWidget {
  const AssignBuggyDialog({super.key});

  @override
  State<AssignBuggyDialog> createState() => _AssignBuggyDialogState();
}

class _AssignBuggyDialogState extends State<AssignBuggyDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  final TextEditingController _buggyController = TextEditingController();
  bool loading = false;

  Future<void> _assignBuggy() async {
    final buggyNumber = _buggyController.text.trim();
    if (buggyNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a buggy number")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // First, check if the current user already has a buggy assigned
      final existingBuggy = await _supabase
          .from('buggies')
          .select()
          .eq('assigned_driver', user!.id)
          .maybeSingle();

      if (existingBuggy != null) {
        // Update the existing buggy record with the new buggy number
        await _supabase
            .from('buggies')
            .update({
              'buggy_number': buggyNumber,
              'status': 'inactive',
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', existingBuggy['id']);

        print('Updated existing buggy record with new number: $buggyNumber');
      } else {
        // Check if the buggy number is already assigned to someone else
        final buggyWithNumber = await _supabase
            .from('buggies')
            .select()
            .eq('buggy_number', buggyNumber)
            .maybeSingle();

        if (buggyWithNumber != null) {
          throw Exception(
            "This buggy number is already assigned to another driver.",
          );
        }

        // Create new buggy record
        await _supabase.from('buggies').insert({
          'buggy_number': buggyNumber,
          'assigned_driver': user!.id,
          'status': 'inactive',
          'last_updated': DateTime.now().toIso8601String(),
        });

        print('Created new buggy record: $buggyNumber');
      }

      print('Buggy $buggyNumber assigned successfully to driver ${user!.id}');

      if (mounted) {
        Navigator.pop(context, buggyNumber);
      }
    } catch (e, stackTrace) {
      print('Buggy assignment error: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to assign buggy: ${e.toString()}")),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assign Buggy",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enter your buggy number to start service",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _buggyController,
              decoration: InputDecoration(
                labelText: "Buggy Number",
                hintText: "e.g., BUGGY-001",
                prefixIcon: Icon(
                  Icons.confirmation_number,
                  color: Colors.blue.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: loading ? null : _assignBuggy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Assigning...",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Assign Buggy",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
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
}
