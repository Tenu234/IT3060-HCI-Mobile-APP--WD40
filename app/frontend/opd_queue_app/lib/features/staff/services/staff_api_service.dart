import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/walk_in_booking.dart';

class StaffApiService {
  // Change this to your backend URL when ready
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static const String baseUrl = 'http://localhost:5000/api';

  // CREATE — add a new walk-in booking
  Future<WalkInBooking?> createBooking(WalkInBooking booking) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(booking.toJson()),
      );
      if (response.statusCode == 201) {
        return WalkInBooking.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Create booking error: $e');
    }
    return null;
  }

  // READ — get all bookings for today
  Future<List<WalkInBooking>> getAllBookings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/bookings'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => WalkInBooking.fromJson(e)).toList();
      }
    } catch (e) {
      print('Get bookings error: $e');
    }
    return [];
  }

  // UPDATE — update booking details or status
  Future<bool> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update booking error: $e');
    }
    return false;
  }

  // DELETE — void or cancel a booking
  Future<bool> deleteBooking(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/bookings/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Delete booking error: $e');
    }
    return false;
  }
}
