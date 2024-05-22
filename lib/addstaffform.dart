import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'firebase_options.dart';
import 'Managestaff.dart';

class FirestoreDropdownService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDesignations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('designation').get();
      List<String> designations = querySnapshot.docs.map((doc) => doc.get('designation') as String).toList();
      return designations;
    } catch (e) {
      print('Error fetching designations: $e');
      return [];
    }
  }

  Future<List<String>> getSpecializations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Specialisation').get();
      List<String> specializations = querySnapshot.docs.map((doc) => doc.get('Specialisation') as String).toList();
      return specializations;
    } catch (e) {
      print('Error fetching specializations: $e');
      return [];
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addStaffDetails({
    required String name,
    required String designation,
    required String specialization,
    required String experience,
    required String mobile,
    required String qualification,
    required String about,
    required String image,
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

  Future<String> uploadImage(dynamic image) async {
    try {
      String fileName = path.basename(image.path);
      final ref = _storage.ref().child('images/$fileName');
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await image.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(image.path));
      }
      await uploadTask.whenComplete(() => null);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Error uploading image.');
    }
  }
}

class StaffDetailsForm extends StatefulWidget {
  @override
  _StaffDetailsFormState createState() => _StaffDetailsFormState();
}

class _StaffDetailsFormState extends State<StaffDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController qualificationController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  String? designationValue;
  String? specializationValue;
  dynamic _image;
  late ImagePicker picker;
  late FirestoreDropdownService _dropdownService;
  List<String> designations = [];
  List<String> specializations = [];
  bool specializationEnabled = true;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    _dropdownService = FirestoreDropdownService();
    fetchDataForDropdowns();
  }

  Future<void> fetchDataForDropdowns() async {
    designations = await _dropdownService.getDesignations();
    specializations = await _dropdownService.getSpecializations();
    setState(() {});
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Details Form'),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StaffTable()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth > 600 ? _buildDesktopView() : _buildMobileView();
        },
      ),
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
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
                        ? Icon(Icons.add_photo_alternate_outlined, color: Colors.purple, size: 100)
                        : (kIsWeb ? Image.network(_image.path, fit: BoxFit.cover) : Image.file(File(_image.path), fit: BoxFit.cover)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(nameController, 'Enter Name', validateName),
              SizedBox(height: 10),
              _buildTextField(experienceController, 'Enter Experience', validateExperience),
              SizedBox(height: 10),
              _buildTextField(mobileController, 'Enter Mobile Number', validateMobile),
              SizedBox(height: 10),
              _buildDropdownField(
                designationValue,
                'Designation',
                designations,
                    (newValue) {
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
                validateDesignation,
              ),
              SizedBox(height: 10),
              if (specializationEnabled)
                _buildDropdownField(
                  specializationValue,
                  'Specialization',
                  specializations,
                      (newValue) {
                    setState(() {
                      specializationValue = newValue;
                    });
                  },
                  validateSpecialization,
                ),
              SizedBox(height: 10),
              _buildTextField(qualificationController, 'Enter Qualification', validateQualification),
              SizedBox(height: 10),
              _buildTextField(aboutController, 'About Doctor', validateAbout),
              SizedBox(height: 20),
              _buildFormButtons(),
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
                      ? Icon(Icons.add_photo_alternate_outlined, color: Colors.purple, size: 100)
                      : (kIsWeb ? Image.network(_image.path, fit: BoxFit.cover) : Image.file(File(_image.path), fit: BoxFit.cover)),
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
                    _buildTextField(nameController, 'Enter Name', validateName),
                    SizedBox(height: 10),
                    _buildTextField(experienceController, 'Enter Experience', validateExperience),
                    SizedBox(height: 10),
                    _buildTextField(mobileController, 'Enter Mobile Number', validateMobile),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            designationValue,
                            'Designation',
                            designations,
                                (newValue) {
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
                            validateDesignation,
                          ),
                        ),
                        SizedBox(width: 10),
                        if (specializationEnabled)
                          Expanded(
                            child: _buildDropdownField(
                              specializationValue,
                              'Specialization',
                              specializations,
                                  (newValue) {
                                setState(() {
                                  specializationValue = newValue;
                                });
                              },
                              validateSpecialization,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildTextField(qualificationController, 'Enter Qualification', validateQualification),
                    SizedBox(height: 10),
                    _buildTextField(aboutController, 'About Doctor', validateAbout),
                    SizedBox(height: 20),
                    _buildFormButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, FormFieldValidator<String> validator) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField(
      String? value,
      String hintText,
      List<String> items,
      ValueChanged<String?> onChanged,
      FormFieldValidator<String?> validator,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hintText,
        border: OutlineInputBorder(),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildFormButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('Submit',style:
          TextStyle(color: Colors.white,fontWeight: FontWeight.w700,fontSize: 15),),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
        SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            _formKey.currentState!.reset();
            setState(() {
              nameController.clear();
              experienceController.clear();
              mobileController.clear();
              qualificationController.clear();
              aboutController.clear();
              designationValue = null;
              specializationValue = null;
              _image = null;
            });
          },
            child: Text('Reset',style:
            TextStyle(color: Colors.white,fontWeight: FontWeight.w700,fontSize: 15),),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image.')));
        return;
      }

      try {
        FirestoreService firestoreService = FirestoreService();
        String imageUrl = await firestoreService.uploadImage(_image);

        await firestoreService.addStaffDetails(
          name: nameController.text,
          designation: designationValue!,
          specialization: specializationValue!,
          experience: experienceController.text,
          mobile: mobileController.text,
          qualification: qualificationController.text,
          about: aboutController.text,
          image: imageUrl,
          createdBy: 'admin',
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Staff details added successfully.')));
        _formKey.currentState!.reset();
        setState(() {
          nameController.clear();
          experienceController.clear();
          mobileController.clear();
          qualificationController.clear();
          aboutController.clear();
          designationValue = null;
          specializationValue = null;
          _image = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding staff details.')));
      }
    }
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name.';
    }
    return null;
  }

  String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter experience.';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a mobile number.';
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

  String? validateQualification(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a qualification.';
    }
    return null;
  }

  String? validateAbout(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter information about the doctor.';
    }
    return null;
  }
}

