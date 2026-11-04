import 'package:flutter/material.dart';
import '../../../../Theme/app_theme.dart';
import '../Models/parent_models.dart';

class StudentAcademicCard extends StatelessWidget {
  final ChildProfile child;
  final StudentBusTransit? transit;
  final VoidCallback? onRfidBusTap;

  const StudentAcademicCard({
    super.key,
    required this.child,
    this.transit,
    this.onRfidBusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: Color(0xFF2DD4BF),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Enrolled Student',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'AY ${child.academicYear}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            child.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${child.program} • ${child.semester}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_circle_outlined,
                  size: 20,
                  color: Color(0xFF2DD4BF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Advisor: ${child.mentorName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Roll No: ${child.rollNumber} • Blood Group: ${child.bloodGroup}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onRfidBusTap != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRfidBusTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live Location',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFF2DD4BF),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
