export interface Tel {
  name: string;
  tel?: string;
  tel2?: string;
}

export interface Card {
  balance: number;
  transitionBalance: number;
}

export interface BathRoom {
  openStatus?: string;
  bathroom?: string;
}

export interface CampusDataItem {
  name: string;
  value: string;
}

export interface RoomSelectionInfo {
  campus?: CampusDataItem;
  building?: CampusDataItem;
  floor?: CampusDataItem;
  room?: CampusDataItem;
}

export interface ElectricityDepositHistoryItem {
  selection: RoomSelectionInfo;
  label: string;
  updatedAt: number;
}

export interface ElectricityChargeInfo {
  totalAmount: number;
  firstChargeDate: string;
}

export interface BathroomAccountData {
  projectId: number;
  projectName: string;
  accountId: number;
  telPhone: string;
  identifier?: string;
  sex: string;
  name?: string;
  statusId: number;
  accountMoney: number;
  accountGivenMoney: number;
  alias?: string;
  tags?: string;
  isCard: number;
  cardStatusId: number;
  isUseCode: number;
  cardPhysicalId?: string;
  tsmAbstract: string;
  myCustomInfo?: string;
  message?: string;
}

export interface BathroomTelInfo {
  msg: string;
  code: number;
  data?: BathroomAccountData;
  phone?: string;
  cashAmount?: string;
  giftAmount?: string;
  message?: string;
}

export interface CampusItem {
  id: string;
  campusName: string;
  campusOrder: number;
  createTime: string;
  createUser: string;
  updateTime?: string;
  updater?: string;
}
