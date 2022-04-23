import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() {
  runApp(const MaterialApp(
    home: BirthdaysPage(),
  ));
}

class BirthdaysPage extends StatefulWidget {
  const BirthdaysPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BirthdaysPageState();
}

class BirthdaysPageState extends State<BirthdaysPage> {
  bool _permissionDenied = false;

  DateTime now = DateTime.now();

  Future<DateTime?> getContactNextBirthday(Contact contact) async {
    var day = 0;
    var month = 0;

    for (Event e in contact.events) {
      if (e.label == EventLabel.birthday) {
        day = e.day;
        month = e.month;
      }
    }

    if (day == 0 || month == 0) {
      return null;
    }

    var nextDate = DateTime(now.year, month, day);

    if (nextDate.compareTo(now) < 0) {                  // if it's already passed this year, loop to next year
      nextDate = DateTime(now.year + 1, month, day);
    }

    return nextDate;
  }

  Row contactToRow(Contact c, DateTime birthday) {
    Row contactRow = Row(
      children: [
        SizedBox(
          width: 250,
          height: 50,
          child: Container(
            padding: const EdgeInsets.only(left: 30, top: 10, bottom: 10),
            alignment: Alignment.centerLeft,
            child: Text(c.displayName),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(right: 30, top: 10, bottom: 10),
          alignment: Alignment.centerLeft,
          child: Text(DateFormat('dd/MM/yyyy').format(birthday))
        ),
      ],
    );

    return contactRow;
  }

  Future<Map<Contact, DateTime>> getContactsAndBirthdays() async {
    // get all contacts, filter out those without birthdays and
    // sort in order of how soon they are

    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    }

    List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
    final Map<Contact, DateTime> birthdays = HashMap();

    for (Contact c in contacts) {
      var birthday = await getContactNextBirthday(c);

      if (birthday != null) {
        birthdays[c] = birthday;
      }
    }

    // sort birthdays
    var sortedKeys = Map.fromEntries(
      birthdays.entries.toList()
          ..sort((date1, date2) => date1.value.compareTo(date2.value))
    );

    return sortedKeys;
  }

  Future<ListView> daysToColumn() async {
    final Map<Contact, DateTime>? birthdays = await getContactsAndBirthdays();

    List<Row> rowList = [];
    birthdays?.forEach((c, day) => rowList.add(contactToRow(c, day)));

    return ListView(children: rowList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Birthdays")
      ),
      body: FutureBuilder(
          future: daysToColumn(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error.toString());
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.data as ListView;
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
      ),
    );
  }
}
