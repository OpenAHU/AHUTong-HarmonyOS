import { AppResult } from 'core_common';
import { AhuPreferences } from 'core_datastore';
import { AhuHttpClient } from 'core_network';
import { common } from '@kit.AbilityKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

export interface GitHubContentItem {
  name: string;
  path: string;
  type: string;
  size: number;
  download_url?: string;
  html_url?: string;
}

export interface RepoConfig {
  id: string;
  name: string;
  owner: string;
  repo: string;
  branch: string;
}

export interface DownloadedFile {
  name: string;
  path: string;
  localPath: string;
  size: number;
  downloadTime: number;
}

interface DownloadRecord { repoId: string; name: string; path: string; localPath: string; downloadTime: number; }
interface ContentCache { items: Array<GitHubContentItem>; updateTime: number; }

export const REPOSITORIES: Array<RepoConfig> = [
  { id: 'cs', name: '计算机科学与技术学院', owner: 'Kaltsit-cell', repo: 'AHU-CS-Repository', branch: 'master' },
  { id: 'ai', name: '人工智能学院', owner: 'DylanAo', repo: 'AHU-AI-Repository', branch: 'main' },
  { id: 'ic', name: '集成电路学院', owner: 'Tonyseth', repo: 'AHU-IC-Design-personal-Repository', branch: 'main' },
  { id: 'ee', name: '电子信息工程学院', owner: 'HarryWeasley3', repo: 'AHU-EE-Repository', branch: 'main' },
  { id: 'internet', name: '互联网学院', owner: 'Zeraora-807', repo: 'AHU-Internet-Exams-Archive', branch: 'main' },
  { id: 'sbi', name: '石溪学院', owner: 'UponNoise', repo: 'AHU_SBI_DMT', branch: 'main' }
];

export class RepositoryManager {
  private readonly client: AhuHttpClient = new AhuHttpClient();
  private readonly context: common.UIAbilityContext;
  private static readonly RECORD_KEY: string = 'repository:downloads';

  constructor(context: common.UIAbilityContext) { this.context = context; }

  repo(id: string): RepoConfig { return REPOSITORIES.find((item: RepoConfig) => item.id === id) ?? REPOSITORIES[0]; }
  repoUrl(id: string): string { const item = this.repo(id); return `https://github.com/${item.owner}/${item.repo}`; }

  private encodePath(path: string): string {
    return path.split('/').filter((part: string) => part.length > 0).map((part: string) => encodeURIComponent(part)).join('/');
  }

  private cacheKey(repoId: string, path: string): string {
    return `repository:content:${repoId}:${encodeURIComponent(path)}`;
  }

  cached(repoId: string, path: string): ContentCache | undefined {
    const raw = AhuPreferences.getString(this.cacheKey(repoId, path));
    if (raw.length === 0) return undefined;
    try { return JSON.parse(raw) as ContentCache; } catch (_) { return undefined; }
  }

  async contents(repoId: string, path: string): Promise<Array<GitHubContentItem>> {
    const repo = this.repo(repoId);
    const suffix = this.encodePath(path);
    const url = `https://api.github.com/repos/${repo.owner}/${repo.repo}/contents/${suffix}?ref=${repo.branch}`;
    const result: AppResult<Array<GitHubContentItem>> = await this.client.request<Array<GitHubContentItem>>({
      url: url, headers: { 'Accept': 'application/vnd.github+json', 'User-Agent': 'AHUTong-HarmonyOS' }
    });
    if (!result.isSuccess || !result.data || !Array.isArray(result.data)) throw new Error(result.error?.message ?? '仓库内容加载失败');
    const items = result.data.sort((left: GitHubContentItem, right: GitHubContentItem) => {
      if (left.type !== right.type) return left.type === 'dir' ? -1 : 1;
      return left.name.localeCompare(right.name);
    });
    AhuPreferences.putString(this.cacheKey(repoId, path), JSON.stringify({ items: items, updateTime: Date.now() }));
    return items;
  }

  private records(): Array<DownloadRecord> {
    const raw = AhuPreferences.getString(RepositoryManager.RECORD_KEY, '[]');
    try { return JSON.parse(raw) as Array<DownloadRecord>; } catch (_) { return []; }
  }

  private saveRecords(records: Array<DownloadRecord>): void {
    AhuPreferences.putString(RepositoryManager.RECORD_KEY, JSON.stringify(records));
  }

  private downloadDir(): string {
    const dir = `${this.context.filesDir}/repository`;
    try { fs.mkdirSync(dir); } catch (_) {}
    return dir;
  }

  private fileName(path: string): string {
    const source = path.substring(path.lastIndexOf('/') + 1) || 'repository_file';
    const safe = source.replace(/[^A-Za-z0-9._\u4e00-\u9fa5-]/g, '_');
    let hash = 0;
    for (let index = 0; index < path.length; index++) hash = ((hash << 5) - hash + path.charCodeAt(index)) | 0;
    const dot = safe.lastIndexOf('.');
    return dot > 0 ? `${safe.substring(0, dot)}_${Math.abs(hash).toString(16)}${safe.substring(dot)}` : `${safe}_${Math.abs(hash).toString(16)}`;
  }

  async download(repoId: string, item: GitHubContentItem, onProgress: (value: number) => void): Promise<DownloadedFile> {
    const repo = this.repo(repoId);
    const encoded = this.encodePath(item.path);
    const urls = [`https://cdn.jsdelivr.net/gh/${repo.owner}/${repo.repo}@${repo.branch}/${encoded}`,
      `https://raw.githubusercontent.com/${repo.owner}/${repo.repo}/${repo.branch}/${encoded}`];
    let lastError = '下载失败';
    for (let index = 0; index < urls.length; index++) {
      const request = http.createHttp();
      try {
        const response = await request.request(urls[index], { method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.ARRAY_BUFFER, connectTimeout: 10_000, readTimeout: 60_000 });
        if ((response.responseCode as number) < 200 || (response.responseCode as number) >= 300) {
          lastError = `下载失败（${response.responseCode}）`; continue;
        }
        const buffer = response.result as ArrayBuffer;
        const localPath = `${this.downloadDir()}/${this.fileName(item.path)}`;
        const file = fs.openSync(localPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        try { fs.writeSync(file.fd, buffer); } finally { fs.closeSync(file); }
        onProgress(1);
        const record: DownloadRecord = { repoId: repoId, name: item.name, path: item.path,
          localPath: localPath, downloadTime: Date.now() };
        const records = this.records().filter((saved: DownloadRecord) => saved.path !== item.path);
        records.push(record); this.saveRecords(records);
        return { name: item.name, path: item.path, localPath: localPath, size: buffer.byteLength,
          downloadTime: record.downloadTime };
      } catch (error) { lastError = (error as Error).message ?? '下载失败'; }
      finally { request.destroy(); }
    }
    throw new Error(lastError);
  }

  downloadedFiles(): Array<DownloadedFile> {
    const valid: Array<DownloadRecord> = [];
    const files: Array<DownloadedFile> = [];
    this.records().forEach((record: DownloadRecord) => {
      try {
        const stat = fs.statSync(record.localPath); valid.push(record);
        files.push({ name: record.name, path: record.path, localPath: record.localPath,
          size: stat.size, downloadTime: record.downloadTime });
      } catch (_) {}
    });
    if (valid.length !== this.records().length) this.saveRecords(valid);
    return files.sort((a: DownloadedFile, b: DownloadedFile) => b.downloadTime - a.downloadTime);
  }

  isDownloaded(path: string): boolean { return this.downloadedFiles().some((item: DownloadedFile) => item.path === path); }

  delete(path: string): void {
    const record = this.records().find((item: DownloadRecord) => item.path === path);
    if (record) { try { fs.unlinkSync(record.localPath); } catch (_) {} }
    this.saveRecords(this.records().filter((item: DownloadRecord) => item.path !== path));
  }

  async open(file: DownloadedFile): Promise<boolean> {
    try {
      await this.context.startAbility({ action: 'ohos.want.action.viewData', uri: fileUri.getUriFromPath(file.localPath),
        type: RepositoryManager.mimeType(file.name), flags: 1 });
      return true;
    } catch (_) { return false; }
  }

  static typeLabel(name: string): string {
    const lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'DOC';
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return 'PPT';
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return 'XLS';
    if (/\.(png|jpg|jpeg|gif|webp|bmp)$/.test(lower)) return 'IMG';
    if (/\.(zip|rar|7z)$/.test(lower)) return 'ZIP';
    return lower.endsWith('.md') ? 'MD' : lower.endsWith('.txt') ? 'TXT' : '?';
  }

  static mimeType(name: string): string {
    const label = RepositoryManager.typeLabel(name);
    if (label === 'PDF') return 'application/pdf';
    if (label === 'DOC') return name.toLowerCase().endsWith('docx') ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : 'application/msword';
    if (label === 'PPT') return 'application/vnd.ms-powerpoint';
    if (label === 'XLS') return 'application/vnd.ms-excel';
    if (label === 'IMG') return 'image/*';
    if (label === 'TXT' || label === 'MD') return 'text/plain';
    return '*/*';
  }
}
