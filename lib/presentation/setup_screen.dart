import 'package:flutter/material.dart';
import 'hospice_setup_screen.dart';

class SetupInfoScreen extends StatefulWidget {
  const SetupInfoScreen({super.key});

  @override
  State<SetupInfoScreen> createState() => _SetupInfoScreenState();
}

class _SetupInfoScreenState extends State<SetupInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final patientController = TextEditingController();
  final caregiverController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8F6FC), // lilac white
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: Color(0xFF6B5B95),
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Who are you caring for?",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B5B95),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "We'll help coordinate care and keep everyone connected.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF8B7BB5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Patient name
                  _buildLabel("Patient's Name"),
                  _buildTextField(
                    controller: patientController,
                    hint: "Enter full name",
                  ),

                  const SizedBox(height: 24),

                  /// Caregiver name
                  _buildLabel("Your name"),
                  _buildTextField(
                    controller: caregiverController,
                    hint: "Your full name",
                  ),

                  const SizedBox(height: 24),

                  /// Email
                  _buildLabel("Your email"),
                  _buildTextField(
                    controller: emailController,
                    hint: "name@example.com",
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 40),

                  /// Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5B95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HospiceSetupScreen(
                                patientName: patientController.text,
                                caregiverName: caregiverController.text,
                                email: emailController.text,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B5B95),
        ),
      ),
    );
  }

  // 🔹 TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFE5E1F0), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}