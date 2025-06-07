import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'widgets/chat_widget.dart';
import 'widgets/modern_chat_widget.dart';
import 'widgets/event_widget.dart' as event;
import 'widgets/history_widget.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'utils/config.dart';
import 'screens/workflows_screen.dart'; // Import the workflows screen

// Import or define necessary screens and providers
import 'providers/event_provider.dart' as event_provider;
import 'providers/chat_provider.dart';

// Widget tùy chỉnh cho AppBar với gradient
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF081C16),
            Color(0xFF014D17),
          ],
        ),
      ),
      child: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: actions,
        // Enhanced menu button
        leading: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.only(left: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Mở menu di chuyển',
              onPressed: () => Scaffold.of(context).openDrawer(),
              splashColor: Colors.greenAccent,
              highlightColor: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Widget tùy chỉnh cho Footer với gradient
class GradientFooter extends StatelessWidget {
  final Widget child;

  const GradientFooter({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF081C16),
            Color(0xFF014D17),
          ],
        ),
      ),
      child: child,
    );
  }
}

// Widget Button với gradient đỏ
class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF5C0000),
            Color(0xFFC20000),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;

  try {
    // Load the .env file
    await dotenv.load(fileName: ".env");
    envLoaded = true;
    print("Env loaded successfully");
  } catch (e) {
    print("Error loading .env file: $e");
    print("Using default environment values");
  }

  // Initialize dotenv with default values if loading failed
  if (!envLoaded) {
    // Create a simple .env file with default values
    try {
      dotenv.testLoad(fileInput: '''
SERVER_IP=192.168.1.67
API_URL=http://192.168.1.67:8080
WS_URL=ws://192.168.1.67:8080/events/ws
API_TIMEOUT=30000
DEBUG_MODE=false
DEFAULT_USERNAME=user1
''');
      print("Default environment values loaded");
    } catch (e) {
      print("Error loading default values: $e");
    }
  }

  // Debug: print out the loaded environment values
  try {
    print("SERVER_IP: ${AppConfig.serverIp}");
    print("API_URL: ${AppConfig.apiUrl}");
    print("WS_URL: ${AppConfig.wsUrl}");
  } catch (e) {
    print("Error accessing environment values: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => event_provider.EventProvider()),
        Provider(create: (_) => ApiService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Botkube Flutter Connector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(elevation: 2),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
        '/chat': (context) => ChatWidget(),
        '/events': (context) => event.EventScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập username';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Xóa token cũ trước khi đăng nhập lại
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        // Sử dụng utf8.decode để đảm bảo dữ liệu được decode với mã hóa UTF-8 chính xác
        final String utf8Body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(utf8Body);
        final token = data['token'];
        // Store token in SharedPreferences
        await prefs.setString('jwt_token', token);
        await prefs.setString('username', username);

        // Lưu vai trò người dùng
        String role = username == 'user1' ? 'admin' : 'user';
        await prefs.setString('user_role', role);
        print('Đăng nhập thành công với vai trò: $role');

        // Cập nhật token trong ChatProvider
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.setToken(token);

        // Tải lịch sử chat sau khi đăng nhập
        try {
          await chatProvider.loadHistory();
          print('Đã tải lịch sử chat sau khi đăng nhập');
        } catch (e) {
          print('Lỗi khi tải lịch sử chat sau khi đăng nhập: $e');
        }

        // Navigate to chat screen
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() {
          _errorMessage = 'Đăng nhập thất bại: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Đăng Nhập'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Đăng Nhập Botkube',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : GradientButton(
                    onPressed: _login,
                    child: Text('Đăng Nhập',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _workflow = [];
  int _selectedIndex = 0;
  String username = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Làm mới token khi màn hình chính được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.reloadToken();

      // Kiểm tra SharedPreferences để debug
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final role = prefs.getString('user_role') ?? '';
      print(
          'MainScreen được tạo - Token: ${token.isNotEmpty ? 'Có (${token.length} ký tự)' : 'Không có'}, Vai trò: $role');

      // Lắng nghe thay đổi từ chatProvider
      chatProvider.addListener(() {
        setState(() {
          _workflow = chatProvider.workflow;
        });
      });

      username = prefs.getString('username') ?? '';
      _userRole = prefs.getString('user_role') ?? '';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Botkube',
        actions: [
          // Logout button with enhanced visibility
          Container(
            margin: EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                // Xác nhận trước khi đăng xuất
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Xác nhận đăng xuất'),
                    content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Đăng xuất'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  _logout();
                }
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const ModernChatWidget(), // Use the new modern chat widget
        event.EventScreen(),
        HistoryScreen(),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return GradientFooter(
      child: SafeArea(
        bottom: true,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.chat, 'Chat'),
              _buildNavItem(1, Icons.event, 'Sự kiện'),
              _buildNavItem(2, Icons.history, 'Lịch sử'),
            ].map((item) => Expanded(child: item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: isSelected
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF744103),
                        Color(0xFFF4C430),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 24 : 22,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF081C16), Color(0xFF014D17)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Botkube Flutter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  username.isNotEmpty
                      ? 'Đã đăng nhập: $username'
                      : 'Chưa đăng nhập',
                  style: TextStyle(color: Colors.white70),
                ),
                if (_userRole.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _userRole == 'admin'
                          ? Colors.green[700]
                          : Colors.orange[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Vai trò: ${_userRole.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
            selected: _selectedIndex == 0,
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.event),
            title: Text('Sự kiện'),
            selected: _selectedIndex == 1,
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Lịch sử chat'),
            selected: _selectedIndex == 2,
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          // Add new Workflows option
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Quy trình làm việc'),
            onTap: () {
              // Navigate to Workflows screen
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkflowsScreen(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Đăng xuất'),
            onTap: () {
              _logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _logout() async {
    // Clear user preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('jwt_token');
    prefs.remove('username');
    prefs.remove('user_role');

    // Reset state
    setState(() {
      username = '';
      _userRole = '';
    });

    // Restart app or show login dialog
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đăng xuất thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
