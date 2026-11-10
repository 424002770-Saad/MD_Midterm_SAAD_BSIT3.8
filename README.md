# MD_Midterm_SAAD_BSIT3.8
# Community Learning Center Management System

**Name:** Moh Ben Amroden P. Saad
**Section:** BSIT 3.8

## Description
A console-based Dart application that registers learning resources and
participants, processes borrow/return transactions, and displays organized records.

## Implemented Features
- Menu-driven console app with loop until Exit
- Add learning resources, stored in a Map
- Register Students and Volunteers, stored in a List
- Borrow and return resources with fee computation
- Borrow limits per participant type
- Transaction log
- Input validation and try-catch error handling
- OOP: abstract class (Participant), subclasses (Student, Volunteer),
  polymorphism, encapsulation (private fields, getters/setters),
  mixin (Timestamped)

## Sample Test Scenarios
1. Add a resource, register a student, borrow for 3 days -> fee P15.00
2. Return the resource, then borrow for 10 days -> fee P60.00 (with surcharge)
3. Invalid input (letters as menu choice, unknown ID) -> error message, app keeps running

## How to Run
1. Open onlinegdb.com and select Dart.
2. Paste main.dart into the editor.
3. Click Run and follow the menu prompts in the console.
