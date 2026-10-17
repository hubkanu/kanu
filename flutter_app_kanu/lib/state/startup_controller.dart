import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Préférences de premier lancement : onboarding et consentement cookies.
class StartupState extends Equatable {
  const StartupState({
    required this.onboardingDone,
    required this.consentGiven,
  });

  final bool onboardingDone;
  final bool consentGiven;

  StartupState copyWith({bool? onboardingDone, bool? consentGiven}) {
    return StartupState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      consentGiven: consentGiven ?? this.consentGiven,
    );
  }

  @override
  List<Object?> get props => [onboardingDone, consentGiven];
}

class StartupController extends Notifier<StartupState> {
  @override
  StartupState build() {
    final prefs = ref.read(preferencesServiceProvider);
    return StartupState(
      onboardingDone: prefs.onboardingDone,
      consentGiven: prefs.consentGiven,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.onboardingDone) return;
    state = state.copyWith(onboardingDone: true);
    await ref.read(preferencesServiceProvider).setOnboardingDone(true);
  }

  Future<void> giveConsent() async {
    if (state.consentGiven) return;
    state = state.copyWith(consentGiven: true);
    await ref.read(preferencesServiceProvider).setConsentGiven(true);
  }
}

final startupControllerProvider =
    NotifierProvider<StartupController, StartupState>(StartupController.new);
