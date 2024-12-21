part of 'authenticated_flow_coordinator.dart';

class AuthenticatedFlowState {
  const AuthenticatedFlowState({
    this.selectedTab = MainTab.books,
    this.isCreatingBook = false,
  });

  final MainTab selectedTab;
  final bool isCreatingBook;
}
