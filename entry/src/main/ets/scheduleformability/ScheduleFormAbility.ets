import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { AhuCache, AhuPreferences } from 'core_datastore';
import { ScheduleWidgetDataBuilder } from 'feature_widget';

export default class ScheduleFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    AhuPreferences.initialize(this.context);
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    if (formId) {
      const ids = AhuCache.getScheduleWidgetIds();
      if (!ids.includes(formId)) { ids.push(formId); AhuCache.saveScheduleWidgetIds(ids); }
    }
    return ScheduleWidgetDataBuilder.bindingData();
  }

  onUpdateForm(formId: string): void {
    AhuPreferences.initialize(this.context);
    formProvider.updateForm(formId, ScheduleWidgetDataBuilder.bindingData()).catch(() => {});
  }

  onFormEvent(formId: string, _message: string): void {
    this.onUpdateForm(formId);
  }

  onRemoveForm(formId: string): void {
    AhuPreferences.initialize(this.context);
    AhuCache.saveScheduleWidgetIds(AhuCache.getScheduleWidgetIds().filter((id: string) => id !== formId));
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
