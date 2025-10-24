import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String course;

  @HiveField(4)
  String year;

  @HiveField(5)
  bool isOfflineUser;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? profileImageUrl;

  @HiveField(8)
  String? university;

  @HiveField(9)
  Map<String, dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.course,
    required this.year,
    required this.isOfflineUser,
    required this.createdAt,
    this.profileImageUrl,
    this.university,
    this.preferences,
  });

  factory UserProfile.offline({
    required String name,
    required String course,
    required String year,
  }) {
    return UserProfile(
      id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: 'offline@uniflow.local',
      course: course,
      year: year,
      isOfflineUser: true,
      createdAt: DateTime.now(),
    );
  }

  factory UserProfile.fromGoogle({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      course: 'Not specified',
      year: 'Not specified',
      isOfflineUser: false,
      createdAt: DateTime.now(),
      profileImageUrl: profileImageUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      course: json['course'] as String,
      year: json['year'] as String,
      isOfflineUser: json['isOfflineUser'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
      university: json['university'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'course': course,
      'year': year,
      'isOfflineUser': isOfflineUser,
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'university': university,
      'preferences': preferences,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? course,
    String? year,
    bool? isOfflineUser,
    DateTime? createdAt,
    String? profileImageUrl,
    String? university,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      course: course ?? this.course,
      year: year ?? this.year,
      isOfflineUser: isOfflineUser ?? this.isOfflineUser,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
      preferences: preferences ?? this.preferences,
    );
  }

  String get displayName => name.isNotEmpty ? name : 'Student';
  String get displayCourse => course.isNotEmpty ? course : 'Course not specified';
  String get displayYear => year.isNotEmpty ? year : 'Year not specified';
  
  bool get isComplete => 
      name.isNotEmpty && 
      course.isNotEmpty && 
      year.isNotEmpty && 
      course != 'Not specified' && 
      year != 'Not specified';
}

