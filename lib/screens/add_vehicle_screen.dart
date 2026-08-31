import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';

class AddVehicleScreen extends StatefulWidget {
  // Optional dependency for Widget Tests.
  //
  // In the real app, when it is not supplied,
  // the screen continues using VehicleRepository.
  final VehicleRepository? repository;

  const AddVehicleScreen({
    super.key,
    this.repository,
  });

  @override
  State<AddVehicleScreen> createState() =>
      _AddVehicleScreenState();
}

class _AddVehicleScreenState
    extends State<AddVehicleScreen> {
  final formKey = GlobalKey<FormState>();

  final licenseController =
      TextEditingController();

  final manufacturerController =
      TextEditingController();

  final modelController =
      TextEditingController();

  final yearController =
      TextEditingController();

  final mileageController =
      TextEditingController();

  VehicleRepository? _vehicleRepository;

  VehicleRepository get vehicleRepository =>
      widget.repository ??
      (_vehicleRepository ??=
          VehicleRepository());

  bool isSaving = false;

  Future<void> saveVehicle() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final vehicle = Vehicle(
        license:
            licenseController.text.trim(),
        manufacturer:
            manufacturerController.text.trim(),
        model:
            modelController.text.trim(),
        year: int.parse(
          yearController.text.trim(),
        ),
        mileage: int.parse(
          mileageController.text.trim(),
        ),
      );

      final savedVehicle =
          await vehicleRepository.addVehicle(
        vehicle,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        savedVehicle,
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Supabase error while saving vehicle: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      final message =
          getDatabaseErrorMessage(
        error,
      );

      showMessage(
        message,
      );
    } catch (error) {
      debugPrint(
        'Unexpected error while saving vehicle: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשמור את הרכב. '
        'בדוק את החיבור לאינטרנט ונסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  String getDatabaseErrorMessage(
    PostgrestException error,
  ) {
    switch (error.code) {
      case '23505':
        return 'רכב עם מספר הרישוי הזה כבר קיים במערכת.';

      case '42501':
        return 'אין הרשאה לבצע את הפעולה. '
            'נסה להתחבר מחדש.';

      case '23514':
        return 'אחד מהפרטים שהוזנו אינו תקין. '
            'בדוק את הנתונים ונסה שוב.';

      case '23502':
        return 'חסר מידע נדרש לשמירת הרכב.';

      case '22P02':
        return 'אחד מהערכים שהוזנו אינו בפורמט תקין.';

      case '22003':
        return 'אחד מהמספרים שהוזנו גדול או קטן מדי.';

      case 'PGRST116':
        return 'הרכב נשמר, אך לא הצלחנו לטעון אותו מחדש. '
            'נסה לרענן את המסך.';

      default:
        return 'לא הצלחנו לשמור את הרכב. נסה שוב.';
    }
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  void dispose() {
    licenseController.dispose();
    manufacturerController.dispose();
    modelController.dispose();
    yearController.dispose();
    mileageController.dispose();

    super.dispose();
  }

  Widget buildHeaderIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color:
            AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              AppTheme.interactiveBorder,
        ),
      ),
      child: const Icon(
        Icons.directions_car_outlined,
        size: 34,
        color:
            AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentYear =
        DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'הוספת רכב',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment:
                    Alignment.center,
                child:
                    buildHeaderIcon(),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'פרטי הרכב',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme.textPrimary,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'הזן את הפרטים הבסיסיים של הרכב',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppTheme.textSecondary,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller:
                            licenseController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'מספר רכב',
                          prefixIcon: Icon(
                            Icons
                                .confirmation_number_outlined,
                          ),
                        ),
                        validator: (value) {
                          final license =
                              value?.trim() ??
                                  '';

                          if (license.isEmpty) {
                            return 'יש להזין מספר רכב';
                          }

                          if (!RegExp(
                            r'^\d+$',
                          ).hasMatch(
                            license,
                          )) {
                            return 'מספר הרכב צריך להכיל ספרות בלבד';
                          }

                          if (license.length <
                                  7 ||
                              license.length >
                                  8) {
                            return 'מספר רכב צריך להכיל 7 או 8 ספרות';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            manufacturerController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'יצרן',
                          hintText:
                              'לדוגמה: Mazda',
                          prefixIcon: Icon(
                            Icons
                                .factory_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'יש להזין יצרן';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            modelController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'דגם',
                          hintText:
                              'לדוגמה: 3',
                          prefixIcon: Icon(
                            Icons
                                .directions_car_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'יש להזין דגם';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            yearController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'שנת ייצור',
                          prefixIcon: Icon(
                            Icons
                                .calendar_month_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'יש להזין שנת ייצור';
                          }

                          final year =
                              int.tryParse(
                            value.trim(),
                          );

                          if (year == null) {
                            return 'יש להזין שנה תקינה';
                          }

                          if (year < 1900 ||
                              year >
                                  currentYear +
                                      1) {
                            return 'יש להזין שנת ייצור תקינה';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            mileageController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'קילומטראז׳ נוכחי',
                          suffixText:
                              'ק"מ',
                          prefixIcon: Icon(
                            Icons
                                .speed_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'יש להזין קילומטראז׳';
                          }

                          final mileage =
                              int.tryParse(
                            value.trim(),
                          );

                          if (mileage ==
                              null) {
                            return 'יש להזין קילומטראז׳ תקין';
                          }

                          if (mileage < 0) {
                            return 'קילומטראז׳ לא יכול להיות שלילי';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : saveVehicle,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .add_circle_outline,
                        ),
                  label: Text(
                    isSaving
                        ? 'שומר...'
                        : 'שמור רכב',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}