import 'package:equatable/equatable.dart';

class AdminSession extends Equatable {
  final String id;
  final String email;
  final String displayName;

  const AdminSession({
    required this.id,
    required this.email,
    required this.displayName,
  });

  @override
  List<Object> get props => [id, email, displayName];
}
