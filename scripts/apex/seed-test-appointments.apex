// Seeds unscheduled Work Orders + Service Appointments with a future scheduling window.
// Format: Territory|Street|City|PostalCode|Latitude|Longitude
List<String> sites = new List<String>{
    'Los Angeles|200 N Spring St|Los Angeles|90012|34.0537|-118.2428',
    'Los Angeles|111 S Grand Ave|Los Angeles|90012|34.0553|-118.2498',
    'Los Angeles|6801 Hollywood Blvd|Los Angeles|90028|34.1022|-118.3404',
    'Los Angeles|1200 Getty Center Dr|Los Angeles|90049|34.0780|-118.4741',
    'Los Angeles|2800 E Observatory Rd|Los Angeles|90027|34.1184|-118.3004',
    'San Francisco|1 Dr Carlton B Goodlett Pl|San Francisco|94102|37.7793|-122.4193',
    'San Francisco|1 Ferry Building|San Francisco|94111|37.7955|-122.3937',
    'San Francisco|Pier 39|San Francisco|94133|37.8087|-122.4098',
    'San Francisco|50 Hagiwara Tea Garden Dr|San Francisco|94118|37.7715|-122.4687',
    'San Francisco|3601 Lyon St|San Francisco|94123|37.8029|-122.4484'
};

Map<String, Id> territoryByName = new Map<String, Id>();
for (ServiceTerritory t : [SELECT Id, Name FROM ServiceTerritory WHERE IsActive = true]) {
    territoryByName.put(t.Name, t.Id);
}
List<WorkType> workTypes = [SELECT Id, Name, EstimatedDuration, DurationType FROM WorkType ORDER BY Name];

// 1. Work Orders
List<WorkOrder> workOrders = new List<WorkOrder>();
for (Integer i = 0; i < sites.size(); i++) {
    List<String> s = sites[i].split('\\|');
    WorkType wt = workTypes[Math.mod(i, workTypes.size())];
    workOrders.add(new WorkOrder(
        Subject = 'FSO Test ' + (i + 1) + ' - ' + wt.Name,
        WorkTypeId = wt.Id,
        ServiceTerritoryId = territoryByName.get(s[0]),
        Street = s[1], City = s[2], PostalCode = s[3],
        Latitude = Decimal.valueOf(s[4]), Longitude = Decimal.valueOf(s[5])
    ));
}
insert workOrders;

// 2. Some Work Types auto-create an SA; reuse those instead of duplicating
Map<Id, ServiceAppointment> saByWorkOrder = new Map<Id, ServiceAppointment>();
for (ServiceAppointment sa : [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId IN :workOrders]) {
    saByWorkOrder.put(sa.ParentRecordId, sa);
}

List<ServiceAppointment> toUpsert = new List<ServiceAppointment>();
for (Integer i = 0; i < workOrders.size(); i++) {
    WorkOrder wo = workOrders[i];
    WorkType wt = workTypes[Math.mod(i, workTypes.size())];
    ServiceAppointment sa = saByWorkOrder.containsKey(wo.Id)
        ? saByWorkOrder.get(wo.Id)
        : new ServiceAppointment(ParentRecordId = wo.Id);
    sa.Subject = wo.Subject;
    sa.ServiceTerritoryId = wo.ServiceTerritoryId;
    sa.EarliestStartTime = System.now();
    sa.DueDate = System.now().addDays(7);
    sa.Duration = wt.EstimatedDuration;
    sa.DurationType = wt.DurationType;
    sa.Street = wo.Street; sa.City = wo.City; sa.PostalCode = wo.PostalCode;
    sa.Latitude = wo.Latitude; sa.Longitude = wo.Longitude;
    toUpsert.add(sa);
}
upsert toUpsert;

System.debug('Created/updated ' + toUpsert.size() + ' service appointments');