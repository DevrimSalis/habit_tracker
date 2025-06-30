class Habit {
  int? id;
  String name;
  String description;
  DateTime createdDate;
  List<DateTime> completedDates;

  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.createdDate,
    required this.completedDates,
  });

  // Veritabanı için map dönüşümü
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_date': createdDate.toIso8601String(),
      'completed_dates': completedDates.map((date) => date.toIso8601String()).join(','),
    };
  }

  // Map'ten Habit oluşturma
  factory Habit.fromMap(Map<String, dynamic> map) {
    List<DateTime> dates = [];
    if (map['completed_dates'].isNotEmpty) {
      dates = map['completed_dates']
          .split(',')
          .map<DateTime>((dateStr) => DateTime.parse(dateStr))
          .toList();
    }

    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdDate: DateTime.parse(map['created_date']),
      completedDates: dates,
    );
  }

  // Bugün tamamlandı mı?
  bool isCompletedToday() {
    DateTime today = DateTime.now();
    return completedDates.any((date) => 
      date.year == today.year && 
      date.month == today.month && 
      date.day == today.day
    );
  }

  // Streak hesaplama
  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;
    
    completedDates.sort((a, b) => b.compareTo(a)); // Tersten sırala
    DateTime today = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < completedDates.length; i++) {
      DateTime expectedDate = today.subtract(Duration(days: i));
      bool foundDate = completedDates.any((date) =>
        date.year == expectedDate.year &&
        date.month == expectedDate.month &&
        date.day == expectedDate.day
      );
      
      if (foundDate) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}