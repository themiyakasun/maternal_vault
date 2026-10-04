import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/delivery_plan.dart';
import '../../features/mother/domain/key_vitals.dart';
import '../../features/mother/domain/medical_history.dart';
import '../../features/mother/domain/obstetric_history.dart';
import 'maternal_risk_model.dart';
import 'mental_health_model.dart';
import 'model_notification.dart';
import 'preterm_risk_model.dart';

/// Combined evaluation result across all clinical AI models.
class ClinicalEvaluationResult {
  const ClinicalEvaluationResult({
    required this.maternalRisk,
    required this.pretermRisk,
    required this.mentalHealthRisk,
    required this.alerts,
  });

  final MaternalRiskResult maternalRisk;
  final PretermRiskResult pretermRisk;
  final MentalHealthRiskResult mentalHealthRisk;
  final List<ModelNotification> alerts;

  bool get hasAlerts => alerts.isNotEmpty;
}

/// Unified runner that executes all models in `lib/data/models`
/// to evaluate maternal and fetal wellbeing and emit clinical alerts.
class ClinicalModelEvaluator {
  ClinicalModelEvaluator({
    MaternalRiskModel? maternalRiskModel,
    PretermRiskModel? pretermRiskModel,
    MentalHealthModel? mentalHealthModel,
  })  : maternalRiskModel = maternalRiskModel ?? MaternalRiskModel(),
        pretermRiskModel = pretermRiskModel ?? PretermRiskModel(),
        mentalHealthModel = mentalHealthModel ?? MentalHealthModel();

  final MaternalRiskModel maternalRiskModel;
  final PretermRiskModel pretermRiskModel;
  final MentalHealthModel mentalHealthModel;

  /// Runs all 3 clinical models on the mother's record and collects any alerts.
  Future<ClinicalEvaluationResult> evaluateAll({
    required BasicProfile profile,
    required KeyVitals vitals,
    MedicalHistory? history,
    ObstetricHistory? obstetric,
    ClinicRecord? clinic,
    DeliveryPlan? deliveryPlan,
    int epdsScore = 0,
    int anxietyScore = 0,
    bool sleepDisturbed = false,
    bool reportedFatigue = false,
    List<int>? itemResponses,
  }) async {
    // 1. Maternal Health Risk (XGBoost)
    ClinicVisit? latestVisit;
    if (clinic != null && clinic.visits.isNotEmpty) {
      latestVisit = clinic.visits.reduce((a, b) => a.week >= b.week ? a : b);
    }
    final maternalRes = await maternalRiskModel.evaluateFromVitals(
      profile: profile,
      vitals: vitals,
      latestVisit: latestVisit,
      clinic: clinic,
      hasDiabetes: history?.hasPersonal(PersonalCondition.diabetes) == true,
    );

    // 2. Preterm Birth Risk (37-dim SINASC feature vector)
    final pretermRes = await pretermRiskModel.evaluate(
      profile: profile,
      vitals: vitals,
      obstetric: obstetric,
      clinic: clinic,
      medicalHistory: history,
    );

    // 3. Mental Health Wellbeing (245-dim clinical/psychosocial feature vector)
    final mentalRes = await mentalHealthModel.evaluate(
      epdsScore: epdsScore,
      anxietyScore: anxietyScore,
      sleepDisturbance: sleepDisturbed,
      reportedFatigue: reportedFatigue,
      itemResponses: itemResponses,
      profile: profile,
      medicalHistory: history,
      obstetric: obstetric,
    );

    // Collect all generated notifications
    final alerts = <ModelNotification>[];

    final matAlert = maternalRes.toNotification();
    if (matAlert != null) alerts.add(matAlert);

    final preAlert = pretermRes.toNotification();
    if (preAlert != null) alerts.add(preAlert);

    final menAlert = mentalRes.toNotification();
    if (menAlert != null) alerts.add(menAlert);

    return ClinicalEvaluationResult(
      maternalRisk: maternalRes,
      pretermRisk: pretermRes,
      mentalHealthRisk: mentalRes,
      alerts: alerts,
    );
  }

  void dispose() {
    maternalRiskModel.dispose();
    pretermRiskModel.dispose();
    mentalHealthModel.dispose();
  }
}
