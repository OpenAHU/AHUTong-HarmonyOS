function normalizeVersion(value: string): Array<number> | undefined {
  const normalized = value.trim().replace(/^[vV]/, '');
  if (!/^\d+(\.\d+){0,3}$/.test(normalized)) return undefined;
  return normalized.split('.').map((part: string): number => Number(part));
}

export function isVersionNewer(remote: string, current: string): boolean {
  const remoteParts = normalizeVersion(remote);
  const currentParts = normalizeVersion(current);
  if (!remoteParts || !currentParts) return false;
  const length = Math.max(remoteParts.length, currentParts.length);
  for (let index = 0; index < length; index++) {
    const remotePart = remoteParts[index] ?? 0;
    const currentPart = currentParts[index] ?? 0;
    if (remotePart > currentPart) return true;
    if (remotePart < currentPart) return false;
  }
  return false;
}
