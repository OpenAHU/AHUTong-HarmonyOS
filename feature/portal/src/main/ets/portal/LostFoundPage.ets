import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { CampusItem, LostFoundItem, LostFoundPublishRequest, LostFoundType } from 'core_model';
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
  @State showPublish: boolean = false;
  @State campuses: Array<CampusItem> = [];
  @State types: Array<LostFoundType> = [];
  @State publishCampusId: string = '';
  @State publishTypeId: string = '';
  @State publishState: string = '1';
  @State linkman: string = '';
  @State phone: string = '';
  @State title: string = '';
  @State num1: string = '';
  @State publishing: boolean = false;
  @State publishError: string = '';
  @State showMyPosts: boolean = false;
  @State deleteTarget?: LostFoundItem = undefined;
  @State deleting: boolean = false;
  @State deleteError: string = '';
  onBack: () => void = () => {};

  aboutToAppear(): void { this.load(true); this.loadPublishOptions(); }

  private async loadPublishOptions(): Promise<void> {
    const campusResult = await this.repository.getCampuses();
    if (campusResult.isSuccess && campusResult.data) this.campuses = campusResult.data;
    const typeResult = await this.repository.getTypes();
    if (typeResult.isSuccess && typeResult.data) this.types = typeResult.data;
  }

  private async publish(): Promise<void> {
    if (this.linkman.trim().length === 0 || this.phone.trim().length === 0 || this.title.trim().length === 0 ||
      this.publishCampusId.length === 0 || this.publishTypeId.length === 0) {
      this.publishError = '请填写联系人、联系电话和描述，并选择校区与物品类型'; return;
    }
    this.publishing = true; this.publishError = '';
    const request: LostFoundPublishRequest = { imgs: [], linkman: this.linkman.trim(), phone: this.phone.trim(),
      title: this.title.trim(), num1: this.num1.trim(), campusid: this.publishCampusId,
      typeid: this.publishTypeId, state: this.publishState, auditresult: 1 };
    const result = await this.repository.publish(request);
    this.publishing = false;
    if (!result.isSuccess) { this.publishError = result.error?.message ?? '发布失败'; return; }
    this.showPublish = false; this.linkman = ''; this.phone = ''; this.title = ''; this.num1 = '';
    this.state = Number(this.publishState); await this.load(true);
  }

  private myPosts(): Array<LostFoundItem> {
    const userId = this.repository.currentUserId();
    return this.items.filter((item: LostFoundItem) => item.pubuser?.idNumber === userId);
  }

  private async confirmDelete(): Promise<void> {
    if (!this.deleteTarget || this.deleting) return;
    this.deleting = true; this.deleteError = '';
    const id = this.deleteTarget.id;
    const result = await this.repository.delete(id);
    this.deleting = false;
    if (!result.isSuccess) { this.deleteError = result.error?.message ?? '删除失败'; return; }
    this.items = this.items.filter((item: LostFoundItem) => item.id !== id);
    this.deleteTarget = undefined;
  }

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

  @Builder
  private publishSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('发布信息').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button('×', { type: ButtonType.Circle }).width(38).height(38).backgroundColor(AhuColors.chipUnselected)
          .fontColor(AhuColors.onSurface).onClick(() => this.showPublish = false);
      }.width('100%');
      Text('当前版本与 Android 一致，暂不支持上传图片。').fontSize(AhuTypography.label)
        .fontColor(AhuColors.onSurfaceSecondary);
      TextInput({ text: this.linkman, placeholder: '联系人（必填）' }).onChange((value: string) => this.linkman = value);
      TextInput({ text: this.phone, placeholder: '联系电话（必填）' }).type(InputType.PhoneNumber)
        .onChange((value: string) => this.phone = value);
      TextInput({ text: this.title, placeholder: '物品描述（必填）' }).onChange((value: string) => this.title = value);
      TextInput({ text: this.num1, placeholder: '编号/补充说明（选填）' }).onChange((value: string) => this.num1 = value);
      Text('选择校区').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
      Scroll() { Row({ space: 8 }) { ForEach(this.campuses, (item: CampusItem) => {
        Button(item.campusName, { type: ButtonType.Capsule })
          .fontColor(this.publishCampusId === item.id ? AhuColors.onPrimaryAction : AhuColors.onSurface)
          .backgroundColor(this.publishCampusId === item.id ? AhuColors.primaryAction : AhuColors.chipUnselected)
          .onClick(() => this.publishCampusId = item.id);
      }, (item: CampusItem) => item.id); } }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
      Text('选择物品类型').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
      Scroll() { Row({ space: 8 }) { ForEach(this.types, (item: LostFoundType) => {
        Button(item.typeName, { type: ButtonType.Capsule })
          .fontColor(this.publishTypeId === item.typeId ? AhuColors.onPrimaryAction : AhuColors.onSurface)
          .backgroundColor(this.publishTypeId === item.typeId ? AhuColors.primaryAction : AhuColors.chipUnselected)
          .onClick(() => this.publishTypeId = item.typeId);
      }, (item: LostFoundType) => item.typeId); } }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
      Text('信息类型').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
      Row({ space: 8 }) {
        Button('失物招领', { type: ButtonType.Capsule }).layoutWeight(1)
          .fontColor(this.publishState === '1' ? AhuColors.onPrimaryAction : AhuColors.onSurface)
          .backgroundColor(this.publishState === '1' ? AhuColors.primaryAction : AhuColors.chipUnselected)
          .onClick(() => this.publishState = '1');
        Button('寻物启事', { type: ButtonType.Capsule }).layoutWeight(1)
          .fontColor(this.publishState === '2' ? AhuColors.onPrimaryAction : AhuColors.onSurface)
          .backgroundColor(this.publishState === '2' ? AhuColors.primaryAction : AhuColors.chipUnselected)
          .onClick(() => this.publishState = '2');
      }.width('100%');
      if (this.publishError.length > 0) Text(this.publishError).fontSize(AhuTypography.label).fontColor(AhuColors.error);
      Button(this.publishing ? '发布中…' : '发布', { type: ButtonType.Capsule }).width('100%').enabled(!this.publishing)
        .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction).onClick(() => this.publish());
    }.width('92%').height('88%').padding(22).backgroundColor(AhuColors.card).borderRadius(28)
      .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private myPostsSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('管理我的帖子').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button('×', { type: ButtonType.Circle }).width(38).height(38).backgroundColor(AhuColors.chipUnselected)
          .fontColor(AhuColors.onSurface).onClick(() => this.showMyPosts = false);
      }.width('100%');
      if (this.myPosts().length === 0) {
        Text('当前列表中没有由你发布的帖子').fontColor(AhuColors.onSurfaceSecondary).padding({ top: 32, bottom: 32 });
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.myPosts(), (item: LostFoundItem) => {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text(item.title).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).maxLines(2);
                  Text(item.createtime ?? '').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Button('删除', { type: ButtonType.Capsule }).fontColor(AhuColors.error)
                  .backgroundColor(AhuColors.chipUnselected).onClick(() => { this.deleteError = ''; this.deleteTarget = item; });
              }.width('100%').padding(12).backgroundColor(AhuColors.cardStrong).borderRadius(16);
            }, (item: LostFoundItem) => item.id);
          }.width('100%');
        }.layoutWeight(1).scrollBar(BarState.Auto);
      }
    }.width('92%').height('76%').padding(22).backgroundColor(AhuColors.card).borderRadius(28)
      .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private deleteConfirmSheet(item: LostFoundItem) {
    Column({ space: 18 }) {
      Text('确认删除').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
      Text(`确定删除“${item.title}”吗？删除后无法恢复。`).fontSize(AhuTypography.body);
      if (this.deleteError.length > 0) Text(this.deleteError).fontSize(AhuTypography.label).fontColor(AhuColors.error);
      Row({ space: 10 }) {
        Button('取消', { type: ButtonType.Capsule }).layoutWeight(1).enabled(!this.deleting)
          .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
          .onClick(() => this.deleteTarget = undefined);
        Button(this.deleting ? '删除中…' : '删除', { type: ButtonType.Capsule }).layoutWeight(1).enabled(!this.deleting)
          .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.error).onClick(() => this.confirmDelete());
      }.width('100%');
    }.width('86%').padding(24).backgroundColor(AhuColors.card).borderRadius(28).alignItems(HorizontalAlign.Start);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 12 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
          Text('失物招领').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
          Button('发布', { type: ButtonType.Capsule }).backgroundColor(AhuColors.primaryAction)
            .fontColor(AhuColors.onPrimaryAction).onClick(() => this.showPublish = true);
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
          Button('我的', { type: ButtonType.Capsule }).fontColor(AhuColors.onSurface)
            .backgroundColor(AhuColors.chipUnselected).onClick(() => this.showMyPosts = true);
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
      if (this.showPublish) {
        Column() { this.publishSheet(); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
      if (this.showMyPosts) {
        Column() { this.myPostsSheet(); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
      if (this.deleteTarget) {
        Column() { this.deleteConfirmSheet(this.deleteTarget); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#88000000');
      }
    }.width('100%').height('100%');
  }
}
