import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PreferencesState extends Equatable {
  const PreferencesState({
    this.themeMode = ThemeMode.system,
    this.notifyNudges = true,
    this.notifyChores = true,
    this.defaultSettlementMethod = SettlementMethod.momo,
    this.defaultSplitType = SplitType.equal,
    this.isLoaded = false,
    this.saveError,
  });

  final ThemeMode themeMode;
  final bool notifyNudges;
  final bool notifyChores;
  final SettlementMethod defaultSettlementMethod;
  final SplitType defaultSplitType;

  /// False until the saved values have been read from the phone.
  final bool isLoaded;

  /// Set when a change could not be saved, so the screen can say so.
  final String? saveError;

  PreferencesState copyWith({
    ThemeMode? themeMode,
    bool? notifyNudges,
    bool? notifyChores,
    SettlementMethod? defaultSettlementMethod,
    SplitType? defaultSplitType,
    bool? isLoaded,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      notifyNudges: notifyNudges ?? this.notifyNudges,
      notifyChores: notifyChores ?? this.notifyChores,
      defaultSettlementMethod:
          defaultSettlementMethod ?? this.defaultSettlementMethod,
      defaultSplitType: defaultSplitType ?? this.defaultSplitType,
      isLoaded: isLoaded ?? this.isLoaded,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    notifyNudges,
    notifyChores,
    defaultSettlementMethod,
    defaultSplitType,
    isLoaded,
    saveError,
  ];
}
