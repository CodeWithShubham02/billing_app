import 'package:billing_application/views/bills_history.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../utills/app_constant.dart';
import '../views/add_item.dart';

class AdminDrawerWidget extends StatefulWidget {
  const AdminDrawerWidget({super.key});

  @override
  State<AdminDrawerWidget> createState() => _AdminDrawerWidgetState();
}

class _AdminDrawerWidgetState extends State<AdminDrawerWidget> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: Get.height/8.5),
      child: Drawer(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0))
        ),
        child: Wrap(
          runSpacing: 1,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
              child: ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text("name"),
                leading: CircleAvatar(
                  child: Icon(Icons.person),
                ),
                subtitle: Text("mobile"),

              ),
            ),
            Divider(
              indent: 10.0,
              endIndent: 10.0,
              thickness: 1.5,
              color: AppConstant.appTextColor,
            ),
            ListTile(
              onTap: (){
                Get.to(()=>AddProductScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Add Item"),
              leading: Icon(Icons.fastfood_outlined),

            ),
            ListTile(
              onTap: (){
                Get.to(()=>BillsHistory());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Bills history"),
              leading: Icon(Icons.fastfood_outlined),

            ),
          ],
        ),
        backgroundColor:Colors.white,
        width: 275,

      ),
    );
  }
}