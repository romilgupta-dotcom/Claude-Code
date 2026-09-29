trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert) {
        ContactTriggerHandler.onAfterInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
        ContactTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isDelete) {
        ContactTriggerHandler.onAfterDelete(Trigger.old);
    } else if (Trigger.isUndelete) {
        ContactTriggerHandler.onAfterUndelete(Trigger.new);
    }
}
