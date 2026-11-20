import ballerina/http;
import ballerina/time;
import ballerina/uuid;

isolated map<Order> orders = {};

service /orders on new http:Listener(8080) {

    resource function post .(@http:Payload NewOrder newOrder) returns Order|http:BadRequest {
        if newOrder.items.length() == 0 {
            return <http:BadRequest>{
                body: {message: "Order must contain at least one item"}
            };
        }

        decimal totalAmount = 0;
        foreach OrderItem item in newOrder.items {
            if item.quantity <= 0 {
                return <http:BadRequest>{
                    body: {message: "Item quantity must be greater than zero"}
                };
            }
            totalAmount += item.unitPrice * item.quantity;
        }

        string orderId = uuid:createType4AsString();
        string createdAt = time:utcToString(time:utcNow());

        Order createdOrder = {
            id: orderId,
            customerName: newOrder.customerName,
            items: newOrder.items,
            totalAmount: totalAmount,
            createdAt: createdAt
        };

        lock {
            orders[orderId] = createdOrder.clone();
        }

        return createdOrder;
    }

    resource function get .() returns Order[] {
        lock {
            return orders.toArray().clone();
        }
    }
}
