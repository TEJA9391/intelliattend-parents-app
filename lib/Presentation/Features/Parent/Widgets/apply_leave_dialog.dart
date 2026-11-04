import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';

class ApplyLeaveBottomSheet extends StatefulWidget {
  const ApplyLeaveBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final controller = Provider.of<ParentController>(context, listen: false);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: controller,
        child: const ApplyLeaveBottomSheet(),
      ),
    );
  }

  @override
  State<ApplyLeaveBottomSheet> createState() => _ApplyLeaveBottomSheetState();
}

class _ApplyLeaveBottomSheetState extends State<ApplyLeaveBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedLeaveType = 'Medical Leave';
  final List<String> _leaveTypes = [
    'Medical Leave',
    'Academic On-Duty (OD)',
    'Family Event / Function',
    'Special Leave',
    'Emergency Leave',
  ];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    HapticFeedback.mediumImpact();

    final reasonText = _reasonController.text.trim();
    final finalReason = reasonText.isNotEmpty
        ? reasonText
        : 'Application for $_selectedLeaveType submitted by parent.';

    final controller = context.read<ParentController>();
    controller.submitLeaveRequest(
      leaveType: _selectedLeaveType,
      startDate: _startDate,
      endDate: _endDate,
      reason: finalReason,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Leave application submitted to Class Advisor.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF0F766E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Apply for Student Leave',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Leave Type Dropdown
              Text(
                'Leave Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLeaveType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    dropdownColor: AppTheme.card(context),
                    items: _leaveTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLeaveType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickDate(isStart: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0F766E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(_startDate),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.text(context)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickDate(isStart: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF0F766E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(_endDate),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.text(context)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reason
              Text(
                'Reason / Explanation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                validator: (val) => null,
                decoration: InputDecoration(
                  hintText: 'Provide details (e.g., medical reasons, family travel, doctor consultation)...',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                  filled: true,
                  fillColor: AppTheme.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Application',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
