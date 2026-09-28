Id policyId = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = 'Customer First' LIMIT 1].Id;

ServiceAppointment sa = [
    SELECT Id, AppointmentNumber, DueDate
    FROM ServiceAppointment
    WHERE SchedStartTime = null
      AND ServiceTerritoryId != null
      AND DueDate > :System.now()
    ORDER BY DueDate ASC
    LIMIT 1
];
System.debug('Testing SA: ' + sa.AppointmentNumber + ' | due ' + sa.DueDate);

FSL.GradeSlotsService svc = new FSL.GradeSlotsService(policyId, sa.Id);
FSL.AdvancedGapMatrix matrix = svc.getGradedMatrix(false);

Map<Id, ServiceResource> names = new Map<Id, ServiceResource>(
    [SELECT Id, Name FROM ServiceResource WHERE Id IN :matrix.resourceIDToScheduleData.keySet()]
);

Integer total = 0;
for (Id resourceId : matrix.resourceIDToScheduleData.keySet()) {
    FSL.ResourceScheduleData data = matrix.resourceIDToScheduleData.get(resourceId);
    for (FSL.SchedulingOption opt : data.schedulingOptions) {
        total++;
        System.debug(names.get(resourceId).Name + ' | grade ' + opt.grade
            + ' | ' + opt.interval.start + ' -> ' + opt.interval.finish);
    }
}
System.debug('Total slots: ' + total);