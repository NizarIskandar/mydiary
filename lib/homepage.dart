import 'package:flutter/material.dart';
import 'settingspage.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All diaries
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  // This function is used to fetch all data from the database
  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshDiaries(); // Loading the diary when the app starts
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update a diary
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new diary
      // id != null -> update an existing diary
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
    }

    showModalBottomSheet(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(hintText: 'Feeling'),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                // Save new diary
                if (id == null) {
                  await _addDiary();
                }

                if (id != null) {
                  await _updateDiary(
                      id, _feelingController.text, _descriptionController.text);
                }

                // Clear the text fields
                _feelingController.text = '';
                _descriptionController.text = '';

                // Close the bottom sheet
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Create New' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Insert a new diary to the database
  Future<void> _addDiary() async {
    await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Update an existing diary
  Future<void> _updateDiary(int id, String feeling, String description) async {
    await SQLHelper.updateDiary(id, feeling, description);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your diary has been updated!'),
      ),
    );
    _refreshDiaries();
  }

  // Delete an item
  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully deleted a diary!'),
      ),
    );
    _refreshDiaries();
  }

  // Helper method to get the emoji GIF based on feeling
  AssetImage _getEmojiGif(String feeling) {
    switch (feeling) {
      case 'Happy':
        return const AssetImage('assets/images/happy.gif');
      case 'Sad':
        return const AssetImage('assets/images/sad.gif');
      case 'Angry':
        return const AssetImage('assets/images/angry.gif');
      case 'Loved':
        return const AssetImage('assets/images/loved.gif');
      case 'Frust':
        return const AssetImage('assets/images/frust.gif');
      case 'Embarassed':
        return const AssetImage('assets/images/embarassed.gif');
      // Add more cases for other feelings as needed
      default:
        return const AssetImage('assets/images/default.gif');
    }
  }

  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      _showForm(null);
    } else if (index == 3) {
      // Navigate to the SettingsPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("My Secret"),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _currentIndex == 0
                ? ListView.builder(
                    itemCount: _diaries.length,
                    itemBuilder: (context, index) => Card(
                      color: const Color.fromARGB(172, 30, 38, 160),
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Image(
                            image: _getEmojiGif(_diaries[index]['feeling']),
                          ),
                          backgroundColor:
                              const Color.fromARGB(255, 15, 15, 15),
                        ),
                        title: Text(_diaries[index]['feeling']),
                        subtitle: Text(
                          _diaries[index]['description'] +
                              '\n\n' +
                              _diaries[index]['createdAt'],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(_diaries[index]['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteDiary(_diaries[index]['id']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(), // Empty container as there are no favorite diaries
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => _onTabTapped(0),
                  color: _currentIndex == 0 ? Colors.blue : Colors.grey,
                ),
                const SizedBox.shrink(),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _onTabTapped(3),
                  color: _currentIndex == 3 ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _onTabTapped(2),
        ),
      ),
    );
  }
}
