SET NOCOUNT ON;
GO
CREATE DATABASE Restaurant;
/* ============================ TABLES ============================ */
CREATE TABLE dbo.Customer (
    customer_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Customer PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(25) NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_Customer_Created DEFAULT (SYSDATETIME())
);
CREATE UNIQUE INDEX UX_Customer_Phone ON dbo.Customer(phone) WHERE phone IS NOT NULL;
GO

CREATE TABLE dbo.Employee (
    employee_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Employee PRIMARY KEY,
    manager_employee_id BIGINT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    phone VARCHAR(25) NULL,
    salary DECIMAL(12,2) NOT NULL,
    hire_date DATE NOT NULL,
    employment_status VARCHAR(20) NOT NULL CONSTRAINT DF_Employee_Status DEFAULT ('ACTIVE'),
    CONSTRAINT FK_Employee_Manager FOREIGN KEY (manager_employee_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT CK_Employee_Salary CHECK (salary >= 0),
    CONSTRAINT CK_Employee_Manager CHECK (manager_employee_id IS NULL OR manager_employee_id <> employee_id),
    CONSTRAINT CK_Employee_Status CHECK (employment_status IN ('ACTIVE','ON_LEAVE','SUSPENDED','TERMINATED'))
);
GO

CREATE TABLE dbo.RestaurantTable (
    table_id BIGINT IDENTITY(1,1) CONSTRAINT PK_RestaurantTable PRIMARY KEY,
    table_number INT NOT NULL CONSTRAINT UQ_RestaurantTable_Number UNIQUE,
    capacity INT NOT NULL,
    operational_status VARCHAR(20) NOT NULL CONSTRAINT DF_Table_Status DEFAULT ('ACTIVE'),
    CONSTRAINT CK_Table_Number CHECK (table_number > 0),
    CONSTRAINT CK_Table_Capacity CHECK (capacity > 0),
    CONSTRAINT CK_Table_Status CHECK (operational_status IN ('ACTIVE','OUT_OF_SERVICE','INACTIVE'))
);
GO

CREATE TABLE dbo.Reservation (
    reservation_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Reservation PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    employee_id BIGINT NULL,
    table_id BIGINT NOT NULL,
    starts_at DATETIME2 NOT NULL,
    ends_at DATETIME2 NOT NULL,
    guest_count INT NOT NULL,
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Reservation_Status DEFAULT ('PENDING'),
    CONSTRAINT FK_Reservation_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_Reservation_Employee FOREIGN KEY (employee_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT FK_Reservation_Table FOREIGN KEY (table_id) REFERENCES dbo.RestaurantTable(table_id),
    CONSTRAINT CK_Reservation_Time CHECK (ends_at > starts_at),
    CONSTRAINT CK_Reservation_Guests CHECK (guest_count > 0),
    CONSTRAINT CK_Reservation_Status CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW'))
);
GO

CREATE TABLE dbo.Category (
    category_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Category PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL CONSTRAINT UQ_Category_Name UNIQUE,
    is_active BIT NOT NULL CONSTRAINT DF_Category_Active DEFAULT (1)
);
GO

CREATE TABLE dbo.MenuItem (
    item_id BIGINT IDENTITY(1,1) CONSTRAINT PK_MenuItem PRIMARY KEY,
    category_id BIGINT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    current_price DECIMAL(12,2) NOT NULL,
    is_available BIT NOT NULL CONSTRAINT DF_MenuItem_Available DEFAULT (1),
    CONSTRAINT FK_MenuItem_Category FOREIGN KEY (category_id) REFERENCES dbo.Category(category_id),
    CONSTRAINT UQ_MenuItem_CategoryName UNIQUE (category_id, item_name),
    CONSTRAINT CK_MenuItem_Price CHECK (current_price >= 0)
);
GO

CREATE TABLE dbo.RestaurantOrder (
    order_id BIGINT IDENTITY(1,1) CONSTRAINT PK_RestaurantOrder PRIMARY KEY,
    customer_id BIGINT NULL,
    employee_id BIGINT NULL,
    table_id BIGINT NULL,
    reservation_id BIGINT NULL,
    order_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Order_Status DEFAULT ('PENDING'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_Order_Created DEFAULT (SYSDATETIME()),
    closed_at DATETIME2 NULL,
    total_amount DECIMAL(12,2) NOT NULL CONSTRAINT DF_Order_Total DEFAULT (0),
    CONSTRAINT FK_Order_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_Order_Employee FOREIGN KEY (employee_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT FK_Order_Table FOREIGN KEY (table_id) REFERENCES dbo.RestaurantTable(table_id),
    CONSTRAINT FK_Order_Reservation FOREIGN KEY (reservation_id) REFERENCES dbo.Reservation(reservation_id),
    CONSTRAINT CK_Order_Type CHECK (order_type IN ('DINE_IN','TAKEAWAY','DELIVERY')),
    CONSTRAINT CK_Order_Status CHECK (status IN ('PENDING','PREPARING','READY','SERVED','COMPLETED','CANCELLED')),
    CONSTRAINT CK_Order_Total CHECK (total_amount >= 0),
    CONSTRAINT CK_Order_DineInTable CHECK (order_type <> 'DINE_IN' OR table_id IS NOT NULL)
);
GO

CREATE TABLE dbo.OrderDetails (
    order_detail_id BIGINT IDENTITY(1,1) CONSTRAINT PK_OrderDetails PRIMARY KEY,
    order_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    item_notes VARCHAR(250) NULL,
    CONSTRAINT FK_OrderDetails_Order FOREIGN KEY (order_id) REFERENCES dbo.RestaurantOrder(order_id),
    CONSTRAINT FK_OrderDetails_MenuItem FOREIGN KEY (item_id) REFERENCES dbo.MenuItem(item_id),
    CONSTRAINT CK_OrderDetails_Quantity CHECK (quantity > 0),
    CONSTRAINT CK_OrderDetails_Price CHECK (unit_price >= 0)
);
GO

CREATE TABLE dbo.Payment (
    payment_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Payment PRIMARY KEY,
    order_id BIGINT NOT NULL,
    paid_at DATETIME2 NULL,
    amount DECIMAL(12,2) NOT NULL,
    method VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Payment_Status DEFAULT ('PENDING'),
    transaction_reference VARCHAR(100) NULL,
    CONSTRAINT FK_Payment_Order FOREIGN KEY (order_id) REFERENCES dbo.RestaurantOrder(order_id),
    CONSTRAINT CK_Payment_Amount CHECK (amount > 0),
    CONSTRAINT CK_Payment_Method CHECK (method IN ('CASH','CARD','WALLET','ONLINE','OTHER')),
    CONSTRAINT CK_Payment_Status CHECK (status IN ('PENDING','COMPLETED','FAILED','CANCELLED','REFUNDED'))
);
GO

CREATE TABLE dbo.DeliveryDetails (
    delivery_id BIGINT IDENTITY(1,1) CONSTRAINT PK_DeliveryDetails PRIMARY KEY,
    order_id BIGINT NOT NULL CONSTRAINT UQ_Delivery_Order UNIQUE,
    recipient_name VARCHAR(100) NOT NULL,
    delivery_address VARCHAR(250) NOT NULL,
    recipient_phone VARCHAR(25) NOT NULL,
    delivery_status VARCHAR(20) NOT NULL CONSTRAINT DF_Delivery_Status DEFAULT ('PENDING'),
    CONSTRAINT FK_Delivery_Order FOREIGN KEY (order_id) REFERENCES dbo.RestaurantOrder(order_id),
    CONSTRAINT CK_Delivery_Status CHECK (delivery_status IN ('PENDING','ASSIGNED','OUT_FOR_DELIVERY','DELIVERED','FAILED','CANCELLED'))
);
GO

CREATE TABLE dbo.Supplier (
    supplier_id BIGINT IDENTITY(1,1) CONSTRAINT PK_Supplier PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100) NULL,
    phone VARCHAR(25) NULL
);
GO

CREATE TABLE dbo.InventoryItem (
    inventory_item_id BIGINT IDENTITY(1,1) CONSTRAINT PK_InventoryItem PRIMARY KEY,
    preferred_supplier_id BIGINT NULL,
    item_name VARCHAR(100) NOT NULL CONSTRAINT UQ_InventoryItem_Name UNIQUE,
    unit VARCHAR(20) NOT NULL,
    quantity_on_hand DECIMAL(12,3) NOT NULL CONSTRAINT DF_Inventory_Quantity DEFAULT (0),
    reorder_level DECIMAL(12,3) NOT NULL CONSTRAINT DF_Inventory_Reorder DEFAULT (0),
    CONSTRAINT FK_Inventory_PreferredSupplier FOREIGN KEY (preferred_supplier_id) REFERENCES dbo.Supplier(supplier_id),
    CONSTRAINT CK_Inventory_Quantity CHECK (quantity_on_hand >= 0),
    CONSTRAINT CK_Inventory_Reorder CHECK (reorder_level >= 0)
);
GO

CREATE TABLE dbo.MenuItemIngredient (
    item_id BIGINT NOT NULL,
    inventory_item_id BIGINT NOT NULL,
    quantity_used DECIMAL(12,3) NOT NULL,
    CONSTRAINT PK_MenuItemIngredient PRIMARY KEY (item_id, inventory_item_id),
    CONSTRAINT FK_Recipe_MenuItem FOREIGN KEY (item_id) REFERENCES dbo.MenuItem(item_id),
    CONSTRAINT FK_Recipe_Inventory FOREIGN KEY (inventory_item_id) REFERENCES dbo.InventoryItem(inventory_item_id),
    CONSTRAINT CK_Recipe_Quantity CHECK (quantity_used > 0)
);
GO

CREATE TABLE dbo.PurchaseOrder (
    purchase_order_id BIGINT IDENTITY(1,1) CONSTRAINT PK_PurchaseOrder PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    created_by_employee_id BIGINT NOT NULL,
    ordered_at DATETIME2 NOT NULL CONSTRAINT DF_PO_OrderedAt DEFAULT (SYSDATETIME()),
    status VARCHAR(20) NOT NULL CONSTRAINT DF_PO_Status DEFAULT ('DRAFT'),
    CONSTRAINT FK_PO_Supplier FOREIGN KEY (supplier_id) REFERENCES dbo.Supplier(supplier_id),
    CONSTRAINT FK_PO_Employee FOREIGN KEY (created_by_employee_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT CK_PO_Status CHECK (status IN ('DRAFT','ORDERED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED'))
);
GO

CREATE TABLE dbo.PurchaseOrderDetail (
    po_detail_id BIGINT IDENTITY(1,1) CONSTRAINT PK_PurchaseOrderDetail PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    inventory_item_id BIGINT NOT NULL,
    quantity_ordered DECIMAL(12,3) NOT NULL,
    quantity_received DECIMAL(12,3) NOT NULL CONSTRAINT DF_POD_Received DEFAULT (0),
    unit_cost DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_POD_Order FOREIGN KEY (purchase_order_id) REFERENCES dbo.PurchaseOrder(purchase_order_id),
    CONSTRAINT FK_POD_Inventory FOREIGN KEY (inventory_item_id) REFERENCES dbo.InventoryItem(inventory_item_id),
    CONSTRAINT CK_POD_QuantityOrdered CHECK (quantity_ordered > 0),
    CONSTRAINT CK_POD_QuantityReceived CHECK (quantity_received >= 0 AND quantity_received <= quantity_ordered),
    CONSTRAINT CK_POD_UnitCost CHECK (unit_cost >= 0)
);
GO

CREATE TABLE dbo.InventoryTransaction (
    transaction_id BIGINT IDENTITY(1,1) CONSTRAINT PK_InventoryTransaction PRIMARY KEY,
    inventory_item_id BIGINT NOT NULL,
    purchase_order_detail_id BIGINT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    quantity_delta DECIMAL(12,3) NOT NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_InventoryTxn_Created DEFAULT (SYSDATETIME()),
    notes VARCHAR(250) NULL,
    CONSTRAINT FK_InventoryTxn_Item FOREIGN KEY (inventory_item_id) REFERENCES dbo.InventoryItem(inventory_item_id),
    CONSTRAINT FK_InventoryTxn_PODetail FOREIGN KEY (purchase_order_detail_id) REFERENCES dbo.PurchaseOrderDetail(po_detail_id),
    CONSTRAINT CK_InventoryTxn_Type CHECK (transaction_type IN ('PURCHASE','CONSUMPTION','WASTE','ADJUSTMENT','RETURN')),
    CONSTRAINT CK_InventoryTxn_Quantity CHECK (quantity_delta <> 0),
    CONSTRAINT CK_InventoryTxn_Sign CHECK (
       (transaction_type IN ('PURCHASE','RETURN') AND quantity_delta > 0)
       OR (transaction_type IN ('CONSUMPTION','WASTE') AND quantity_delta < 0)
       OR transaction_type = 'ADJUSTMENT'
    )
);
GO

/* ============================ INDEXES ============================ */
CREATE INDEX IX_Reservation_Table_Time ON dbo.Reservation(table_id, starts_at, ends_at) INCLUDE (status);
CREATE INDEX IX_Order_CreatedAt ON dbo.RestaurantOrder(created_at);
CREATE INDEX IX_OrderDetails_Order ON dbo.OrderDetails(order_id) INCLUDE (item_id, quantity, unit_price);
CREATE INDEX IX_Payment_Order ON dbo.Payment(order_id) INCLUDE (amount, status);
CREATE INDEX IX_InventoryTxn_ItemDate ON dbo.InventoryTransaction(inventory_item_id, created_at);
CREATE INDEX IX_POD_Order ON dbo.PurchaseOrderDetail(purchase_order_id);
GO

/* ============================ FUNCTIONS ============================ */
CREATE OR ALTER FUNCTION dbo.fn_OrderSubtotal (@OrderID BIGINT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Subtotal DECIMAL(12,2);
    SELECT @Subtotal = COALESCE(SUM(CONVERT(DECIMAL(12,2), quantity * unit_price)), 0)
    FROM dbo.OrderDetails WHERE order_id = @OrderID;
    RETURN COALESCE(@Subtotal, 0);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_InventoryStatus (@InventoryItemID BIGINT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Qty DECIMAL(12,3), @Reorder DECIMAL(12,3), @Result VARCHAR(20);
    SELECT @Qty = quantity_on_hand, @Reorder = reorder_level
    FROM dbo.InventoryItem WHERE inventory_item_id = @InventoryItemID;
    IF @Qty IS NULL RETURN 'NOT_FOUND';
    SET @Result = CASE WHEN @Qty <= @Reorder THEN 'REORDER' ELSE 'IN_STOCK' END;
    RETURN @Result;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_OrderPaidAmount (@OrderID BIGINT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Paid DECIMAL(12,2);
    SELECT @Paid = COALESCE(SUM(amount), 0)
    FROM dbo.Payment WHERE order_id = @OrderID AND status = 'COMPLETED';
    RETURN COALESCE(@Paid, 0);
END;
GO

/* ============================ TRIGGERS ============================ */
/* Keep order totals correct after order-detail INSERT/UPDATE/DELETE. */
CREATE OR ALTER TRIGGER dbo.trg_OrderDetails_RecalculateTotal
ON dbo.OrderDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH AffectedOrders AS (
        SELECT order_id FROM inserted
        UNION
        SELECT order_id FROM deleted
    )
    UPDATE ro
       SET total_amount = COALESCE(x.subtotal, 0)
    FROM dbo.RestaurantOrder ro
    INNER JOIN AffectedOrders ao ON ao.order_id = ro.order_id
    OUTER APPLY (
        SELECT SUM(CONVERT(DECIMAL(12,2), od.quantity * od.unit_price)) AS subtotal
        FROM dbo.OrderDetails od WHERE od.order_id = ro.order_id
    ) x;
END;
GO

/* Keep stock synchronized with every inventory movement; rollback if stock would go negative. */
CREATE OR ALTER TRIGGER dbo.trg_InventoryTransaction_UpdateStock
ON dbo.InventoryTransaction
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Deltas TABLE (
        inventory_item_id BIGINT PRIMARY KEY,
        net_change DECIMAL(12,3) NOT NULL
    );

    INSERT INTO @Deltas(inventory_item_id, net_change)
    SELECT inventory_item_id, SUM(delta_change)
    FROM (
        SELECT inventory_item_id, CONVERT(DECIMAL(12,3), quantity_delta) AS delta_change FROM inserted
        UNION ALL
        SELECT inventory_item_id, CONVERT(DECIMAL(12,3), -quantity_delta) AS delta_change FROM deleted
    ) q
    GROUP BY inventory_item_id;

    IF EXISTS (
        SELECT 1 FROM @Deltas d
        JOIN dbo.InventoryItem i ON i.inventory_item_id = d.inventory_item_id
        WHERE i.quantity_on_hand + d.net_change < 0
    )
    BEGIN
        RAISERROR('Inventory movement rejected: stock cannot become negative.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE i SET quantity_on_hand = i.quantity_on_hand + d.net_change
    FROM dbo.InventoryItem i JOIN @Deltas d ON d.inventory_item_id = i.inventory_item_id;
END;
GO

/* Validate that a reservation's party fits the selected table. */
CREATE OR ALTER TRIGGER dbo.trg_Reservation_ValidateCapacity
ON dbo.Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted r
        JOIN dbo.RestaurantTable t ON t.table_id = r.table_id
        WHERE r.guest_count > t.capacity
    )
    BEGIN
        RAISERROR('Reservation guest_count cannot exceed table capacity.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* Avoid overlapping active reservations for the same table. */
CREATE OR ALTER TRIGGER dbo.trg_Reservation_PreventOverlap
ON dbo.Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Reservation r WITH (UPDLOCK, HOLDLOCK)
          ON r.table_id = i.table_id
         AND r.reservation_id <> i.reservation_id
         AND r.status IN ('PENDING','CONFIRMED')
         AND i.status IN ('PENDING','CONFIRMED')
         AND i.starts_at < r.ends_at
         AND i.ends_at > r.starts_at
    )
    BEGIN
        RAISERROR('The table already has an overlapping active reservation.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ============================ STORED PROCEDURES ============================ */
CREATE OR ALTER PROCEDURE dbo.usp_AddCustomer
    @FirstName VARCHAR(50), @LastName VARCHAR(50), @Phone VARCHAR(25) = NULL,
    @CustomerID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Customer(first_name, last_name, phone)
    VALUES (@FirstName, @LastName, @Phone);
    SET @CustomerID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder
    @OrderType VARCHAR(20),
    @CustomerID BIGINT = NULL,
    @EmployeeID BIGINT = NULL,
    @TableID BIGINT = NULL,
    @ReservationID BIGINT = NULL,
    @OrderID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @OrderType NOT IN ('DINE_IN','TAKEAWAY','DELIVERY')
        THROW 50001, 'Invalid order type.', 1;
    IF @OrderType = 'DINE_IN' AND @TableID IS NULL
        THROW 50002, 'A table is required for DINE_IN orders.', 1;
    IF @TableID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.RestaurantTable WHERE table_id = @TableID AND operational_status = 'ACTIVE'
    ) THROW 50003, 'The selected table does not exist or is not active.', 1;
    IF @EmployeeID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.Employee WHERE employee_id = @EmployeeID AND employment_status = 'ACTIVE'
    ) THROW 50004, 'The selected employee does not exist or is not active.', 1;
    INSERT INTO dbo.RestaurantOrder(customer_id, employee_id, table_id, reservation_id, order_type)
    VALUES (@CustomerID, @EmployeeID, @TableID, @ReservationID, @OrderType);
    SET @OrderID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AddOrderDetail
    @OrderID BIGINT, @ItemID BIGINT, @Quantity INT,
    @UnitPrice DECIMAL(12,2) = NULL, @ItemNotes VARCHAR(250) = NULL,
    @OrderDetailID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @Quantity <= 0 THROW 50010, 'Quantity must be greater than zero.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.RestaurantOrder WHERE order_id = @OrderID AND status IN ('PENDING','PREPARING'))
        THROW 50011, 'Order not found or is no longer editable.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.MenuItem WHERE item_id = @ItemID AND is_available = 1)
        THROW 50012, 'Menu item not found or unavailable.', 1;
    IF @UnitPrice IS NULL SELECT @UnitPrice = current_price FROM dbo.MenuItem WHERE item_id = @ItemID;
    IF @UnitPrice < 0 THROW 50013, 'Unit price cannot be negative.', 1;
    INSERT INTO dbo.OrderDetails(order_id, item_id, quantity, unit_price, item_notes)
    VALUES (@OrderID, @ItemID, @Quantity, @UnitPrice, @ItemNotes);
    SET @OrderDetailID = CONVERT(BIGINT, SCOPE_IDENTITY());
    /* trg_OrderDetails_RecalculateTotal updates the order total automatically. */
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SetOrderStatus
    @OrderID BIGINT, @NewStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @NewStatus NOT IN ('PENDING','PREPARING','READY','SERVED','COMPLETED','CANCELLED')
        THROW 50020, 'Invalid order status.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.RestaurantOrder WHERE order_id = @OrderID)
        THROW 50021, 'Order not found.', 1;
    IF @NewStatus = 'COMPLETED' AND NOT EXISTS (SELECT 1 FROM dbo.OrderDetails WHERE order_id = @OrderID)
        THROW 50022, 'An order without items cannot be completed.', 1;
    UPDATE dbo.RestaurantOrder
       SET status = @NewStatus,
           closed_at = CASE WHEN @NewStatus IN ('COMPLETED','CANCELLED') THEN SYSDATETIME() ELSE NULL END
     WHERE order_id = @OrderID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RecordPayment
    @OrderID BIGINT, @Amount DECIMAL(12,2), @Method VARCHAR(20),
    @TransactionReference VARCHAR(100) = NULL, @PaymentID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @Amount <= 0 THROW 50030, 'Payment amount must be greater than zero.', 1;
    IF @Method NOT IN ('CASH','CARD','WALLET','ONLINE','OTHER') THROW 50031, 'Invalid payment method.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.RestaurantOrder WHERE order_id = @OrderID AND status <> 'CANCELLED')
        THROW 50032, 'Order not found or cancelled.', 1;
    INSERT INTO dbo.Payment(order_id, paid_at, amount, method, status, transaction_reference)
    VALUES (@OrderID, SYSDATETIME(), @Amount, @Method, 'COMPLETED', @TransactionReference);
    SET @PaymentID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateReservation
    @CustomerID BIGINT, @TableID BIGINT, @StartsAt DATETIME2, @EndsAt DATETIME2,
    @GuestCount INT, @EmployeeID BIGINT = NULL, @ReservationID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @EndsAt <= @StartsAt THROW 50040, 'Reservation end must be after its start.', 1;
    IF @GuestCount <= 0 THROW 50041, 'Guest count must be positive.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.RestaurantTable WHERE table_id = @TableID AND operational_status = 'ACTIVE')
        THROW 50042, 'Table not found or inactive.', 1;
    INSERT INTO dbo.Reservation(customer_id, employee_id, table_id, starts_at, ends_at, guest_count)
    VALUES (@CustomerID, @EmployeeID, @TableID, @StartsAt, @EndsAt, @GuestCount);
    SET @ReservationID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreatePurchaseOrder
    @SupplierID BIGINT, @EmployeeID BIGINT, @PurchaseOrderID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Supplier WHERE supplier_id = @SupplierID)
        THROW 50050, 'Supplier not found.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Employee WHERE employee_id = @EmployeeID AND employment_status = 'ACTIVE')
        THROW 50051, 'Active employee not found.', 1;
    INSERT INTO dbo.PurchaseOrder(supplier_id, created_by_employee_id, status)
    VALUES (@SupplierID, @EmployeeID, 'DRAFT');
    SET @PurchaseOrderID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AddPurchaseOrderDetail
    @PurchaseOrderID BIGINT, @InventoryItemID BIGINT,
    @QuantityOrdered DECIMAL(12,3), @UnitCost DECIMAL(12,2),
    @PODetailID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @QuantityOrdered <= 0 THROW 50060, 'Ordered quantity must be positive.', 1;
    IF @UnitCost < 0 THROW 50061, 'Unit cost cannot be negative.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrder WHERE purchase_order_id = @PurchaseOrderID AND status IN ('DRAFT','ORDERED','PARTIALLY_RECEIVED'))
        THROW 50062, 'Purchase order not found or not editable.', 1;
    INSERT INTO dbo.PurchaseOrderDetail(purchase_order_id, inventory_item_id, quantity_ordered, unit_cost)
    VALUES (@PurchaseOrderID, @InventoryItemID, @QuantityOrdered, @UnitCost);
    SET @PODetailID = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ReceivePurchaseOrderItem
    @PODetailID BIGINT, @QuantityToReceive DECIMAL(12,3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ItemID BIGINT, @OrderID BIGINT, @Remaining DECIMAL(12,3);
    IF @QuantityToReceive <= 0 THROW 50070, 'Received quantity must be positive.', 1;
    BEGIN TRANSACTION;
    SELECT @ItemID = inventory_item_id, @OrderID = purchase_order_id,
           @Remaining = quantity_ordered - quantity_received
    FROM dbo.PurchaseOrderDetail WITH (UPDLOCK, HOLDLOCK)
    WHERE po_detail_id = @PODetailID;
    IF @ItemID IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50071, 'Purchase order detail not found.', 1;
    END;
    IF @QuantityToReceive > @Remaining
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50072, 'Received quantity exceeds the outstanding quantity.', 1;
    END;
    UPDATE dbo.PurchaseOrderDetail
       SET quantity_received = quantity_received + @QuantityToReceive
     WHERE po_detail_id = @PODetailID;
    INSERT INTO dbo.InventoryTransaction(inventory_item_id, purchase_order_detail_id, transaction_type, quantity_delta, notes)
    VALUES (@ItemID, @PODetailID, 'PURCHASE', @QuantityToReceive, 'Goods received against purchase order');
    /* Inventory trigger updates quantity_on_hand. */
    UPDATE dbo.PurchaseOrder
       SET status = CASE
           WHEN NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderDetail d WHERE d.purchase_order_id = @OrderID AND d.quantity_received < d.quantity_ordered) THEN 'RECEIVED'
           WHEN EXISTS (SELECT 1 FROM dbo.PurchaseOrderDetail d WHERE d.purchase_order_id = @OrderID AND d.quantity_received > 0) THEN 'PARTIALLY_RECEIVED'
           ELSE status END
     WHERE purchase_order_id = @OrderID;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdjustInventory
    @InventoryItemID BIGINT, @QuantityDelta DECIMAL(12,3), @Notes VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @QuantityDelta = 0 THROW 50080, 'Adjustment quantity cannot be zero.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.InventoryItem WHERE inventory_item_id = @InventoryItemID)
        THROW 50081, 'Inventory item not found.', 1;
    INSERT INTO dbo.InventoryTransaction(inventory_item_id, transaction_type, quantity_delta, notes)
    VALUES (@InventoryItemID, 'ADJUSTMENT', @QuantityDelta, @Notes);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetLowStockItems
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.inventory_item_id, i.item_name, i.unit, i.quantity_on_hand, i.reorder_level,
           s.supplier_name, s.phone AS supplier_phone
    FROM dbo.InventoryItem i
    LEFT JOIN dbo.Supplier s ON s.supplier_id = i.preferred_supplier_id
    WHERE i.quantity_on_hand <= i.reorder_level
    ORDER BY i.item_name;
END;
GO

/* ============================ REPORTING VIEWS ============================ */
CREATE OR ALTER VIEW dbo.vw_OrderSummary
AS
SELECT ro.order_id, ro.created_at, ro.closed_at, ro.order_type, ro.status,
       ro.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       ro.employee_id,
       CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
       ro.table_id, ro.total_amount,
       dbo.fn_OrderPaidAmount(ro.order_id) AS paid_amount,
       ro.total_amount - dbo.fn_OrderPaidAmount(ro.order_id) AS balance_due
FROM dbo.RestaurantOrder ro
LEFT JOIN dbo.Customer c ON c.customer_id = ro.customer_id
LEFT JOIN dbo.Employee e ON e.employee_id = ro.employee_id;
GO

CREATE OR ALTER VIEW dbo.vw_MenuSales
AS
SELECT mi.item_id, mi.item_name, c.category_name,
       SUM(od.quantity) AS units_sold,
       SUM(CONVERT(DECIMAL(14,2), od.quantity * od.unit_price)) AS sales_amount
FROM dbo.OrderDetails od
JOIN dbo.MenuItem mi ON mi.item_id = od.item_id
JOIN dbo.Category c ON c.category_id = mi.category_id
JOIN dbo.RestaurantOrder ro ON ro.order_id = od.order_id
WHERE ro.status <> 'CANCELLED'
GROUP BY mi.item_id, mi.item_name, c.category_name;
GO


/* Assignment-named UDF: returns the current calculated total for an order. */
CREATE OR ALTER FUNCTION dbo.CalculateOrderTotal (@OrderID BIGINT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Total DECIMAL(12,2);
    SELECT @Total = COALESCE(SUM(CONVERT(DECIMAL(12,2), quantity * unit_price)), 0)
    FROM dbo.OrderDetails
    WHERE order_id = @OrderID;
    RETURN COALESCE(@Total, 0);
END;
GO

/* ============================ PRICE AUDIT ============================ */
CREATE TABLE dbo.MenuItemPriceAudit (
    audit_id BIGINT IDENTITY(1,1) CONSTRAINT PK_MenuItemPriceAudit PRIMARY KEY,
    item_id BIGINT NOT NULL,
    old_price DECIMAL(12,2) NOT NULL,
    new_price DECIMAL(12,2) NOT NULL,
    changed_at DATETIME2 NOT NULL CONSTRAINT DF_MenuItemPriceAudit_ChangedAt DEFAULT (SYSDATETIME()),
    changed_by SYSNAME NOT NULL CONSTRAINT DF_MenuItemPriceAudit_ChangedBy DEFAULT (SUSER_SNAME())
);
GO

CREATE OR ALTER TRIGGER dbo.trg_MenuItem_PriceAudit
ON dbo.MenuItem
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.MenuItemPriceAudit(item_id, old_price, new_price, changed_at, changed_by)
    SELECT i.item_id, d.current_price, i.current_price, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i
    JOIN deleted d ON d.item_id = i.item_id
    WHERE i.current_price <> d.current_price;
END;
GO

/* ============================ REQUIRED PROCEDURES ============================ */
CREATE OR ALTER PROCEDURE dbo.GetCustomerOrders
    @CustomerID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ro.order_id, ro.created_at, ro.order_type, ro.status,
           ro.total_amount,
           COALESCE(p.paid_amount, 0) AS paid_amount,
           ro.total_amount - COALESCE(p.paid_amount, 0) AS balance_due
    FROM dbo.RestaurantOrder ro
    OUTER APPLY (
        SELECT SUM(py.amount) AS paid_amount
        FROM dbo.Payment py
        WHERE py.order_id = ro.order_id AND py.status = 'COMPLETED'
    ) p
    WHERE ro.customer_id = @CustomerID
    ORDER BY ro.created_at DESC, ro.order_id DESC;
END;
GO

/* User-facing procedure name requested in the assignment. */
CREATE OR ALTER PROCEDURE dbo.CreateReservation
    @CustomerID BIGINT,
    @TableID BIGINT,
    @StartsAt DATETIME2,
    @EndsAt DATETIME2,
    @GuestCount INT,
    @EmployeeID BIGINT = NULL,
    @ReservationID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.usp_CreateReservation
        @CustomerID = @CustomerID,
        @TableID = @TableID,
        @StartsAt = @StartsAt,
        @EndsAt = @EndsAt,
        @GuestCount = @GuestCount,
        @EmployeeID = @EmployeeID,
        @ReservationID = @ReservationID OUTPUT;
END;
GO

/* ============================ SAMPLE DATA (ASSIGNMENT REQUIREMENTS) ============================ */
/* Categories and tables are included to satisfy foreign-key dependencies. */
INSERT INTO dbo.Category(category_name, is_active) VALUES
('Starters',1),('Main Course',1),('Desserts',1),('Beverages',1),('Salads',1);

INSERT INTO dbo.RestaurantTable(table_number, capacity, operational_status) VALUES
(1,2,'ACTIVE'),(2,2,'ACTIVE'),(3,4,'ACTIVE'),(4,4,'ACTIVE'),(5,4,'ACTIVE'),
(6,6,'ACTIVE'),(7,6,'ACTIVE'),(8,8,'ACTIVE'),(9,2,'ACTIVE'),(10,4,'ACTIVE');

INSERT INTO dbo.Customer(first_name, last_name, phone) VALUES
('Ahmed','Hassan','01010000001'),('Mona','Ali','01010000002'),
('Omar','Mahmoud','01010000003'),('Salma','Ibrahim','01010000004'),
('Youssef','Khaled','01010000005'),('Nour','Samir','01010000006'),
('Maryam','Adel','01010000007'),('Amr','Mostafa','01010000008'),
('Farah','Tarek','01010000009'),('Karim','Ashraf','01010000010');

INSERT INTO dbo.Employee(manager_employee_id, first_name, last_name, job_title, phone, salary, hire_date, employment_status) VALUES
(NULL,'Hany','Fawzy','Manager','01120000001',18000,'2022-01-10','ACTIVE'),
(1,'Rana','Said','Head Chef','01120000002',14000,'2022-04-15','ACTIVE'),
(1,'Mostafa','Nabil','Waiter','01120000003',6500,'2023-02-01','ACTIVE'),
(1,'Dina','Wael','Cashier','01120000004',7000,'2023-06-12','ACTIVE'),
(1,'Sherif','Ayman','Delivery Coordinator','01120000005',7500,'2024-01-20','ACTIVE');

INSERT INTO dbo.Supplier(supplier_name, contact_person, phone) VALUES
('Nile Fresh Foods','Mahmoud Saleh','01230000001'),
('Green Farm Supplies','Heba Amin','01230000002'),
('Prime Meat Co','Tamer Eid','01230000003'),
('Daily Dairy','Mariam Galal','01230000004'),
('Beverage Hub','Fady Nasser','01230000005');

INSERT INTO dbo.MenuItem(category_id, item_name, current_price, is_available) VALUES
(1,'Garlic Bread',45.00,1),(1,'Chicken Wings',95.00,1),(1,'Soup of the Day',55.00,1),
(2,'Grilled Chicken',180.00,1),(2,'Beef Burger',165.00,1),(2,'Alfredo Pasta',145.00,1),
(2,'Margherita Pizza',155.00,1),(2,'Steak Plate',290.00,1),(2,'Grilled Fish',220.00,1),
(3,'Chocolate Cake',75.00,1),(3,'Cheesecake',85.00,1),
(4,'Fresh Orange Juice',50.00,1),(4,'Lemon Mint',45.00,1),
(5,'Greek Salad',80.00,1),(5,'Caesar Salad',90.00,1);

INSERT INTO dbo.InventoryItem(preferred_supplier_id, item_name, unit, quantity_on_hand, reorder_level) VALUES
(1,'Bread Loaves','piece',120,20),(1,'Chicken','kg',80,15),
(3,'Beef','kg',50,10),(2,'Tomatoes','kg',60,12),
(2,'Lettuce','kg',35,8),(4,'Milk','liter',45,10),
(4,'Cheese','kg',40,8),(5,'Orange Juice','liter',55,10),
(2,'Potatoes','kg',70,15),(5,'Coffee Beans','kg',25,5);

/* Ten reservations: different tables and dates, so they do not overlap. */
INSERT INTO dbo.Reservation(customer_id, employee_id, table_id, starts_at, ends_at, guest_count, status) VALUES
(1,3,1,DATEADD(HOUR,10,DATEADD(DAY,1,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,11,DATEADD(DAY,1,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),2,'CONFIRMED'),
(2,3,2,DATEADD(HOUR,11,DATEADD(DAY,2,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,12,DATEADD(DAY,2,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),2,'PENDING'),
(3,3,3,DATEADD(HOUR,12,DATEADD(DAY,3,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,13,DATEADD(DAY,3,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),4,'CONFIRMED'),
(4,3,4,DATEADD(HOUR,13,DATEADD(DAY,4,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,14,DATEADD(DAY,4,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),4,'PENDING'),
(5,3,5,DATEADD(HOUR,14,DATEADD(DAY,5,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,15,DATEADD(DAY,5,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),3,'CONFIRMED'),
(6,3,6,DATEADD(HOUR,15,DATEADD(DAY,6,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,16,DATEADD(DAY,6,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),5,'PENDING'),
(7,3,7,DATEADD(HOUR,16,DATEADD(DAY,7,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,17,DATEADD(DAY,7,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),6,'CONFIRMED'),
(8,3,8,DATEADD(HOUR,17,DATEADD(DAY,8,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,18,DATEADD(DAY,8,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),7,'PENDING'),
(9,3,9,DATEADD(HOUR,18,DATEADD(DAY,9,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,19,DATEADD(DAY,9,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),2,'CONFIRMED'),
(10,3,10,DATEADD(HOUR,19,DATEADD(DAY,10,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),DATEADD(HOUR,20,DATEADD(DAY,10,CONVERT(DATETIME2,CONVERT(DATE,GETDATE())))),4,'PENDING');

/* Twenty orders, covering dine-in, takeaway and delivery. */
INSERT INTO dbo.RestaurantOrder(customer_id, employee_id, table_id, reservation_id, order_type, status)
VALUES
(1,3,1,1,'DINE_IN','COMPLETED'),(2,3,2,2,'DINE_IN','COMPLETED'),
(3,3,3,3,'DINE_IN','COMPLETED'),(4,3,4,4,'DINE_IN','COMPLETED'),
(5,3,5,5,'DINE_IN','COMPLETED'),(6,3,6,6,'DINE_IN','COMPLETED'),
(7,3,7,7,'DINE_IN','COMPLETED'),(8,3,8,8,'DINE_IN','COMPLETED'),
(9,3,9,9,'DINE_IN','COMPLETED'),(10,3,10,10,'DINE_IN','COMPLETED'),
(1,4,NULL,NULL,'TAKEAWAY','COMPLETED'),(2,4,NULL,NULL,'TAKEAWAY','COMPLETED'),
(3,4,NULL,NULL,'DELIVERY','COMPLETED'),(4,4,NULL,NULL,'DELIVERY','COMPLETED'),
(5,4,NULL,NULL,'TAKEAWAY','COMPLETED'),(6,4,NULL,NULL,'DELIVERY','COMPLETED'),
(7,4,NULL,NULL,'TAKEAWAY','COMPLETED'),(8,4,NULL,NULL,'DELIVERY','COMPLETED'),
(9,4,NULL,NULL,'TAKEAWAY','COMPLETED'),(10,4,NULL,NULL,'DELIVERY','COMPLETED');

/* At least one menu item per order; trigger calculates each order total. */
INSERT INTO dbo.OrderDetails(order_id, item_id, quantity, unit_price, item_notes)
VALUES
(1,4,1,180.00,NULL),(2,5,1,165.00,NULL),(3,6,2,145.00,NULL),(4,7,1,155.00,NULL),
(5,8,1,290.00,NULL),(6,9,1,220.00,NULL),(7,10,2,75.00,NULL),(8,11,1,85.00,NULL),
(9,12,2,50.00,NULL),(10,13,2,45.00,NULL),(11,14,1,80.00,NULL),(12,15,1,90.00,NULL),
(13,4,2,180.00,NULL),(14,5,2,165.00,NULL),(15,6,1,145.00,NULL),(16,7,2,155.00,NULL),
(17,8,1,290.00,NULL),(18,9,2,220.00,NULL),(19,10,1,75.00,NULL),(20,11,2,85.00,NULL);

/* Twenty payments: one completed payment for each sample order. */
INSERT INTO dbo.Payment(order_id, paid_at, amount, method, status, transaction_reference)
SELECT ro.order_id, SYSDATETIME(), ro.total_amount,
       CASE WHEN ro.order_id % 3 = 0 THEN 'CARD'
            WHEN ro.order_id % 3 = 1 THEN 'CASH' ELSE 'WALLET' END,
       'COMPLETED', CONCAT('SAMPLE-TXN-', ro.order_id)
FROM dbo.RestaurantOrder ro
WHERE ro.order_id BETWEEN 1 AND 20;
GO

/* ============================ ASSIGNMENT VALIDATION ============================ */
SELECT 'Customers' AS entity, COUNT_BIG(*) AS sample_count FROM dbo.Customer
UNION ALL SELECT 'Employees', COUNT_BIG(*) FROM dbo.Employee
UNION ALL SELECT 'MenuItems', COUNT_BIG(*) FROM dbo.MenuItem
UNION ALL SELECT 'Orders', COUNT_BIG(*) FROM dbo.RestaurantOrder
UNION ALL SELECT 'Reservations', COUNT_BIG(*) FROM dbo.Reservation
UNION ALL SELECT 'Suppliers', COUNT_BIG(*) FROM dbo.Supplier
UNION ALL SELECT 'Inventory', COUNT_BIG(*) FROM dbo.InventoryItem
UNION ALL SELECT 'Payments', COUNT_BIG(*) FROM dbo.Payment;
GO

