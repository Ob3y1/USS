import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'نظام مراقبة الامتحانات',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.dashboard,
              color: Colors.blue,
            ),
            title: const Text('لوحة التحكم',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.group,
              color: Colors.blue,
            ),
            title: const Text('إدارة المستخدمين',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/user_management');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.input,
              color: Colors.blue,
            ),
            title: const Text('إدخال البيانات',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/data_input');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.schedule,
              color: Colors.blue,
            ),
            title: const Text('توليد البرنامج الامتحاني',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(
                  context, '/exam_schedule_generator');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.linear_scale,
              color: Colors.blue,
            ),
            title: const Text('توزيع المراقبين والمواد',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/linear');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.bar_chart,
              color: Colors.blue,
            ),
            title: const Text('الإحصائيات',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/statistics');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.search,
              color: Colors.blue,
            ),
            title: const Text('البحث',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/search_dashboard');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.visibility_off,
              color: Colors.blue,
            ),
            title: const Text('حالات الغش',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/CheatingListScreen');
            },
          ),
          const Divider(),

          // ListTile(
          //   leading: const Icon(
          //     Icons.person,
          //     color: Colors.blue,
          //   ),
          //   title: const Text('لوحة تحكم المراقب',
          //       style: TextStyle(color: Colors.white, fontSize: 18)),
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/supervisor_dashboard');
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(
          //     Icons.calendar_today,
          //     color: Colors.blue,
          //   ),
          //   title: const Text('جدول مواعيد المراقب',
          //       style: TextStyle(color: Colors.white, fontSize: 18)),
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/supervisor_schedule');
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(
          //     Icons.videocam,
          //     color: Colors.blue,
          //   ),
          //   title: const Text('مراقبة القاعة',
          //       style: TextStyle(color: Colors.white, fontSize: 18)),
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/supervisor_monitoring');
          //   },
          // ),
          ListTile(
            leading: const Icon(
              Icons.exit_to_app,
              color: Colors.blue,
            ),
            title: const Text(
              'الملف الشخصي',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            onTap: () {
              // استدعاء تابع تسجيل الخروج من UserCubit
              context.read<UserCubit>().fetchUserProfile(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.exit_to_app,
              color: Colors.blue,
            ),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            onTap: () {
              // استدعاء تابع تسجيل الخروج من UserCubit
              context.read<UserCubit>().logout(context);
            },
          ),
        ],
      ),
    );
  }
}
