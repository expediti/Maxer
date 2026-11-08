import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/data/mock_opportunities_data.dart';

class SavedNotifier extends StateNotifier<List<Opportunity>> {
  SavedNotifier() : super([
    // Seed with two saved opportunities initially
    mockOpportunities[0], // UPSC CSE
    mockOpportunities[1], // ISRO Scientist
    mockOpportunities[3], // DRDO Scientist
  ]);

  bool isSaved(String opportunityId) {
    return state.any((opp) => opp.id == opportunityId);
  }

  void toggleSave(Opportunity opportunity) {
    if (isSaved(opportunity.id)) {
      state = state.where((opp) => opp.id != opportunity.id).toList();
    } else {
      state = [...state, opportunity];
    }
  }

  void remove(String opportunityId) {
    state = state.where((opp) => opp.id != opportunityId).toList();
  }

  void sortByDeadline() {
    final list = [...state]..sort((a, b) => a.applicationDeadline.compareTo(b.applicationDeadline));
    state = list;
  }

  void sortByLatest() {
    final list = [...state]..sort((a, b) => b.lastVerifiedAt.compareTo(a.lastVerifiedAt));
    state = list;
  }
}

final savedProvider = StateNotifierProvider<SavedNotifier, List<Opportunity>>((ref) {
  return SavedNotifier();
});
