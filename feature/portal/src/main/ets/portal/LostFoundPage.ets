import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { LostFoundItem } from 'core_model';
import { LostFoundRepository, LostFoundRepositoryProvider } from 'data_portal';

@Component
export struct LostFoundPage {
  private readonly repository: LostFoundRepository = LostFoundRepositoryProvider.get();
  @State state: number = 1;
  @State page: number = 1;
  @State pages: number = 1;
  @State items: Array<LostFoundItem> = [];
  @State loading: boolean = true;
  @State loadingMore: boolean = false;
  @State error: string = '';
  @State selected?: LostFoundItem = undefined;
  onBack: () => void = () => {};

  aboutToAppear(): void { this.load(true); }

  private async load(refresh: boolean): Promise<void> {
    if (refresh) { this.loading = true; this.page = 1; } else this.loadingMore = true;
    this.error = '';
    const target = refresh ? 1 : this.page + 1;
    const response = await this.repository.getList(target, 20, this.state);
    if (response.isSuccess && response.data) {
      this.items = refresh ? response.data.object.list : this.items.concat(response.data.object.list);
      this.page = response.data.object.pageNum; this.pages = Math.max(1, response.data.object.pages);
    } else this.error = response.error?.message ?? '失物招领加载失败';
    this.loading = false; this.loadingMore = false;
  }

  private switchState(value: number): void {
    if (this.state === value) return;
    this.state = value; this.items = []; this.load(true);
  }

  private imageUrl(item: LostFoundItem): string {
    const path = item.imgs.length > 0 ? item.imgs[0].imgPath : '';
    if (path.length === 0 || /^https?:\/\//.test(path)) return path;
    return `https://adwmh.ahu.edu.cn${path.startsWith('/') ? '' : '/'}${path}`;
  }

  @Builder
  private detail(item: LostFoundItem) {
    Column({ space: 14 }) {
      Row() {
        Text(item.title).fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button('×', { type: ButtonType.Circle }).width(38).height(38)
          .backgroundColor(AhuColors.chipUnselected).fontColor(AhuColors.onSurface).onClick(() => this.selected = undefined);
      }.width('100%');
      if (this.imageUrl(item).length > 0) Image(this.imageUrl(item)).width('100%').height(220)
        .objectFit(ImageFit.Contain).backgroundColor(AhuColors.cardStrong).borderRadius(18);
      Text(`${item.state === 1 ? '招领物品' : '寻找物品'} · ${item.lostType?.typeName ?? '未分类'}`)
        .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
      Text(`校区：${item.campusName ?? '未填写'}`).fontSize(AhuTypography.body);
      Text(`数量/说明：${item.num1 ?? '未填写'}`).fontSize(AhuTypography.body);
      Text(`联系人：${item.linkman ?? item.pubuser?.userName ?? '未填写'}`).fontSize(AhuTypography.body);
      Text(`电话：${item.phone ?? item.pubuser?.mobile ?? '未填写'}`).fontSize(AhuTypography.body);
      Text(`发布时间：${item.createtime ?? '未知'}`).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
    }.width('90%').height('82%').padding(24).backgroundColor(AhuColors.card).borderRadius(28)
      .alignItems(HorizontalAlign.Start);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 12 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
          Text('失物招领').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
          Button('刷新', { type: ButtonType.Capsule }).enabled(!this.loading).backgroundColor(AhuColors.card)
            .fontColor(AhuColors.onSurface).onClick(() => this.load(true));
        }.width('100%').padding({ left: 16, right: 16, top: 20 });
        Row({ space: 8 }) {
          Button('失物招领', { type: ButtonType.Capsule }).layoutWeight(1)
            .fontColor(this.state === 1 ? AhuColors.onPrimaryAction : AhuColors.onSurface)
            .backgroundColor(this.state === 1 ? AhuColors.primaryAction : AhuColors.chipUnselected)
            .onClick(() => this.switchState(1));
          Button('寻物启事', { type: ButtonType.Capsule }).layoutWeight(1)
            .fontColor(this.state === 2 ? AhuColors.onPrimaryAction : AhuColors.onSurface)
            .backgroundColor(this.state === 2 ? AhuColors.primaryAction : AhuColors.chipUnselected)
            .onClick(() => this.switchState(2));
        }.width('100%').padding({ left: 16, right: 16 });
        if (this.loading) {
          Column({ space: 12 }) { LoadingProgress().width(48).height(48).color(AhuColors.primaryAction); Text('正在加载…'); }
            .width('100%').padding(48);
        } else if (this.items.length === 0) {
          AhuInsetCard() { Text(this.error.length > 0 ? this.error : '暂无内容').fontColor(AhuColors.onSurfaceSecondary); }
        } else {
          ForEach(this.items, (item: LostFoundItem) => {
            AhuInsetCard() {
              Row({ space: 14 }) {
                if (this.imageUrl(item).length > 0) Image(this.imageUrl(item)).width(88).height(88)
                  .objectFit(ImageFit.Cover).borderRadius(16).backgroundColor(AhuColors.cardStrong);
                Column({ space: 7 }) {
                  Text(item.title).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).maxLines(2);
                  Text(`${item.lostType?.typeName ?? '未分类'} · ${item.campusName ?? '未知校区'}`)
                    .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary).maxLines(1);
                  Text(item.createtime ?? '').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              }.width('100%').onClick(() => this.selected = item);
            }
          }, (item: LostFoundItem) => item.id);
          if (this.page < this.pages) Button(this.loadingMore ? '加载中…' : '加载更多', { type: ButtonType.Capsule })
            .enabled(!this.loadingMore).alignSelf(ItemAlign.Center).backgroundColor(AhuColors.chipUnselected)
            .fontColor(AhuColors.onSurface).onClick(() => this.load(false));
        }
        if (this.error.length > 0 && this.items.length > 0) Text(this.error).fontColor(AhuColors.error).padding(16);
      }
      if (this.selected) {
        Column() { this.detail(this.selected); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
    }.width('100%').height('100%');
  }
}
