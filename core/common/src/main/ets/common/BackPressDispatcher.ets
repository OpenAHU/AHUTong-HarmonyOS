export type BackPressHandler = () => boolean;

interface BackPressEntry {
  id: string;
  handler: BackPressHandler;
}

export class BackPressDispatcher {
  private static handlers: Array<BackPressEntry> = [];

  static register(id: string, handler: BackPressHandler): void {
    BackPressDispatcher.unregister(id);
    BackPressDispatcher.handlers.push({ id: id, handler: handler });
  }

  static unregister(id: string): void {
    BackPressDispatcher.handlers = BackPressDispatcher.handlers.filter((entry: BackPressEntry) => entry.id !== id);
  }

  static handle(): boolean {
    const handlers = BackPressDispatcher.handlers.slice().reverse();
    for (let index = 0; index < handlers.length; index++) {
      try {
        if (handlers[index].handler()) return true;
      } catch (_) {}
    }
    return false;
  }
}
