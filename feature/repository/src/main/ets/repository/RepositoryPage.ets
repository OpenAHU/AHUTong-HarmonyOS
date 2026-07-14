import { AhuColors, AhuInsetCard, AhuLoading, AhuScreen, AhuTypography } from 'core_designsystem';
import { common } from '@kit.AbilityKit';
import { DownloadedFile, GitHubContentItem, REPOSITORIES, RepoConfig, RepositoryManager } from './RepositoryManager';
import { BackPressDispatcher } from 'core_common';

@Component
export struct RepositoryPage {
  @State selectedRepoId: string = '';
  @State items: Array<GitHubContentItem> = [];
  @State currentPath: string = '';
  @State pathStack: Array<string> = [];
  @State loading: boolean = false;
  @State refreshing: boolean = false;
  @State cached: boolean = false;
  @State cacheTime: number = 0;
  @State error: string = '';
  @State downloadingPath: string = '';
  @State downloadedPaths: Array<string> = [];
  @State showDownloads: boolean = false;
  @State downloads: Array<DownloadedFile> = [];
  @State managingDownloads: boolean = false;
  @State selectedDownloadPaths: Array<string> = [];
  @State pendingDeletePaths: Array<string> = [];
  private manager?: RepositoryManager;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    BackPressDispatcher.register('repository_page', () => this.handleBackPress());
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.manager = new RepositoryManager(context); this.refreshDownloads();
  }

  aboutToDisappear(): void { BackPressDispatcher.unregister('repository_page'); }

  private handleBackPress(): boolean {
    if (this.pendingDeletePaths.length > 0) { this.pendingDeletePaths = []; return true; }
    this.back();
    return true;
  }

  private refreshDownloads(): void {
    this.downloads = this.manager?.downloadedFiles() ?? [];
    this.downloadedPaths = this.downloads.map((item: DownloadedFile) => item.path);
    this.selectedDownloadPaths = this.selectedDownloadPaths.filter((path: string) =>
      this.downloadedPaths.includes(path));
  }

  private selectRepo(repoId: string): void {
    this.selectedRepoId = repoId; this.currentPath = ''; this.pathStack = []; this.items = [];
    this.load('', false);
  }

  private async load(path: string, force: boolean): Promise<void> {
    if (!this.manager || this.selectedRepoId.length === 0) return;
    this.error = '';
    const cache = force ? undefined : this.manager.cached(this.selectedRepoId, path);
    if (cache) {
      this.items = cache.items; this.currentPath = path; this.cached = true; this.cacheTime = cache.updateTime;
      this.refreshing = true;
    } else { this.loading = this.items.length === 0; this.refreshing = this.items.length > 0; }
    try {
      this.items = await this.manager.contents(this.selectedRepoId, path);
      this.currentPath = path; this.cached = false; this.cacheTime = Date.now();
    } catch (error) {
      if (!cache) this.error = (error as Error).message ?? '仓库内容加载失败';
    } finally { this.loading = false; this.refreshing = false; this.refreshDownloads(); }
  }

  private enter(item: GitHubContentItem): void {
    if (item.type !== 'dir' || this.loading) return;
    this.pathStack = this.pathStack.concat([this.currentPath]); this.load(item.path, false);
  }

  private back(): void {
    if (this.showDownloads && this.managingDownloads) {
      this.managingDownloads = false; this.selectedDownloadPaths = []; return;
    }
    if (this.showDownloads) { this.showDownloads = false; return; }
    if (this.pathStack.length > 0) {
      const parent = this.pathStack[this.pathStack.length - 1];
      this.pathStack = this.pathStack.slice(0, this.pathStack.length - 1); this.load(parent, false); return;
    }
    if (this.selectedRepoId.length > 0) {
      this.selectedRepoId = ''; this.currentPath = ''; this.items = []; this.error = ''; return;
    }
    this.onBack();
  }

  private async download(item: GitHubContentItem): Promise<void> {
    if (!this.manager || this.downloadingPath.length > 0) return;
    this.downloadingPath = item.path; this.error = '';
    try { await this.manager.download(this.selectedRepoId, item, (_: number) => {}); this.refreshDownloads(); }
    catch (error) { this.error = (error as Error).message ?? '下载失败'; }
    finally { this.downloadingPath = ''; }
  }

  private async openByPath(path: string): Promise<void> {
    const file = this.downloads.find((item: DownloadedFile) => item.path === path);
    if (!file || !this.manager) { this.error = '文件不存在，请重新下载'; return; }
    if (!await this.manager.open(file)) this.error = '没有可打开该文件的系统应用';
  }

  private delete(path: string): void {
    this.pendingDeletePaths = [path];
  }

  private toggleDownloadSelection(path: string): void {
    if (this.selectedDownloadPaths.includes(path)) {
      this.selectedDownloadPaths = this.selectedDownloadPaths.filter((selected: string) => selected !== path);
    } else {
      this.selectedDownloadPaths = this.selectedDownloadPaths.concat([path]);
    }
  }

  private toggleSelectAllDownloads(): void {
    this.selectedDownloadPaths = this.selectedDownloadPaths.length === this.downloads.length ? [] :
      this.downloads.map((file: DownloadedFile) => file.path);
  }

  private confirmBatchDelete(): void {
    if (this.selectedDownloadPaths.length > 0) this.pendingDeletePaths = this.selectedDownloadPaths.slice();
  }

  private performDelete(): void {
    this.pendingDeletePaths.forEach((path: string) => this.manager?.delete(path));
    this.pendingDeletePaths = []; this.selectedDownloadPaths = []; this.refreshDownloads();
  }

  private title(): string {
    if (this.showDownloads && this.managingDownloads) return `已选择 ${this.selectedDownloadPaths.length} 项`;
    if (this.showDownloads) return '已下载文件';
    if (this.selectedRepoId.length === 0) return '学习资料';
    if (this.currentPath.length > 0) return this.currentPath.substring(this.currentPath.lastIndexOf('/') + 1);
    return this.manager?.repo(this.selectedRepoId).name ?? '学习资料';
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes}B`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)}KB`;
    return `${(bytes / 1024 / 1024).toFixed(1)}MB`;
  }

  @Builder
  private repositorySelector() {
    Column({ space: 10 }) {
      Text('选择学院资料仓库').fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary)
        .width('100%').padding({ left: 4, bottom: 4 });
      ForEach(REPOSITORIES, (repo: RepoConfig) => {
        AhuInsetCard() {
          Row({ space: 14 }) {
            SymbolGlyph($r('sys.symbol.folder')).fontSize(30).fontColor(['#FFB300']);
            Column({ space: 3 }) {
              Text(repo.name).fontSize(AhuTypography.body).fontWeight(FontWeight.Medium).maxLines(1);
              Text(repo.repo).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary).maxLines(1);
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Text('›').fontSize(26).fontColor(AhuColors.onSurfaceSecondary);
          }.width('100%').onClick(() => this.selectRepo(repo.id));
        }
      }, (repo: RepoConfig) => repo.id);
    }.padding({ left: 16, right: 16 });
  }

  @Builder
  private fileRow(item: GitHubContentItem) {
    AhuInsetCard() {
      Row({ space: 12 }) {
        if (item.type === 'dir') {
          SymbolGlyph($r('sys.symbol.folder')).fontSize(30).fontColor(['#FFB300']);
        } else {
          Text(RepositoryManager.typeLabel(item.name)).fontSize(11).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .width(38).height(32).textAlign(TextAlign.Center).backgroundColor('#607D8B').borderRadius(7);
        }
        Column({ space: 3 }) {
          Text(item.name).fontSize(AhuTypography.body).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
          if (item.type !== 'dir' && item.size > 0) {
            Text(this.formatSize(item.size)).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        if (item.type === 'dir') {
          Text('›').fontSize(26).fontColor(AhuColors.onSurfaceSecondary);
        } else if (this.downloadingPath === item.path) {
          LoadingProgress().width(26).height(26).color(AhuColors.primaryAction);
        } else if (this.downloadedPaths.includes(item.path)) {
          Button('打开', { type: ButtonType.Capsule }).height(34).fontSize(AhuTypography.label)
            .onClick(() => this.openByPath(item.path));
        } else {
          Button('下载', { type: ButtonType.Capsule }).height(34).fontSize(AhuTypography.label)
            .onClick(() => this.download(item));
        }
      }.width('100%').onClick(() => { if (item.type === 'dir') this.enter(item); });
    }
  }

  @Builder
  private browser() {
    Column({ space: 10 }) {
      if (this.currentPath.length > 0) {
        Text(this.currentPath).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 4 });
      }
      if (this.refreshing) {
        Text(this.cached ? '正在同步 GitHub，当前显示缓存内容' : '正在同步 GitHub')
          .fontSize(AhuTypography.label).fontColor(AhuColors.primaryAction).width('100%');
      } else if (this.cached) {
        Text(`GitHub 暂不可用，显示 ${new Date(this.cacheTime).toLocaleString()} 的缓存`)
          .fontSize(AhuTypography.label).fontColor('#B26A00').width('100%');
      }
      if (this.loading) {
        AhuLoading({ message: '正在读取仓库' });
      } else if (this.items.length === 0 && this.error.length === 0) {
        Text('目录为空').width('100%').textAlign(TextAlign.Center).fontColor(AhuColors.onSurfaceSecondary).padding(48);
      } else {
        ForEach(this.items, (item: GitHubContentItem) => { this.fileRow(item); },
          (item: GitHubContentItem) => item.path);
      }
      if (this.selectedRepoId.length > 0 && this.items.length > 0) {
        Text('内容由对应 GitHub 社区仓库提供').fontSize(AhuTypography.label)
          .fontColor(AhuColors.onSurfaceSecondary).width('100%').textAlign(TextAlign.Center).padding(24);
      }
    }.padding({ left: 16, right: 16 });
  }

  @Builder
  private downloadedList() {
    Column({ space: 10 }) {
      if (this.downloads.length === 0) {
        Text('还没有下载文件').width('100%').textAlign(TextAlign.Center)
          .fontColor(AhuColors.onSurfaceSecondary).padding(48);
      }
      ForEach(this.downloads, (file: DownloadedFile) => {
        AhuInsetCard() {
          Row({ space: 12 }) {
            if (this.managingDownloads) {
              Text(this.selectedDownloadPaths.includes(file.path) ? '✓' : '')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                .width(24).height(24).textAlign(TextAlign.Center)
                .backgroundColor(this.selectedDownloadPaths.includes(file.path) ?
                  AhuColors.primaryAction : Color.Transparent)
                .border({ width: 1.5, color: this.selectedDownloadPaths.includes(file.path) ?
                  AhuColors.primaryAction : AhuColors.onSurfaceSecondary }).borderRadius(6);
            }
            Text(RepositoryManager.typeLabel(file.name)).fontSize(11).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .width(38).height(32).textAlign(TextAlign.Center).backgroundColor('#607D8B').borderRadius(7);
            Column({ space: 3 }) {
              Text(file.name).fontSize(AhuTypography.body).maxLines(2);
              Text(`${this.formatSize(file.size)} · ${file.path}`).fontSize(AhuTypography.label)
                .fontColor(AhuColors.onSurfaceSecondary).maxLines(1);
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            if (!this.managingDownloads) {
              Button('打开', { type: ButtonType.Capsule }).height(34).fontSize(AhuTypography.label)
                .onClick(() => this.openByPath(file.path));
              Button('删除', { type: ButtonType.Capsule }).height(34).fontSize(AhuTypography.label)
                .backgroundColor(AhuColors.error).onClick(() => this.delete(file.path));
            }
          }.width('100%').onClick(() => {
            if (this.managingDownloads) this.toggleDownloadSelection(file.path);
          });
        }
      }, (file: DownloadedFile) => file.path);
      if (this.managingDownloads && this.downloads.length > 0) {
        Row() {
          Button(this.selectedDownloadPaths.length === this.downloads.length ? '取消全选' : '全选',
            { type: ButtonType.Capsule })
            .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface)
            .onClick(() => this.toggleSelectAllDownloads());
          Blank();
          Button(`删除所选 (${this.selectedDownloadPaths.length})`, { type: ButtonType.Capsule })
            .enabled(this.selectedDownloadPaths.length > 0).backgroundColor(AhuColors.error)
            .onClick(() => this.confirmBatchDelete());
        }.width('100%').padding({ top: 4, bottom: 16 });
      }
    }.padding({ left: 16, right: 16 });
  }

  @Builder
  private deleteConfirmation() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#66000000')
        .onClick(() => { this.pendingDeletePaths = []; });
      Column({ space: 16 }) {
        Text(this.pendingDeletePaths.length > 1 ? '批量删除' : '删除文件')
          .fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
        Text(this.pendingDeletePaths.length > 1 ?
          `确定要删除选中的 ${this.pendingDeletePaths.length} 个文件吗？` : '确定要删除这个已下载文件吗？')
          .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary).width('100%');
        Row({ space: 12 }) {
          Button('取消', { type: ButtonType.Capsule }).layoutWeight(1)
            .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface)
            .onClick(() => { this.pendingDeletePaths = []; });
          Button('删除', { type: ButtonType.Capsule }).layoutWeight(1).backgroundColor(AhuColors.error)
            .onClick(() => this.performDelete());
        }.width('100%');
      }.width('86%').padding(22).backgroundColor(AhuColors.cardStrong).borderRadius(20);
    }.width('100%').height('100%');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
      Row() {
        Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.back());
        Text(this.title()).fontSize(AhuTypography.pageTitle).fontWeight(FontWeight.Bold)
          .fontColor(AhuColors.onSurface).layoutWeight(1).maxLines(1);
        if (!this.showDownloads && this.selectedRepoId.length > 0) {
          Button('刷新', { type: ButtonType.Capsule }).enabled(!this.loading && !this.refreshing)
            .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.load(this.currentPath, true));
        }
        if (this.showDownloads && this.downloads.length > 0) {
          Button(this.managingDownloads ? '完成' : '管理', { type: ButtonType.Capsule })
            .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => {
              this.managingDownloads = !this.managingDownloads;
              if (!this.managingDownloads) this.selectedDownloadPaths = [];
            });
        }
        Button(this.showDownloads ? '浏览' : `已下载 ${this.downloads.length}`, { type: ButtonType.Capsule })
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface)
          .onClick(() => {
            this.showDownloads = !this.showDownloads; this.managingDownloads = false;
            this.selectedDownloadPaths = []; this.refreshDownloads();
          });
      }.width('100%').padding({ left: 16, right: 12, top: 24 });
      if (this.error.length > 0) {
        Row() {
          Text(this.error).fontSize(AhuTypography.label).fontColor(AhuColors.error).layoutWeight(1);
          Button('关闭', { type: ButtonType.Capsule }).height(32).onClick(() => { this.error = ''; });
        }.margin({ left: 16, right: 16 }).padding(12).backgroundColor('#22F44336').borderRadius(12);
      }
      if (this.showDownloads) this.downloadedList();
      else if (this.selectedRepoId.length === 0) this.repositorySelector();
      else this.browser();
      }
      if (this.pendingDeletePaths.length > 0) this.deleteConfirmation();
    }.width('100%').height('100%');
  }
}
