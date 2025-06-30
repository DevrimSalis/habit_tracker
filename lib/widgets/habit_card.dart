import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCompletedToday = habit.isCompletedToday();
    int currentStreak = habit.getCurrentStreak();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCompletedToday
              ? LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım: İsim ve silme butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompletedToday ? Colors.green.shade800 : Colors.grey.shade800,
                        decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Sil'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  ),
                ],
              ),
              
              // Açıklama
              if (habit.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  habit.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Alt kısım: Streak ve tamamlama butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Streak bilgisi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentStreak > 0 ? Colors.orange.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: currentStreak > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak gün',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentStreak > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tamamlama butonu
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isCompletedToday ? Colors.green : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isCompletedToday ? Icons.check : Icons.radio_button_unchecked,
                        color: isCompletedToday ? Colors.white : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Son 7 günün görsel gösterimi
              const SizedBox(height: 12),
              _buildWeeklyProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    List<Widget> dayWidgets = [];
    DateTime today = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      DateTime date = today.subtract(Duration(days: i));
      bool isCompleted = habit.completedDates.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day
      );
      
      dayWidgets.add(
        Container(
          width: 28,
          height: 28,
          margin: EdgeInsets.only(right: i > 0 ? 4 : 0),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade400 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son 7 gün',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: dayWidgets),
      ],
    );
  }
}