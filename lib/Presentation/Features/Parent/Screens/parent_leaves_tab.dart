import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/child_switcher_bar.dart';
import '../Widgets/apply_leave_dialog.dart';

class ParentLeavesTab extends StatefulWidget {
  const ParentLeavesTab({super.key});

  @override
  State<ParentLeavesTab> createState() => _ParentLeavesTabState();
}

class _ParentLeavesTabState extends State<ParentLeavesTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final allLeaves = controller.activeChildLeaveRequests;

    final filteredLeaves = allLeaves.where((leave) {
      if (_selectedFilter == 'Pending') return leave.status == LeaveStatus.pending;
      if (_selectedFilter == 'Approved') return leave.status == LeaveStatus.approved;
      if (_selectedFilter == 'Rejected') return leave.status == LeaveStatus.rejected;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Leave Applications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ApplyLeaveBottomSheet.show(context),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const ChildSwitcherBar(),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Pending', 'Approved'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF2DD4BF),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2DD4BF) : AppTheme.textSecondary(context),
                    ),
                    backgroundColor: AppTheme.surface(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _buildLeavesView(context, filteredLeaves),
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesView(BuildContext context, List<LeaveRequest> leaves) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textSecondary(context)),
            const SizedBox(height: 12),
            Text(
              'No leave applications found.',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: leaves.length,
      itemBuilder: (ctx, index) {
        final leave = leaves[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leave.leaveType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: leave.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: leave.statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      leave.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: leave.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF2DD4BF)),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFormat.format(leave.startDate)} → ${dateFormat.format(leave.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Reason: ${leave.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              if (leave.reviewRemarks != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment_rounded, size: 14, color: Color(0xFF2DD4BF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          leave.reviewRemarks!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
