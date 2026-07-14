export interface ScheduleReminderCoordinator {
  reschedule(): void;
}

class EmptyScheduleReminderCoordinator implements ScheduleReminderCoordinator {
  reschedule(): void {}
}

export class ScheduleReminderCoordinatorProvider {
  private static coordinator: ScheduleReminderCoordinator = new EmptyScheduleReminderCoordinator();

  static initialize(coordinator: ScheduleReminderCoordinator): void {
    ScheduleReminderCoordinatorProvider.coordinator = coordinator;
  }

  static get(): ScheduleReminderCoordinator {
    return ScheduleReminderCoordinatorProvider.coordinator;
  }
}
