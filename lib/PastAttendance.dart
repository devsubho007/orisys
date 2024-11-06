import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:orisys/model/Global.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  
 // int? empId = prefs.getInt('empID');
 // final String empId = global.EmpID.toString();

  @override
  void initState() {
    super.initState();
    fetchAttendanceData(); // Fetch data when screen loads
  }


  Future<void> fetchAttendanceData() async {
    final dateFormatter = DateFormat('dd-MM-yyyy');
    final String from = dateFormatter.format(fromDate);
    final String to = dateFormatter.format(toDate);
    SharedPreferences prefs = await SharedPreferences.getInstance();
     int? empId = prefs.getInt('empID');
    final url = Uri.parse("http://orionline.in/api/Employee/GetAttendanceList");
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "EmpID": int.parse(empId.toString()),
          "FromDate": from,
          "ToDate": to
        }));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          attendanceData = jsonData['data'];
        });
      } else {
        showError(jsonData['message']);
      }
    } else {
      showError("Error fetching data. Please try again.");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked.start;
        toDate = picked.end;
      });
      fetchAttendanceData(); // Fetch data after selecting new date range
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        ); // Or Navigator.pop(context);
        return false; // Prevent default back action to ensure proper handling
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Employee Attendance"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );;
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: selectDateRange,
            ),
          ],
        ),
        body: attendanceData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: attendanceData.length,
          itemBuilder: (context, index) {
            final item = attendanceData[index];
            // Parse the date string to DateTime
            DateTime attendanceDate = DateTime.parse(item['AttDate']);
            // Format the date to dd-MM-yyyy
            String formattedDate = DateFormat('dd-MM-yyyy').format(attendanceDate);
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: $formattedDate",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("In Time: ${item['AttInTime'] ?? 'N/A'}"),
                    Text("Out Time: ${item['AttOutTime'] ?? 'N/A'}"),
                    if (item['AttInRemarks'] != null && item['AttInRemarks']!.isNotEmpty)
                      Text("In Remarks: ${item['AttInRemarks']}"),
                    if (item['AttOutRemarks'] != null && item['AttOutRemarks']!.isNotEmpty)
                      Text("Out Remarks: ${item['AttOutRemarks']}")
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}