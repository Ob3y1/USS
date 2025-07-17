import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubit/user_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<UserCubit>(context).signIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // تم تغيير الخلفية إلى اللون الأبيض
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              color: Colors.black87, // تغيير لون النص إلى الأسود
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white, // خلفية بيضاء
          elevation: 1, // ظل خفيف للتمييز
          automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: BlocConsumer<UserCubit, UserState>(
            listener: (context, state) async {
              if (state is SignInSuccess) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', true);
                Navigator.pushReplacementNamed(context, '/statistics');
              } else if (state is SignInFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errMessage)),
                );
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // حقل البريد الإلكتروني
                  TextFormField(
                    controller: context.read<UserCubit>().emailController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: const TextStyle(
                        color: Colors.black54, // لون نص داكن
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.grey.shade50, // خلفية رمادية فاتحة
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(color: Colors.black87), // نص أسود
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'يرجى إدخال بريد إلكتروني صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  TextFormField(
                    controller: context.read<UserCubit>().passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey.shade600, // لون رمادي متوازن
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87), // نص أسود
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 4) {
                        return 'يجب أن تكون كلمة المرور 4 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // زر تسجيل الدخول
                  state is SignInLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blue.shade700, // لون أزرق غامق
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: Colors.white, // نص أبيض
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
