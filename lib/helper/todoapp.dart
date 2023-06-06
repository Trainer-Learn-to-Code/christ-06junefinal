import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoapp_christ/helper/sql_helper.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  //FormKey
  var _todoFormKey = GlobalKey<FormState>();

  // All journals
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data.map((item) => {...item, 'isChecked': false}).toList();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
    _initSharedPreferences();
  }

  SharedPreferences? _prefs;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
      _startDateController.text = existingJournal['startDate'];
      _endDateController.text = existingJournal['endDate'];
    }

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        // <-- SEE HERE
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25.0),
        ),
      ),
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          // this will prevent the soft keyboard from covering the text fields
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Form(
          key: _todoFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null) {
                      return "Enter title";
                    }
                    return null;
                  },
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(hintText: 'Note'),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                      icon: Icon(Icons.calendar_today), //icon of text field
                      labelText: "Start Date"),
                  readOnly: true,
                  //set it true, so that user will not able to edit text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        //DateTime.now() - not to allow to choose before today.
                        lastDate: DateTime(2101));
                    if (pickedDate != null) {
                      print(
                          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      print(
                          formattedDate); //formatted date output using intl package =>  2021-03-16
                      //you can implement different kind of Date Format here according to your requirement

                      setState(() {
                        _startDateController.text =
                            formattedDate; //set output date to TextField value.
                      });
                    } else {
                      print("Date is not selected");
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                      icon: Icon(Icons.calendar_today), //icon of text field
                      labelText: "End Date"),
                  readOnly: true,
                  //set it true, so that user will not able to edit text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        //DateTime.now() - not to allow to choose before today.
                        lastDate: DateTime(2101));
                    if (pickedDate != null) {
                      print(
                          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      print(
                          formattedDate); //formatted date output using intl package =>  2021-03-16
                      //you can implement different kind of Date Format here according to your requirement

                      setState(() {
                        _endDateController.text =
                            formattedDate; //set output date to TextField value.
                      });
                    } else {
                      print("Date is not selected");
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        if (id == null) {
                          _addItem();
                        }
                      });

                      if (id != null) {
                        _updateItem(id);
                      }

                      // Clear the text fields
                      _titleController.text = '';
                      _descriptionController.text = '';
                      _startDateController.text = '';
                      _endDateController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Center(
                        child: Text(id == null ? 'Create New' : 'Update')),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text,
        _descriptionController.text,
        _startDateController.text,
        _endDateController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id,
        _titleController.text,
        _descriptionController.text,
        _startDateController.text,
        _endDateController.text);
    _refreshJournals();
    _titleController.text = '';
    _descriptionController.text = '';
    _startDateController.text = '';
    _endDateController.text = '';
  }

  void _deleteItem(int id) async {
    final currentDate = DateTime.now();
    final itemIndex = _journals.indexWhere((element) => element['id'] == id);
    final item = _journals[itemIndex];
    final endDateString = item['endDate'];
    final endDate = DateFormat('yyyy-MM-dd').parse(endDateString);

    if (endDate.year == currentDate.year &&
        endDate.month == currentDate.month &&
        endDate.day == currentDate.day) {
      await SQLHelper.deleteItem(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully deleted'),
      ));
      setState(() {
        _journals.removeAt(itemIndex);
        _refreshJournals();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Cannot delete item. End date does not match the current date.'),
      ));

      setState(() {
        _journals.removeAt(itemIndex);
      });

      // Delay the removal of the Dismissible widget to allow time for the SnackBar to be displayed
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _refreshJournals();
        });
      });
    }
  }

  void _deleteItemArchived(int id) async {
    final itemIndex = _journals.indexWhere((element) => element['id'] == id);

    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Moved to archives'),
    ));
    setState(() {
      _journals.removeAt(itemIndex);
      _refreshJournals();
    });
  }

  void _deleteUnwantedItem(int id) async {
    final itemIndex = _journals.indexWhere((element) => element['id'] == id);

    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Item Deleted'),
    ));
    setState(() {
      _journals.removeAt(itemIndex);
      _refreshJournals();
    });
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _savePassword(String password) {
    _prefs?.setString('password', password);
  }

  List<Map<String, dynamic>> _archivedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 10,
        centerTitle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))),
        title: const Text('Todo.com'),
        actions: [
          PopupMenuButton(itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'archives',
                child: Text('Archives'),
              ),
              PopupMenuItem(
                value: 'set_password',
                child: Text('Set Password'),
              ),
            ];
          }, onSelected: (value) {
            if (value == 'archives') {
              // Show archives page
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String password = ''; // Password entered by the user

                  return AlertDialog(
                    title: Text('Enter Password'),
                    content: TextField(
                      obscureText: true,
                      onChanged: (value) {
                        password = value;
                      },
                      decoration: InputDecoration(hintText: 'Password'),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: Text('Confirm'),
                        onPressed: () {
                          // Check if the entered password is correct
                          if (password == _prefs?.getString('password')) {
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArchivedItemsPage(
                                    archivedItems: _archivedItems),
                              ),
                            );
                          } else {
                            // Show an error message if the password is incorrect
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Error'),
                                  content: Text(
                                      'Incorrect password. Please try again.'),
                                  actions: [
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the error dialog
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (value == 'set_password') {
              // Show set password dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String password = '';

                  return AlertDialog(
                    title: Text('Set Password'),
                    content: TextField(
                      obscureText: true,
                      onChanged: (value) {
                        password = value;
                      },
                      decoration: InputDecoration(hintText: 'Password'),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: Text('Save'),
                        onPressed: () {
                          _savePassword(password);
                          // print(password);
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                    ],
                  );
                },
              );
            }
          })
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(0, 98, 86, 86),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/test.jpg"), fit: BoxFit.cover),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  _refreshJournals();
                },
                child: ListView.builder(
                  itemCount: _journals.length,
                  itemBuilder: (context, index) {
                    final journalItem = _journals[index];

                    return Dismissible(
                      key: Key(journalItem.toString()),
                      onDismissed: (direction) {
                        setState(() {
                          _deleteItem(journalItem['id']);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 250,
                          child: Card(
                              elevation: 20,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                              ),
                              child: Column(children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text(
                                      journalItem['title'],
                                      style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic),
                                    ),
                                    trailing: SizedBox(
                                      width: 150,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon:
                                                const Icon(Icons.remove_circle),
                                            onPressed: () =>
                                                _deleteUnwantedItem(
                                                    journalItem['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _showForm(journalItem['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.archive),
                                            onPressed: () {
                                              setState(() {
                                                _archivedItems.add(journalItem);
                                                _journals.removeAt(index);
                                                _deleteItemArchived(
                                                    journalItem['id']);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 5, 0, 5),
                                  child: Text(
                                    journalItem['description'],
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 5, 0, 5),
                                  child: Text(
                                    "Start Date : " + journalItem['startDate'],
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 5, 0, 5),
                                  child: Text(
                                    "End Date : " + journalItem['endDate'],
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ])
                              // trailing: SizedBox(
                              //   width: 150,
                              //   child: Row(
                              //     children: [
                              //       IconButton(
                              //         icon: const Icon(Icons.remove_circle),
                              //         onPressed: () => _deleteUnwantedItem(
                              //             journalItem['id']),
                              //       ),
                              //       IconButton(
                              //         icon: const Icon(Icons.edit),
                              //         onPressed: () =>
                              //             _showForm(journalItem['id']),
                              //       ),
                              //       IconButton(
                              //         icon: const Icon(Icons.archive),
                              //         onPressed: () {
                              //           setState(() {
                              //             _archivedItems.add(journalItem);
                              //             _journals.removeAt(index);
                              //             _deleteItemArchived(
                              //                 journalItem['id']);
                              //           });
                              //         },
                              //       ),
                              //     ],
                              //   ),
                              // ),

                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        elevation: 40,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ArchivedItemsPage extends StatefulWidget {
  final List<Map<String, dynamic>> archivedItems;

  const ArchivedItemsPage({Key? key, required this.archivedItems})
      : super(key: key);

  @override
  State<ArchivedItemsPage> createState() => _ArchivedItemsPageState();
}

class _ArchivedItemsPageState extends State<ArchivedItemsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Items'),
      ),
      body: ListView.builder(
        itemCount: widget.archivedItems.length,
        itemBuilder: (context, index) {
          final item = widget.archivedItems[index];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 250,
              child: Card(
                elevation: 20,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item['title'],
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          item['description'],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          item['startDate'] + " " + item['endDate'],
                          style: TextStyle(
                              fontSize: 15, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ),
                  trailing: SizedBox(
                    width: 50,
                    child: Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.unarchive),
                            onPressed: () async {
                              await SQLHelper.createItem(
                                  item['title'].toString(),
                                  item['description'].toString(),
                                  item['startDate'].toString(),
                                  item['endDate'].toString());
                              widget.archivedItems.removeAt(index);
                              _refreshJournals();
                            }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data.map((item) => {...item, 'isChecked': false}).toList();
      _isLoading = false;
    });
  }
}
