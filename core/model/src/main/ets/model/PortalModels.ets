export interface LostFoundResponse {
  code: number;
  msg: string;
  object: LostFoundPage;
}

export interface LostFoundPage {
  pageNum: number;
  pageSize: number;
  size: number;
  startRow: number;
  endRow: number;
  total: number;
  pages: number;
  list: Array<LostFoundItem>;
}

export interface LostFoundItem {
  id: string;
  title: string;
  phone?: string;
  linkman?: string;
  createuser?: string;
  createtime?: string;
  state: number;
  audituser?: string;
  auditresult?: string;
  typeid?: string;
  campusid?: string;
  num1?: string;
  num2?: string;
  campusName?: string;
  audituserName?: string;
  imgs: Array<LostFoundImage>;
  pubuser?: LostFoundUser;
  lostType?: LostFoundType;
}

export interface LostFoundImage {
  imgId: string;
  imgPath: string;
  createtime?: string;
  lostid: string;
}

export interface LostFoundUser {
  idNumber?: string;
  unitUid?: string;
  unitName?: string;
  userName?: string;
  mobile?: string;
  headimgurl?: string;
}

export interface LostFoundType {
  typeId: string;
  typeName: string;
  typeState: string;
  createtime?: string;
  createuser?: string;
  updatetime?: string;
  updateuser?: string;
  remark?: string;
}

export interface LostFoundPublishRequest {
  imgs: Array<string>;
  linkman: string;
  phone: string;
  typeid: string;
  num1?: string;
  campusid: string;
  title: string;
  state: string;
  auditresult: number;
}
