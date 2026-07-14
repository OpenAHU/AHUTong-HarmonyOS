import { CampusNativeGateway } from 'core_sdk_api';
import { UnavailableCampusGateway } from './UnavailableCampusGateway';

export class CampusGatewayProvider {
  private static gateway: CampusNativeGateway = new UnavailableCampusGateway();

  static initialize(gateway?: CampusNativeGateway): void {
    CampusGatewayProvider.gateway = gateway ?? new UnavailableCampusGateway();
  }

  static get(): CampusNativeGateway {
    return CampusGatewayProvider.gateway;
  }
}
