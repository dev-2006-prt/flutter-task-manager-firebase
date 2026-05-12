import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const LoginScreen(), // ADD THIS
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  super.dispose();
}
  Future<void> login() async{
    setState(() {
      loading = true ;
    });

    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email : emailController.text.trim(),
        password : passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content : Text(e.message ?? "Login failed"),
        ),
        );
    }
    setState(() {
      loading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:20),
            ElevatedButton(
              onPressed: login,
              child: loading
              ? const CircularProgressIndicator()
              : const Text("login"),
              ),
              TextButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:(_)=> const RegisterScreen(),
                    ),
                );
              }, 
              child: const Text("Create Acoount"),
              ),
          ],
        ),
        ),
    );

  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  super.dispose();
}

  bool loading = false ;

  Future<void> register() async{
    setState(() {
      loading =true;
    });
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email : emailController.text.trim(),
        password : passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder : (_) => const HomeScreen(),
        ),
        );
    }on FirebaseAuthException catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content : Text(e.message ?? "Registration failed"),
        ),
        );
    }

    setState(() {
      loading = false;
    });
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
         body: Padding(
        padding: const EdgeInsets.all(20),
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:20),
            ElevatedButton(
              onPressed: register,
              child: loading
              ? const CircularProgressIndicator()
              : const Text("Register"),
              ),
          ],
    ),
   ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskController = TextEditingController();
  

  CollectionReference tasks =
      FirebaseFirestore.instance.collection('tasks');

 Future<void> addTask() async {
  if (taskController.text.trim().isEmpty) return;

  try {
    print("Adding task...");

    await tasks.add({
      'title': taskController.text.trim(),
      'isDone': false,
    });

    print("Task added!");

    taskController.clear();

  } catch (e) {
    print("ERROR: $e");
  }
}

  Future<void> deleteTask(String id) async {
    await tasks.doc(id).delete();
  }

  Future<void> toggleTask(String id, bool value) async {
    await tasks.doc(id).update({
      'isDone': !value,
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Task"),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              hintText: "Enter Task",
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await addTask();
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: tasks.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No Tasks"),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No Tasks Added"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var task = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Checkbox(
                    value: task['isDone'],
                    onChanged: (_) {
                      toggleTask(
                        task.id,
                        task['isDone'],
                      );
                    },
                  ),
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      decoration: task['isDone']
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      deleteTask(task.id);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

