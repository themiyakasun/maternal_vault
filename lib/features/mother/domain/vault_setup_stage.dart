/// The steps the app walks through while standing up a new mother's vault.
///
/// Declaration order is run order — [VaultSetupScreen] iterates
/// [VaultSetupStage.values] straight through.
enum VaultSetupStage { creatingRecord, encrypting, finishing }

/// Where a [VaultSetupStage] stands in that run.
enum StageStatus { done, active, pending }
