import 'package:flutter/material.dart';

/// Model representing a tab group.
class TabGroup {
  final String id;
  String name;
  Color color;
  List<String> tabIds;
  bool isCollapsed;

  TabGroup({
    required this.id,
    required this.name,
    required this.color,
    List<String>? tabIds,
    this.isCollapsed = false,
  }) : tabIds = tabIds ?? [];

  TabGroup copyWith({
    String? id,
    String? name,
    Color? color,
    List<String>? tabIds,
    bool? isCollapsed,
  }) {
    return TabGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tabIds: tabIds ?? List.from(this.tabIds),
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'tabIds': tabIds,
      'isCollapsed': isCollapsed,
    };
  }

  factory TabGroup.fromJson(Map<String, dynamic> json) {
    return TabGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      tabIds: (json['tabIds'] as List<dynamic>).cast<String>(),
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }

  static const List<Color> availableColors = [
    Color(0xFF4285F4), // Blue
    Color(0xFFEA4335), // Red
    Color(0xFFFBBC04), // Yellow
    Color(0xFF34A853), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
  ];
}
