import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class StaffPopup extends StatefulWidget {
  final String image;
  final String name;
  final String designation;
  final String specialization;
  final String experience;
  final String mobile;
  final String about;
  final String status;

  const StaffPopup({
    Key? key,
    required this.image,
    required this.name,
    required this.designation,
    required this.specialization,
    required this.experience,
    required this.mobile,
    required this.about,
    required this.status,
  }) : super(key: key);

  @override
  _StaffPopupState createState() => _StaffPopupState();
}

class _StaffPopupState extends State<StaffPopup> {
  late TextEditingController nameController;
  late TextEditingController designationController;
  late TextEditingController specializationController;
  late TextEditingController experienceController;
  late TextEditingController mobileController;
  late TextEditingController aboutController;
  late TextEditingController statusController;
  late TextEditingController imageController;

  late String _displayedImage; // Track the displayed image URL or path
  bool _isDefaultImage = true; // Track whether the default image is displayed

  bool isEditing = false;

  final ImagePicker _picker = ImagePicker();
  late File _imageFile; // Updated image file variable
// Updated image file variable

  @override
  void initState() {
    super.initState();
    _displayedImage = widget.image.isNotEmpty ? widget.image : 'assets/placeholder_image.jpg';
    _imageFile = File('');
    nameController = TextEditingController(text: widget.name);
    designationController = TextEditingController(text: widget.designation);
    specializationController = TextEditingController(text: widget.specialization);
    experienceController = TextEditingController(text: widget.experience);
    mobileController = TextEditingController(text: widget.mobile);
    aboutController = TextEditingController(text: widget.about);
    statusController = TextEditingController(text: widget.status);
    imageController = TextEditingController(text: widget.image);

    // Load image if widget.image is not empty
    if (widget.image.isNotEmpty) {
      setState(() {
        _imageFile = File(widget.image);
      });
    }

  }

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    mobileController.dispose();
    aboutController.dispose();
    statusController.dispose();
    imageController.dispose();
    super.dispose();
  }

  void updateStaffDetailsByNameAndMobile(
      String name, String mobile, Map<String, dynamic> updatedData) {
    FirebaseFirestore.instance
        .collection('staffs')
        .where('name', isEqualTo: name)
        .where('mobile', isEqualTo: mobile)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        String documentId = querySnapshot.docs.first.id;
        FirebaseFirestore.instance
            .collection('staffs')
            .doc(documentId)
            .update(updatedData)
            .then((_) {
          print("Document updated successfully");
          setState(() {
            isEditing = false;
          });
        }).catchError((error) {
          print("Failed to update staff details: $error");
        });
      } else {
        print('Document with name $name and mobile $mobile not found');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _updateImage(String name, String mobile) async {
    final firebaseStorageRef = FirebaseStorage.instance.ref().child('staff_images/$name-$mobile.jpg');

    await firebaseStorageRef.putFile(_imageFile);

    final imageUrl = await firebaseStorageRef.getDownloadURL();

    setState(() {
      imageController.text = imageUrl;
    });

    // Update image URL in Firestore
    updateStaffDetailsByNameAndMobile(widget.name, widget.mobile, {
      'image': imageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(25.0),
          ),
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Staff Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(width: 20,),
                  IconButton(
                    icon: Icon(Icons.edit,size: 30,),
                    onPressed: () {
                      setState(() {
                        isEditing = true; // Enable editing
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await _getImage();
                            _updateImage(widget.name, widget.mobile);
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile)
                                : widget.image.isNotEmpty
                                ? NetworkImage(widget.image)
                                : AssetImage('assets/placeholder_image.jpg') as ImageProvider<Object>,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: aboutController,
                          decoration: InputDecoration(labelText: 'About'),
                          enabled: isEditing,
                        ),
                        SizedBox(height: 10),
                        Text(
                          widget.about,
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20), // Spacer between left and right sides
                  // Right side: Remaining details
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                          enabled: isEditing, // Enable/disable based on editing state
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: designationController,
                          decoration: InputDecoration(labelText: 'Designation'),
                          enabled: isEditing,
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: specializationController,
                          decoration: InputDecoration(labelText: 'Specialization'),
                          enabled: isEditing && widget.designation != 'Admin',
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: experienceController,
                          decoration: InputDecoration(labelText: 'Experience'),
                          enabled: isEditing,
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: mobileController,
                          decoration: InputDecoration(labelText: 'Mobile'),
                          enabled: isEditing,
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: statusController,
                          decoration: InputDecoration(labelText: 'Status'),
                          enabled: isEditing,
                        ),

                        SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('staffs')
                                    .where('name', isEqualTo: widget.name)
                                    .where('mobile', isEqualTo: widget.mobile)
                                    .get()
                                    .then((QuerySnapshot querySnapshot) {
                                  if (querySnapshot.docs.isNotEmpty) {
                                    String documentId = querySnapshot.docs.first.id; // Retrieve the document ID
                                    updateStaffDetailsByNameAndMobile(widget.name, widget.mobile, {
                                      'name': nameController.text,
                                      'designation': designationController.text,
                                      'specialization': specializationController.text,
                                      'experience': experienceController.text,
                                      'mobile': mobileController.text,
                                      'status': statusController.text,
                                      'about': aboutController.text,
                                    });
                                  } else {
                                    print('Document with name ${widget.name} and mobile ${widget.mobile} not found');
                                  }
                                }).catchError((error) {
                                  print('Error getting document: $error');
                                });
                              },
                              child: Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                            ),

                            SizedBox(width: 10),
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the popup
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,),
                                child: Text('Close', style: TextStyle(
                                    color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}