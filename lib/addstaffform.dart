import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Managestaff.dart';
import 'firebase_options.dart';


class FirestoreDropdownService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDesignations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('designation').get();
      List<String> designations =
      querySnapshot.docs.map((doc) => doc.get('designation') as String).toList();
      return designations;
    } catch (e) {
      print('Error fetching designations: $e');
      return [];
    }
  }

  Future<List<String>> getSpecializations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Specialisation').get();
      List<String> specializations =
      querySnapshot.docs.map((doc) => doc.get('Specialisation') as String).toList();
      return specializations;
    } catch (e) {
      print('Error fetching specializations: $e');
      return [];
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStaffDetails({
    required String name,
    required String designation,
    required String specialization,
    required String experience,
    required String mobile,
    required String qualification,
    required String about,
    required dynamic image,
    required String createdBy,
  }) async {
    try {
      DateTime createdAt = DateTime.now();
      await _firestore.collection('staffs').add({
        'name': name,
        'designation': designation,
        'specialization': specialization,
        'experience': experience,
        'mobile': mobile,
        'qualification': qualification,
        'about': about,
        'status': 'AA',
        'createdAt': createdAt,
        'createdBy': createdBy,
        'image': image,
      });
    } catch (e) {
      print('Error adding staff details: $e');
      throw Exception('Error adding staff details.');
    }
  }
}

class StaffDetailsForm extends StatefulWidget {
  @override
  _StaffDetailsFormState createState() => _StaffDetailsFormState();
}

class _StaffDetailsFormState extends State<StaffDetailsForm> {
  TextEditingController nameController = TextEditingController();
  String? designationValue;
  String? specializationValue;
  TextEditingController experienceController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController qualificationController = TextEditingController();
  TextEditingController aboutController = TextEditingController();

  dynamic _image;
  final picker = ImagePicker();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late FirestoreDropdownService _dropdownService;
  List<String> designations = [];
  List<String> specializations = [];
  bool specializationEnabled = true;

  @override
  void initState() {
    super.initState();
    _dropdownService = FirestoreDropdownService();
    fetchDataForDropdowns();
  }

  Future<void> fetchDataForDropdowns() async {
    designations = await _dropdownService.getDesignations();
    specializations = await _dropdownService.getSpecializations();
    setState(() {});
  }

  Widget _buildDropdownField(
      String? value,
      String label,
      List<String> options, {
        String? Function(String?)? validator,
        bool isEnabled = true,
        void Function(String?)? onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: isEnabled ? onChanged : null,
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
        validator: validator,
        onTap: () {},
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Details Form'),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts), // Icon for "Manage Staff"
            onPressed: () {
              // Navigate to the StaffTable screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StaffTable()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 600) {
            return _buildDesktopView();
          } else {
            return _buildMobileView();
          }
        },
      ),
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: getImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.purple),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: _image == null
                        ? Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.purple, size: 100)
                        : Image.network(
                      _image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                nameController,
                'Enter Name',
                validator: validateName,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      experienceController,
                      'Enter Experience',
                      validator: validateExperience,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      mobileController,
                      'Enter Mobile Number',
                      validator: validateMobile,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      designationValue,
                      'Designation',
                      designations,
                      onChanged: (newValue) {
                        setState(() {
                          designationValue = newValue;
                          if (newValue == 'Doctor') {
                            specializationEnabled = true;
                          } else {
                            specializationEnabled = false;
                            specializationValue = null;
                          }
                        });
                      },
                      validator: validateDesignation,
                    ),
                  ),
                  SizedBox(width: 10),
                  if (specializationEnabled)
                    Expanded(
                      child: _buildDropdownField(
                        specializationValue,
                        'Specialization',
                        specializations,
                        onChanged: (newValue) {
                          setState(() {
                            specializationValue = newValue;
                          });
                        },
                        validator: validateSpecialization,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              _buildTextField(
                qualificationController,
                'Enter Qualification',
                validator: validateQualification,
              ),
              SizedBox(height: 10),
              _buildTextField(
                aboutController,
                'About Doctor',
                validator: validateAbout,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          FirestoreService _firestoreService = FirestoreService();
                          await _firestoreService.addStaffDetails(
                            name: nameController.text,
                            designation: designationValue ?? '',
                            specialization: specializationValue ?? '',
                            experience: experienceController.text,
                            mobile: mobileController.text,
                            qualification: qualificationController.text,
                            about: aboutController.text,
                            image: _image,
                            createdBy: 'UserXYZ',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data saved successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          _formKey.currentState?.reset();
                          nameController.clear();
                          experienceController.clear();
                          mobileController.clear();
                          qualificationController.clear();
                          aboutController.clear();
                          setState(() {
                            designationValue = null;
                            specializationValue = null;
                            _image = null;
                          });
                        } catch (e) {
                          print('Error submitting form: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error submitting form'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      nameController.clear();
                      experienceController.clear();
                      mobileController.clear();
                      qualificationController.clear();
                      aboutController.clear();
                      setState(() {
                        designationValue = null;
                        specializationValue = null;
                        _image = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: getImage,
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: _image == null
                      ? Icon(Icons.add_photo_alternate_outlined,
                      color: Colors.purple, size: 100)
                      : Image.network(
                    _image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      nameController,
                      'Enter Name',
                      validator: validateName,
                    ),
                    SizedBox(height: 10),
                    _buildTextField(
                      experienceController,
                      'Enter Experience',
                      validator: validateExperience,
                    ),
                    SizedBox(height: 10),
                    _buildTextField(
                      mobileController,
                      'Enter Mobile Number',
                      validator: validateMobile,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            designationValue,
                            'Designation',
                            designations,
                            onChanged: (newValue) {
                              setState(() {
                                designationValue = newValue;
                                if (newValue == 'Doctor') {
                                  specializationEnabled = true;
                                } else {
                                  specializationEnabled = false;
                                  specializationValue = null;
                                }
                              });
                            },
                            validator: validateDesignation,
                          ),
                        ),
                        SizedBox(width: 10),
                        if (specializationEnabled)
                          Expanded(
                            child: _buildDropdownField(
                              specializationValue,
                              'Specialization',
                              specializations,
                              onChanged: (newValue) {
                                setState(() {
                                  specializationValue = newValue;
                                });
                              },
                              validator: validateSpecialization,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildTextField(
                      qualificationController,
                      'Enter Qualification',
                      validator: validateQualification,
                    ),
                    SizedBox(height: 10),
                    _buildTextField(
                      aboutController,
                      'About Doctor',
                      validator: validateAbout,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                FirestoreService _firestoreService = FirestoreService();
                                await _firestoreService.addStaffDetails(
                                  name: nameController.text,
                                  designation: designationValue ?? '',
                                  specialization: specializationValue ?? '',
                                  experience: experienceController.text,
                                  mobile: mobileController.text,
                                  qualification: qualificationController.text,
                                  about: aboutController.text,
                                  image: _image,
                                  createdBy: 'UserXYZ',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Data saved successfully'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                _formKey.currentState?.reset();
                                nameController.clear();
                                experienceController.clear();
                                mobileController.clear();
                                qualificationController.clear();
                                aboutController.clear();
                                setState(() {
                                  designationValue = null;
                                  specializationValue = null;
                                  _image = null;
                                });
                              } catch (e) {
                                print('Error submitting form: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error submitting form'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _formKey.currentState?.reset();
                            nameController.clear();
                            experienceController.clear();
                            mobileController.clear();
                            qualificationController.clear();
                            aboutController.clear();
                            setState(() {
                              designationValue = null;
                              specializationValue = null;
                              _image = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
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

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
        String? Function(String?)? validator,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          errorStyle: TextStyle(fontSize: 12),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name.';
    }
    if (value.length < 4 || value.length > 30) {
      return 'Name should be between 4 and 30 characters.';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a mobile number.';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Enter a valid 10-digit mobile number starting with 6, 7, 8, or 9.';
    }
    return null;
  }

  String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter experience.';
    }
    int? experienceYears = int.tryParse(value);
    if (experienceYears == null || experienceYears > 40) {
      return 'Experience should be a valid number less than or equal to 40.';
    }
    return null;
  }

  String? validateQualification(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter qualification.';
    }
    if (value.length < 4 || value.length > 30) {
      return 'Qualification should be between 4 and 30 characters.';
    }
    return null;
  }

  String? validateDesignation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a designation.';
    }
    return null;
  }

  String? validateSpecialization(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a specialization.';
    }
    return null;
  }

  String? validateAbout(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter about.';
    }
    List<String> words = value.trim().split(RegExp(r'\s+'));
    if (words.length > 30) {
      return 'About should not exceed 30 words.';
    }
    return null;
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile.path; // Store image path for mobile, URL for web
      } else {
        print('No image selected.');
      }
    }
    );
    }
  }