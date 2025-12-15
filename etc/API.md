# API Documentation

This document describes the API endpoints provided by the Laravel backend.

## Base URL

All API routes are prefixed with `/api`.

## Authentication

Some endpoints may require authentication using Laravel Sanctum (e.g., `/user`).  
Authenticated requests should include an `Authorization: Bearer <token>` header.

---

## 1. Menu Items

Manage the food and drink items available on the menu.

### List All Menu Items

- **URL**: `/menu-items`
- **Method**: `GET`
- **Description**: distinct list of all available menu items.
- **Response**: Array of menu item objects.
  ```json
  [
    {
      "id": 1,
      "name": "Nasi Goreng",
      "price": 15000,
      "image_asset": "nasi_goreng.jpg",
      "created_at": "2025-12-13T12:59:02.000000Z",
      "updated_at": "2025-12-13T12:59:02.000000Z"
    }
  ]
  ```

### Get Menu Item

- **URL**: `/menu-items/{id}`
- **Method**: `GET`
- **Description**: Retrieve a single menu item by ID.
- **Response**: Menu item object or 404 Not Found.
  ```json
  {
    "id": 4,
    "name": "Nasi Goreng Special",
    "price": 25000,
    "image_asset": "images/nasi_goreng_sambal_matah.jpg",
    "created_at": "2025-12-13T12:59:02.000000Z",
    "updated_at": "2025-12-13T12:59:02.000000Z"
  }
  ```

### Create Menu Item [NOT NEEDED FOR THIS FLUTTER PROJECT]

- **URL**: `/menu-items`
- **Method**: `POST`
- **Body Parameters**:
  - `name` (required, string, max:255)
  - `price` (required, integer, min:0)
  - `image_asset` (optional, string) - filename or path relative to assets
- **Response**: Created menu item object (HTTP 201).

### Update Menu Item [NOT NEEDED FOR THIS FLUTTER PROJECT]

- **URL**: `/menu-items/{id}`
- **Method**: `PUT` or `PATCH`
- **Body Parameters** (all optional):
  - `name` (string)
  - `price` (integer)
  - `image_asset` (string)
- **Response**: Updated menu item object.

### Delete Menu Item [NOT NEEDED FOR THIS FLUTTER PROJECT]

- **URL**: `/menu-items/{id}`
- **Method**: `DELETE`
- **Description**: Deletes the specified menu item.
- **Response**: HTTP 204 No Content.

---

## 2. Orders

Manage customer orders.

### List All Orders

- **URL**: `/orders`
- **Method**: `GET`
- **Description**: Returns all orders including their associated items.
- **Response**: Array of orders with `orderItems`.
  ```json
  [
    {
      "id": 2,
      "order_date": "2025-12-13T13:37:01.000000Z",
      "subtotal": 49000,
      "tax_amount": 4900,
      "total_amount": 53900,
      "payment_method": "QRIS",
      "payment_status": "PAID",
      "created_at": "2025-12-13T13:37:01.000000Z",
      "updated_at": "2025-12-13T13:37:01.000000Z",
      "order_items": [
        {
          "id": 5,
          "order_id": 2,
          "menu_item_id": 15,
          "menu_name": "Telur Dadar",
          "quantity": 2,
          "price_at_time": 5000,
          "subtotal": 10000,
          "created_at": "2025-12-13T13:37:01.000000Z",
          "updated_at": "2025-12-13T13:37:01.000000Z"
        }
        // ... more individual items
      ]
    }
    // ... more order lists
  ]
  ```

### Get Order

- **URL**: `/orders/{id}`
- **Method**: `GET`
- **Description**: Retrieve a single order with its items.
- **Response**: Order object with `orderItems` nested.
  ```json
  {
    "id": 2,
    "order_date": "2025-12-13T13:37:01.000000Z",
    "subtotal": 49000,
    "tax_amount": 4900,
    "total_amount": 53900,
    "payment_method": "QRIS",
    "payment_status": "PAID",
    "created_at": "2025-12-13T13:37:01.000000Z",
    "updated_at": "2025-12-13T13:37:01.000000Z",
    "order_items": [
      {
        "id": 5,
        "order_id": 2,
        "menu_item_id": 15,
        "menu_name": "Telur Dadar",
        "quantity": 2,
        "price_at_time": 5000,
        "subtotal": 10000,
        "created_at": "2025-12-13T13:37:01.000000Z",
        "updated_at": "2025-12-13T13:37:01.000000Z"
      }
      // ... more individual items
    ]
  }
  ```

### Create Order

- **URL**: `/orders`
- **Method**: `POST`
- **Description**: Creates a new order. Calculates subtotal, tax (10%), and total automatically.
- **Body Parameters**:
  - `payment_method` (required, string)
  - `items` (required, array of objects):
    - `id` (required, integer) - Menu item ID
    - `quantity` (required, integer, min:1)
- **Example Request**:
  ```json
  {
    "payment_method": "QRIS",
    "items": [
      { "id": 4, "quantity": 2 },
      { "id": 5, "quantity": 1 }
    ]
  }
  ```
- **Response**: Created Order object with detailed `orderItems`. Status defaults to `PAID`.
  ```json
  {
    "order_date": "2025-12-14T08:23:50.000000Z",
    "subtotal": 78000,
    "tax_amount": 7800,
    "total_amount": 85800,
    "payment_method": "QRIS",
    "payment_status": "PAID",
    "updated_at": "2025-12-14T08:23:50.000000Z",
    "created_at": "2025-12-14T08:23:50.000000Z",
    "id": 7,
    "order_items": [
      {
        "id": 26,
        "order_id": 7,
        "menu_item_id": 4,
        "menu_name": "Nasi Goreng Special",
        "quantity": 2,
        "price_at_time": 25000,
        "subtotal": 50000,
        "created_at": "2025-12-14T08:23:50.000000Z",
        "updated_at": "2025-12-14T08:23:50.000000Z"
      },
      {
        "id": 27,
        "order_id": 7,
        "menu_item_id": 5,
        "menu_name": "Mie Goreng Seafood",
        "quantity": 1,
        "price_at_time": 28000,
        "subtotal": 28000,
        "created_at": "2025-12-14T08:23:50.000000Z",
        "updated_at": "2025-12-14T08:23:50.000000Z"
      }
    ]
  }
  ```

### Update Order Status

- **URL**: `/orders/{id}`
- **Method**: `PUT`
- **Description**: Currently only allows updating the `payment_status`.
- **Body Parameters**:
  - `payment_status` (string)
  ```json
  {
    "payment_status": "PAID"
  }
  ```
- **Response**: Updated Order object.
  ```json
  {
    "id": 7,
    "order_date": "2025-12-14T08:23:50.000000Z",
    "subtotal": 78000,
    "tax_amount": 7800,
    "total_amount": 85800,
    "payment_method": "QRIS",
    "payment_status": "PAID",
    "created_at": "2025-12-14T08:23:50.000000Z",
    "updated_at": "2025-12-14T08:23:50.000000Z"
  }
  ```

### Delete Order

- **URL**: `/orders/{id}`
- **Method**: `DELETE`
- **Description**: _Currently disabled in controller logic._
- **Response**: HTTP 204 No Content.

---

## 3. Printing

Endoints for thermal printer integration.

### Print Order [I WANT TO IMPLEMENT IT HERE USING https://pub.dev/packages/flutter_thermal_printer | flutter_thermal_printer: ^1.2.4]

- **URL**: `/orders/{id}/print`
- **Method**: `POST`
- **Description**: Sends the order details to a local Python Flask bridge running on `localhost:8800`.
- **Response**:
  - Success: `{"message": "Print job sent successfully"}`
  - Error (500/503): Contains error message from the bridge or connection failure.
