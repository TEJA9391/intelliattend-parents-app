import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

class ChildSwitcherBar extends StatelessWidget {
  const ChildSwitcherBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final children = controller.children;
    final activeId = controller.activeChildId;

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: children.map((ChildProfile child) {
          final isSelected = child.id == activeId;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.switchChild(child.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppTheme.surface(context),
                      child: Text(
                        child.name.isNotEmpty ? child.name[0] : 'S',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.text(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  child.name.split(' ').first,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.text(context),
                                  ),
                                ),
                              ),
                              if (controller.isChildIdOnBus(child.id)) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.directions_bus_rounded,
                                  size: 13,
                                  color: Color(0xFFFBBF24),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            child.rollNumber,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.textSecondary(context),
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
        }).toList(),
      ),
    );
  }
}
