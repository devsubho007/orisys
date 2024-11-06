import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:orisys/main.dart';
import 'package:orisys/model/Global.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PastAttendance.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isInButtonDisabled = false;
  bool isOutButtonDisabled = true;
  String State ="";
  final TextEditingController _textFieldController = TextEditingController();

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 24), // Error icon
              SizedBox(width: 10), // Space between icon and title
              Text('Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Title style
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding for content
            child: Text(
              message,
              style: const TextStyle(fontSize: 16), // Content text style
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.teal, fontSize: 16), // Button style
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding for the button
                backgroundColor: Colors.grey[200], // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded button
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<int> _sendLocation(String action, {String? inputText}) async {
    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Create API payload
    if (action=="IN")
      {
        State='I';
      }
    else
      {
        State='O';
      }

     // Replace with your API URL
    final url = Uri.parse("http://orionline.in/api/Employee/SetAttendance");
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "EmpID":global.EmpID ,
          "Remarks": inputText,
          "InOut": State,
          "Longitude": position.longitude,
          "Latitude": position.latitude
        }));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {

        return 1;
      } else {
        _showDialog("Already $action");
        return 0;
      }
    } else {
      _showDialog("Please try After Some time !!!!!");
      return 0;
    }
  }

  Future<void> _handleInButton() async {
    String textFieldValue = _textFieldController.text;

    // Validate that TextField is not empty for "IN" button
    if (textFieldValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text before pressing "IN".'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Don't proceed if the text is empty
    }

    // Send location and text to API
    int output = await _sendLocation("IN", inputText: textFieldValue);

    // Clear the TextField after submission
    _textFieldController.clear();

    if (output == 1) {
      _showDialog("IN Successfully");
      // After successful IN, set the button states
      setState(() {
        isInButtonDisabled = true;  // Disable the IN button
        isOutButtonDisabled = false; // Enable the OUT button
      });
    }
  }

  Future<void> _handleOutButton() async {
    // Send location to API (TextField is optional for OUT)
    String textFieldValue = _textFieldController.text;

    // Validate that TextField is not empty for "IN" button
    if (textFieldValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text before pressing "OUT".'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Don't proceed if the text is empty
    }

    int output = await _sendLocation("OUT", inputText: textFieldValue);
    _textFieldController.clear();
    if (output == 1) {
      _showDialog("OUT Successfully");
      // After successful OUT, set the button states
      setState(() {
        isInButtonDisabled = false; // Enable the IN button
        isOutButtonDisabled = true;  // Disable the OUT button
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('EmpID');
    await prefs.remove('username');
    await prefs.remove('password');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );// Redirect to LoginPage
  }

  Future<void> _past(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AttendanceScreen()),
    );// Redirect to LoginPage
  }


  @override
  void initState() {
    super.initState();

    _checkInOUTState();
  }

  Future<void> _checkInOUTState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? empId = prefs.getInt('empID');
    String status = "";
    final response = await http.post(
      Uri.parse('http://orionline.in/api/Employee/AttendanceStatus'),
      body: {
        'EmpID': empId.toString()
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      status = data['message'];
    } else {
      _showDialog("Failed to fetch attendance status. Please try again.");
      return; // Exit if there is an error
    }

    // Update button states based on the attendance status
    setState(() {
      if (status == "IN") {
        isInButtonDisabled = true; // Disable IN button
        isOutButtonDisabled = false; // Enable OUT button
      } else {
        isInButtonDisabled = false; // Enable IN button
        isOutButtonDisabled = true; // Disable OUT button
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28, color: Colors.white),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        elevation: 4,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(

                child: Text(
                  'Quick Acess',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.black),
              title: const Text(
                'Past Visits',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              onTap: () {
                _past(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent,
                Colors.purpleAccent,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: height * 0.05),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child:Text(
                      "Welcome ${global.empName} ",
                      style: TextStyle(
                        fontSize: width * 0.06, // 7% of screen width

                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.01), // 5% of screen height
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child:Text(
                      "Mark your attendance .",
                      style: TextStyle(
                        fontSize: width * 0.06, // 7% of screen width

                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.05),
                  // TextField Input
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05), // 5% of screen width
                    child: Card(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _textFieldController, // Use the controller to get text
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(top: 20.0), // Adjust padding for label
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Remarks ",
                                    style: TextStyle(color: Colors.black, fontSize: 24,fontWeight: FontWeight.bold), // Hint text style
                                    children: [
                                      TextSpan(
                                        text: "*",
                                        style: TextStyle(color: Colors.red,fontSize: 20), // Red star style
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )

                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.05), // 5% of screen height
                  ElevatedButton(
                    onPressed: isInButtonDisabled ? null : _handleInButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.2, // 20% of screen width
                        vertical: height * 0.02, // 2% of screen height
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: Text(
                      "IN",
                      style: TextStyle(
                          fontSize: width * 0.06, color: Colors.black), // 6%
                    ),
                  ),
                  SizedBox(height: height * 0.05), // 5%
                  ElevatedButton(
                    onPressed: isOutButtonDisabled ? null : _handleOutButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.2,
                        vertical: height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: Text(
                      "OUT",
                      style: TextStyle(
                          fontSize: width * 0.06, color: Colors.black), // 6%
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
