import 'dart:io';

// ======================= EXCEPTION =======================
class CenterException implements Exception {
  final String message;
  CenterException(this.message);
  @override
  String toString() => message;
}

// ======================= MIXIN =======================
// Reusable timestamp behavior for any record
mixin Timestamped {
  final DateTime _createdAt = DateTime.now();

  String get createdAtText {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_createdAt.year}-${two(_createdAt.month)}-${two(_createdAt.day)} '
        '${two(_createdAt.hour)}:${two(_createdAt.minute)}';
  }
}

// ======================= ABSTRACT PARENT =======================
abstract class Participant with Timestamped {
  final String _id;
  String _name;
  final List<String> _borrowedIds = [];

  Participant(this._id, this._name);

  // Encapsulation: controlled access via getters/setters
  String get id => _id;
  String get name => _name;
  set name(String value) {
    if (value.trim().isEmpty) {
      throw CenterException('Name cannot be empty.');
    }
    _name = value.trim();
  }

  List<String> get borrowedIds => List.unmodifiable(_borrowedIds);

  // Each subclass provides its own implementation (polymorphism)
  String get role;
  int get borrowLimit;
  double get dailyRate;
  String describe();

  bool canBorrow() => _borrowedIds.length < borrowLimit;

  void addBorrowed(String resourceId) => _borrowedIds.add(resourceId);
  void removeBorrowed(String resourceId) => _borrowedIds.remove(resourceId);
}

// ======================= SUBCLASSES =======================
class Student extends Participant {
  final String _gradeLevel;

  Student(String id, String name, this._gradeLevel) : super(id, name);

  @override
  String get role => 'Student';

  @override
  int get borrowLimit => 3;

  @override
  double get dailyRate => 5.0;

  @override
  String describe() {
    return '[$id] $name | $role (Grade/Year: $_gradeLevel) | '
        'Limit: $borrowLimit | Rate: P${dailyRate.toStringAsFixed(2)}/day | '
        'Borrowed: ${borrowedIds.length} | Registered: $createdAtText';
  }
}

class Volunteer extends Participant {
  final String _assignedTask;

  Volunteer(String id, String name, this._assignedTask) : super(id, name);

  @override
  String get role => 'Volunteer';

  @override
  int get borrowLimit => 5;

  @override
  double get dailyRate => 2.0;

  @override
  String describe() {
    return '[$id] $name | $role (Task: $_assignedTask) | '
        'Limit: $borrowLimit | Rate: P${dailyRate.toStringAsFixed(2)}/day | '
        'Borrowed: ${borrowedIds.length} | Registered: $createdAtText';
  }
}

// ======================= LEARNING RESOURCE =======================
class LearningResource with Timestamped {
  final String _id;
  final String _title;
  final String _category;
  bool _isAvailable = true;
  String? _borrowedBy;

  LearningResource(this._id, this._title, this._category);

  String get id => _id;
  String get title => _title;
  String get category => _category;
  bool get isAvailable => _isAvailable;
  String? get borrowedBy => _borrowedBy;

  void borrow(String participantId) {
    if (!_isAvailable) {
      throw CenterException('Resource "$_title" is already borrowed.');
    }
    _isAvailable = false;
    _borrowedBy = participantId;
  }

  void giveBack() {
    _isAvailable = true;
    _borrowedBy = null;
  }

  String describe() {
    String status = _isAvailable ? 'Available' : 'Borrowed by $_borrowedBy';
    return '[$_id] $_title | Category: $_category | $status | Added: $createdAtText';
  }
}

// ======================= USER-DEFINED FUNCTIONS =======================
// Function 1: computes borrowing fee (parameters + return value)
double computeFee(int days, double dailyRate) {
  double fee = days * dailyRate;
  if (days > 7) {
    fee += 10.0; // extended borrowing surcharge
  }
  return fee;
}

// Function 2: reads non-empty text input (parameters + return value)
String readText(String prompt) {
  while (true) {
    stdout.write(prompt);
    String? input = stdin.readLineSync();
    if (input == null) {
      throw CenterException('Input closed.');
    }
    if (input.trim().isNotEmpty) {
      return input.trim();
    }
    print('  ! Input cannot be empty. Please try again.');
  }
}

// Function 3: reads a whole number within a range
int readInt(String prompt, int min, int max) {
  while (true) {
    String text = readText(prompt);
    try {
      int value = int.parse(text);
      if (value < min || value > max) {
        print('  ! Please enter a number from $min to $max.');
      } else {
        return value;
      }
    } on FormatException {
      print('  ! "$text" is not a valid number.');
    }
  }
}

// ======================= CENTER MANAGER =======================
class CenterManager {
  final Map<String, LearningResource> _resources = {}; // Map
  final List<Participant> _participants = []; // List
  final List<String> _transactionLog = []; // List
  int _resourceCounter = 1;
  int _participantCounter = 1;

  void addResource(String title, String category) {
    String id = 'R${_resourceCounter.toString().padLeft(3, '0')}';
    _resourceCounter++;
    _resources[id] = LearningResource(id, title, category);
    print('\n  Resource added: [$id] $title');
  }

  void registerParticipant(Participant p) {
    _participants.add(p);
    print('\n  Participant registered: ${p.name} (${p.role}) with ID ${p.id}');
  }

  String nextParticipantId() {
    String id = 'P${_participantCounter.toString().padLeft(3, '0')}';
    _participantCounter++;
    return id;
  }

  Participant findParticipant(String id) {
    for (Participant p in _participants) {
      if (p.id == id.toUpperCase()) return p;
    }
    throw CenterException('Participant "$id" not found.');
  }

  LearningResource findResource(String id) {
    LearningResource? r = _resources[id.toUpperCase()];
    if (r == null) {
      throw CenterException('Resource "$id" not found.');
    }
    return r;
  }

  void borrowResource(String participantId, String resourceId, int days) {
    Participant p = findParticipant(participantId);
    LearningResource r = findResource(resourceId);

    if (!p.canBorrow()) {
      throw CenterException(
          '${p.name} reached the borrow limit of ${p.borrowLimit}.');
    }
    r.borrow(p.id);
    p.addBorrowed(r.id);

    double fee = computeFee(days, p.dailyRate);
    String record = '${p.name} borrowed "${r.title}" for $days day(s). '
        'Fee: P${fee.toStringAsFixed(2)}';
    _transactionLog.add(record);
    print('\n  Success! $record');
  }

  void returnResource(String resourceId) {
    LearningResource r = findResource(resourceId);
    if (r.isAvailable) {
      throw CenterException('Resource "${r.title}" is not currently borrowed.');
    }
    Participant p = findParticipant(r.borrowedBy!);
    p.removeBorrowed(r.id);
    r.giveBack();
    String record = '${p.name} returned "${r.title}".';
    _transactionLog.add(record);
    print('\n  Success! $record');
  }

  void viewResources() {
    print('\n===== LEARNING RESOURCES =====');
    if (_resources.isEmpty) {
      print('  No resources yet.');
      return;
    }
    for (LearningResource r in _resources.values) {
      print('  ${r.describe()}');
    }
  }

  // Polymorphism: each Participant subclass prints its own describe()
  void viewParticipants() {
    print('\n===== PARTICIPANTS =====');
    if (_participants.isEmpty) {
      print('  No participants yet.');
      return;
    }
    for (Participant p in _participants) {
      print('  ${p.describe()}');
    }
  }

  void viewTransactions() {
    print('\n===== TRANSACTION LOG =====');
    if (_transactionLog.isEmpty) {
      print('  No transactions yet.');
      return;
    }
    for (int i = 0; i < _transactionLog.length; i++) {
      print('  ${i + 1}. ${_transactionLog[i]}');
    }
  }
}

// ======================= MENU =======================
void showMenu() {
  print('\n=====================================');
  print('  COMMUNITY LEARNING CENTER SYSTEM');
  print('=====================================');
  print('  1. Add learning resource');
  print('  2. Register participant');
  print('  3. Borrow resource');
  print('  4. Return resource');
  print('  5. View resources');
  print('  6. View participants');
  print('  7. View transaction log');
  print('  8. Exit');
  print('-------------------------------------');
}

void main() {
  CenterManager center = CenterManager();
  bool running = true;

  while (running) {
    showMenu();
    stdout.write('Enter choice (1-8): ');
    String? raw = stdin.readLineSync();
    if (raw == null) break; // input closed

    int? choice = int.tryParse(raw.trim());

    try {
      switch (choice) {
        case 1:
          String title = readText('Resource title: ');
          String category = readText('Category (e.g., Book, Video, Module): ');
          center.addResource(title, category);
          break;

        case 2:
          String name = readText('Participant name: ');
          print('Type: 1 = Student, 2 = Volunteer');
          int type = readInt('Choose type: ', 1, 2);
          String id = center.nextParticipantId();
          if (type == 1) {
            String grade = readText('Grade/Year level: ');
            center.registerParticipant(Student(id, name, grade));
          } else {
            String task = readText('Assigned task: ');
            center.registerParticipant(Volunteer(id, name, task));
          }
          break;

        case 3:
          center.viewResources();
          center.viewParticipants();
          String pid = readText('\nParticipant ID (e.g., P001): ');
          String rid = readText('Resource ID (e.g., R001): ');
          int days = readInt('Number of days (1-30): ', 1, 30);
          center.borrowResource(pid, rid, days);
          break;

        case 4:
          center.viewResources();
          String rid = readText('\nResource ID to return: ');
          center.returnResource(rid);
          break;

        case 5:
          center.viewResources();
          break;

        case 6:
          center.viewParticipants();
          break;

        case 7:
          center.viewTransactions();
          break;

        case 8:
          print('\nThank you for using the system. Goodbye!');
          running = false;
          break;

        default:
          print('\n  ! Invalid choice. Please enter a number from 1 to 8.');
      }
    } on CenterException catch (e) {
      print('\n  Error: ${e.message}');
    } catch (e) {
      print('\n  Unexpected error: $e');
    }
  }
}