export interface ScheduleWidgetCoordinator {
  update(): void;
}

class EmptyScheduleWidgetCoordinator implements ScheduleWidgetCoordinator {
  update(): void {}
}

export class ScheduleWidgetCoordinatorProvider {
  private static coordinator: ScheduleWidgetCoordinator = new EmptyScheduleWidgetCoordinator();
  static initialize(coordinator: ScheduleWidgetCoordinator): void { ScheduleWidgetCoordinatorProvider.coordinator = coordinator; }
  static get(): ScheduleWidgetCoordinator { return ScheduleWidgetCoordinatorProvider.coordinator; }
}
