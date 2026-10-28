import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_languages.dart';


class NotificationPage extends StatefulWidget {

  const NotificationPage({
    super.key,
  });

  @override
  State<NotificationPage> createState() =>
      _NotificationPageState();

}



class _NotificationPageState extends State<NotificationPage> {


  List notifications = [];

  bool loading = true;

  String errorMessage = "";



  @override
  void initState() {

    super.initState();

    loadNotifications();

  }




  Future<void> loadNotifications() async {


    try {


      final prefs = await SharedPreferences.getInstance();

      final email = prefs.getString("email");


      if(email == null || email.isEmpty){

        setState(() {

          errorMessage = AppLanguage.text(
            "Email not found",
            "Email မတွေ့ပါ",
          );

          loading = false;

        });

        return;

      }



      final url = Uri.parse(
          ApiConfig.notifications+"?email=$email"
      );


      print("Notification URL : $url");



      final response = await http.get(url)
          .timeout(
          const Duration(seconds: 10)
      );



      print("Status : ${response.statusCode}");

      print("Body : ${response.body}");




      if(response.statusCode == 200){


        final data = jsonDecode(response.body);



        setState(() {


          notifications = data;

          loading = false;



        });

        await markNotificationsRead();

      }else{


        setState(() {


          errorMessage =
          "${AppLanguage.text(
            "Server Error",
            "Server အမှား",
          )} : ${response.statusCode}";


          loading = false;


        });


      }



    }catch(e){


      print("Notification Error : $e");


      setState(() {


        errorMessage = AppLanguage.text(
          "Connection Failed",
          "ချိတ်ဆက်မှု မအောင်မြင်ပါ",
        );


        loading = false;


      });



    }


  }

  Future<void> markNotificationsRead() async {

    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString("email");


    if(email == null) return;


    await http.post(

      Uri.parse(
          ApiConfig.marknotification
      ),

      headers: {
        "Content-Type":"application/json",
        'ngrok-skip-browser-warning':'true'
      },

      body: jsonEncode({

        "email": email

      }),

    );

  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: Text(
          AppLanguage.text(
            "Notifications",
            "အသိပေးချက်များ",
          ),
        ),

        centerTitle: true,

      ),



      body:


      loading


          ?


      const Center(

        child: CircularProgressIndicator(),

      )



          :


      errorMessage.isNotEmpty


          ?


      Center(

        child: Text(

          errorMessage,

          style: const TextStyle(

            color: Colors.red,

            fontSize: 16,

          ),

        ),

      )



          :


      notifications.isEmpty


          ?


      Center(
        child: Text(
          AppLanguage.text(
            "No Notification",
            "အသိပေးချက် မရှိသေးပါ",
          ),
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      )



          :


      RefreshIndicator(


        onRefresh: loadNotifications,


        child: ListView.builder(


          itemCount: notifications.length,


          itemBuilder: (context,index){


            final item = notifications[index];



            return Card(


              margin: const EdgeInsets.symmetric(

                horizontal: 12,

                vertical: 6,

              ),



              child: ListTile(



                leading: CircleAvatar(


                  backgroundColor:


                  item["is_read"] == true


                      ? Colors.grey.shade200


                      : Colors.blue.shade100,



                  child: Icon(


                    item["is_read"] == true


                        ? Icons.notifications_none


                        : Icons.notifications_active,



                    color: Colors.blue,


                  ),


                ),




                title: Text(


                  item["message"] ?? "",



                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                  ),


                ),




                subtitle: Text(


                  item["sent_at"] ?? "",


                ),



              ),


            );


          },


        ),


      ),



    );


  }


}