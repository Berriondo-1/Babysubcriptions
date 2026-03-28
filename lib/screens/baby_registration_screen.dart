import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/providers/baby_provider.dart';
import 'package:baby_subscription/widgets/empty_state_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BabyRegistrationScreen extends StatefulWidget {
  const BabyRegistrationScreen({super.key});

  @override
  State<BabyRegistrationScreen> createState() => _BabyRegistrationScreenState();
}

class _BabyRegistrationScreenState extends State<BabyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _stages = ['Recien nacido', 'Lactante', 'Gateo'];

  DateTime? _selectedDate;
  String? _selectedStage;
  bool _showDateError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BabyProvider>();
      provider.loadBabyProfile().then((_) {
        final profile = provider.babyProfile;
        if (profile == null || !mounted) {
          return;
        }

        _nameController.text = profile.name;
        _selectedDate = profile.birthDate;
        _selectedStage = profile.stage;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _showDateError = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || _selectedDate == null) {
      setState(() {
        _showDateError = _selectedDate == null;
      });
      return;
    }

    final profile = BabyProfile(
      name: _nameController.text.trim(),
      birthDate: _selectedDate!,
      stage: _selectedStage!,
    );

    await context.read<BabyProvider>().saveBabyProfile(profile);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos del bebe guardados localmente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BabyProvider>();
    final profile = provider.babyProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BabySubscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F2FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pequeno avance funcional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este avance solo incluye el registro basico del bebe y su guardado local en SQLite.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5E6B7A),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulario basico',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            errorText: _showDateError && _selectedDate == null
                                ? 'Selecciona una fecha.'
                                : null,
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy')
                                    .format(_selectedDate!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedStage,
                        decoration: const InputDecoration(
                          labelText: 'Etapa',
                        ),
                        items: _stages
                            .map(
                              (stage) => DropdownMenuItem(
                                value: stage,
                                child: Text(stage),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStage = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona una etapa.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: provider.isLoading ? null : _saveProfile,
                          child: const Text('Guardar registro'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Registro guardado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (profile == null)
              const EmptyStateCard(
                message: 'Todavia no se ha registrado informacion del bebe.',
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nacimiento: ${DateFormat('dd/MM/yyyy').format(profile.birthDate)}',
                      ),
                      const SizedBox(height: 4),
                      Text('Etapa: ${profile.stage}'),
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
