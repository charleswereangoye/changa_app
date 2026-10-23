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
  });

  final ThemeMode themeMode;
  final bool notifyNudges;
  final bool notifyChores;
  final SettlementMethod defaultSettlementMethod;
  final SplitType defaultSplitType;

  /// False until the saved values have been read from the phone.
  final bool isLoaded;

  PreferencesState copyWith({
    ThemeMode? themeMode,
    bool? notifyNudges,
    bool? notifyChores,
    SettlementMethod? defaultSettlementMethod,
    SplitType? defaultSplitType,
    bool? isLoaded,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      notifyNudges: notifyNudges ?? this.notifyNudges,
      notifyChores: notifyChores ?? this.notifyChores,
      defaultSettlementMethod:
          defaultSettlementMethod ?? this.defaultSettlementMethod,
      defaultSplitType: defaultSplitType ?? this.defaultSplitType,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object> get props => [
    themeMode,
    notifyNudges,
    notifyChores,
    defaultSettlementMethod,
    defaultSplitType,
    isLoaded,
  ];
}
