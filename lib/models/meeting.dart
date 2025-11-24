// models/meeting.dart
class Meeting {
  final String id;
  final String title;
  final String description;
  final String agenda;
  final DateTime dateTime;
  final String location;
  final String onlineLink;
  final String createdBy;
  final List<String> attendees;
  final Map<String, String> rsvp; // userId -> 'attending'/'not_attending'

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.agenda,
    required this.dateTime,
    required this.location,
    this.onlineLink = '',
    required this.createdBy,
    this.attendees = const [],
    this.rsvp = const {},
  });

  factory Meeting.fromMap(Map<String, dynamic> map, String id) {
    return Meeting(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      agenda: map['agenda'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      location: map['location'] ?? '',
      onlineLink: map['onlineLink'] ?? '',
      createdBy: map['createdBy'] ?? '',
      attendees: List<String>.from(map['attendees'] ?? []),
      rsvp: Map<String, String>.from(map['rsvp'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'agenda': agenda,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'onlineLink': onlineLink,
      'createdBy': createdBy,
      'attendees': attendees,
      'rsvp': rsvp,
    };
  }
}
