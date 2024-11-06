import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orisys/HomePage.dart';
import 'package:orisys/model/Global.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class LocationService {
  Position? _currentPosition;

  Future<void> requestPermissionAndFetchLocation() async {
    // Request location permission
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      // Get the current location
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print(_currentPosition);
    } else {
      // Handle permission denial
      print("Location permission denied");
    }
  }

  Position? get currentPosition => _currentPosition;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Loading state
  bool _isPasswordVisible = false; // State for password visibility
  LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    locationService.requestPermissionAndFetchLocation();
  }

  Future<void> _checkAutoLogin() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? empId = prefs.getInt('empID');
      String? user = prefs.getString('username');
      String? pass = prefs.getString('password');

      final response = await http.post(
        Uri.parse('https://orionline.in/api/Employee/Login'),
        body: {
          'UserID': user,
          'Upwd': pass,
        },
      );

      if (response.statusCode == 200 && json.decode(response.body)['data'][0] != []) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final employee = responseData['data'][0];
        empId = employee['EmpID'];
        final String empName = employee['EmpName'];

        // Store user info in shared preferences
        await prefs.setInt('empID', empId!);
        await prefs.setString('EmpName', empName);
        await prefs.setString('username', user!);
        await prefs.setString('password', pass!);

        global.EmpID = empId;
        global.empName = empName;

        // Navigate to the next page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // If login fails, show error dialog and clear preferences
        _showDialog('UserID or Password has changed. Login again!');
        await prefs.remove('empID');
        await prefs.remove('username');
        await prefs.remove('password');
      }
    } catch (error) {
      // Handle errors (e.g., network issues)

    } finally {
      // Ensure the loading indicator is hidden no matter what
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _login() async {
    final user = _usernameController.text;
    final pass = _passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Simulate a login process (replace with your API call)
    final response = await http.post(
      Uri.parse('http://orionline.in/api/Employee/Login'),

      body: {
        'UserID': _usernameController.text,
        'Upwd': _passwordController.text,
      },
    );

    if (response.statusCode == 200 ) {

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('data') && responseData['data'] is List && responseData['data'].isNotEmpty)
        {
          final employee = responseData['data'][0];
          final int empId = employee['EmpID'];
          final String empName = employee['EmpName'];


          // Store userId in shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('empID', empId);
          await prefs.setString('EmpName', empName);
          await prefs.setString('username', user);
          await prefs.setString('password', pass);

          global.EmpID=empId;
          global.empName=empName;
          // Navigate to the next page
          var replacement = Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      else
        {
          _showDialog('UerID or Password is wrong !!!!!');
        }

    } else {
      _showDialog('Login failed');
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

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
              Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Title style
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

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600; // Define threshold for small screens

    // Scale factors for adaptive design
    final double scaleFactor = isSmallScreen ? 0.8 : 1.2; // Scale down for small screens, up for large

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login',style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: Colors.teal, // Custom color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80 * scaleFactor, color: Colors.teal),
              SizedBox(height: 20 * scaleFactor),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username*',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 16 * scaleFactor), // Adjust text size
              ),
              SizedBox(height: 16 * scaleFactor),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password*',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible; // Toggle password visibility
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible, // Control the visibility
                style: TextStyle(fontSize: 16 * scaleFactor), // Adjust text size
              ),
              SizedBox(height: 20 * scaleFactor),
              _isLoading // Conditional loading indicator
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: Text('Login', style: TextStyle(fontSize: 16 * scaleFactor,fontWeight: FontWeight.bold, color: Colors.white,)), // Adjust button text size
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32 * scaleFactor, vertical: 16 * scaleFactor),
                  primary: Colors.teal, // Button color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

