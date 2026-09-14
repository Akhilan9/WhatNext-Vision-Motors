public class VehicleOrderTriggerHandler {

    public static void handleTrigger(
        List<Vehicle_Order__c> newOrders,
        Map<Id, Vehicle_Order__c> oldOrders,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate
    ) {

        // Before insert/update: validate stock
        if (isBefore && (isInsert || isUpdate)) {
            preventOrderIfOutOfStock(newOrders);
        }

        // After insert/update: reduce stock only when
        // an order becomes Confirmed
        if (isAfter && (isInsert || isUpdate)) {
            updateStockOnOrderPlacement(
                newOrders,
                oldOrders,
                isInsert
            );
        }
    }


    // If vehicle is out of stock,
    // keep the order Pending instead of blocking it.
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

            if (order.Vehicle__c != null &&
                vehicleStockMap.containsKey(order.Vehicle__c)) {

                Vehicle__c vehicle =
                    vehicleStockMap.get(order.Vehicle__c);

                if (vehicle.Stock_Quantity__c <= 0) {
                    order.Status__c = 'Pending';
                }
            }
        }
    }


    // Reduce stock when an order becomes Confirmed.
    private static void updateStockOnOrderPlacement(
        List<Vehicle_Order__c> orders,
        Map<Id, Vehicle_Order__c> oldOrders,
        Boolean isInsert
    ) {

        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c order : orders) {

            Boolean shouldReduceStock = false;

            // New Confirmed order
            if (isInsert &&
                order.Status__c == 'Confirmed') {

                shouldReduceStock = true;
            }

            // Existing Pending → Confirmed order
            if (!isInsert &&
                oldOrders != null &&
                oldOrders.containsKey(order.Id)) {

                Vehicle_Order__c oldOrder =
                    oldOrders.get(order.Id);

                if (order.Status__c == 'Confirmed' &&
                    oldOrder.Status__c != 'Confirmed') {

                    shouldReduceStock = true;
                }
            }

            if (shouldReduceStock &&
                order.Vehicle__c != null) {

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
                    FOR UPDATE
                ]
            );

        Map<Id, Vehicle__c> vehiclesToUpdate =
            new Map<Id, Vehicle__c>();

        for (Vehicle_Order__c order : orders) {

            Boolean shouldReduceStock = false;

            if (isInsert &&
                order.Status__c == 'Confirmed') {

                shouldReduceStock = true;
            }

            if (!isInsert &&
                oldOrders != null &&
                oldOrders.containsKey(order.Id)) {

                Vehicle_Order__c oldOrder =
                    oldOrders.get(order.Id);

                if (order.Status__c == 'Confirmed' &&
                    oldOrder.Status__c != 'Confirmed') {

                    shouldReduceStock = true;
                }
            }

            if (shouldReduceStock &&
                vehicleStockMap.containsKey(order.Vehicle__c)) {

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
        }

        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate.values();
        }
    }
}
