import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_todo/home_page.dart';
import 'package:flutter_todo/todo.dart';
import 'package:flutter_todo/todo_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "나만의 투두!",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final GoogleSignIn googleSignIn = GoogleSignIn();
                  final googleSignInAccount = await googleSignIn.signIn();
                  final googleSignInAuthentication =
                      await googleSignInAccount?.authentication;

                  if (googleSignInAuthentication == null) {
                    return; // 로그인 실패로 처리
                  }

                  final oauthCred = GoogleAuthProvider.credential(
                    accessToken: googleSignInAuthentication.accessToken,
                    idToken: googleSignInAuthentication.idToken,
                  );

                  final userCredential = await FirebaseAuth.instance
                      .signInWithCredential(oauthCred);
                  if (userCredential.user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return HomePage();
                        },
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Image.asset("assets/ic_google.png", width: 24),
                    SizedBox(width: 8),
                    Text(
                      "구글로 시작하기",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
