public class VehicleOrderTriggerHandler {

    public static void handleTrigger(
        List<Vehicle_Order__c> newOrders,
        Map<Id, Vehicle_Order__c> oldOrders,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate
    ) {

        if (isBefore && (isInsert || isUpdate)) {
            preventOrderIfOutOfStock(newOrders);
        }

        if (isAfter && isInsert) {
            updateStockOnOrderPlacement(newOrders);
        }
    }


    // Validate vehicle stock before an order is created or updated
    private static void preventOrderIfOutOfStock(
        List<Vehicle_Order__c> orders
    ) {

        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c order : orders) {

            if (order.Vehicle__c != null) {
                vehicleIds.add(order.Vehicle__c);
            }
        }

        if (vehicleIds.isEmpty()) {
            return;
        }

        Map<Id, Vehicle__c> vehicleStockMap =
            new Map<Id, Vehicle__c>(
                [
                    SELECT Id, Stock_Quantity__c
                    FROM Vehicle__c
                    WHERE Id IN :vehicleIds
                ]
            );

        for (Vehicle_Order__c order : orders) {

            if (order.Vehicle__c == null) {
                continue;
            }

            if (!vehicleStockMap.containsKey(order.Vehicle__c)) {
                continue;
            }

            Vehicle__c vehicle =
                vehicleStockMap.get(order.Vehicle__c);

            // If no stock is available, keep order Pending
            if (vehicle.Stock_Quantity__c <= 0) {
                order.Status__c = 'Pending';
            }
        }
    }


    // Reduce stock only when a new order is inserted as Confirmed
    private static void updateStockOnOrderPlacement(
        List<Vehicle_Order__c> orders
    ) {

        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c order : orders) {

            if (order.Vehicle__c != null &&
                order.Status__c == 'Confirmed') {

                vehicleIds.add(order.Vehicle__c);
            }
        }

        if (vehicleIds.isEmpty()) {
            return;
        }

        Map<Id, Vehicle__c> vehicleStockMap =
            new Map<Id, Vehicle__c>(
                [
                    SELECT Id, Stock_Quantity__c
                    FROM Vehicle__c
                    WHERE Id IN :vehicleIds
                ]
            );

        Map<Id, Vehicle__c> vehiclesToUpdate =
            new Map<Id, Vehicle__c>();

        for (Vehicle_Order__c order : orders) {

            if (order.Vehicle__c == null ||
                order.Status__c != 'Confirmed') {
                continue;
            }

            if (!vehicleStockMap.containsKey(order.Vehicle__c)) {
                continue;
            }

            Vehicle__c vehicle =
                vehicleStockMap.get(order.Vehicle__c);

            if (vehicle.Stock_Quantity__c > 0) {

                vehicle.Stock_Quantity__c -= 1;

                vehiclesToUpdate.put(
                    vehicle.Id,
                    vehicle
                );
            }
        }

        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate.values();
        }
    }
}
