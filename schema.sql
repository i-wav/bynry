-- Stores companies (customers) using the inventory management system
CREATE TABLE company (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 

-- Represents physical warehouses owned by a company
CREATE TABLE warehouse (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_warehouse_company
        FOREIGN KEY (company_id)
        REFERENCES company(id)
        ON DELETE CASCADE
);


-- Stores product catalog information independent of warehouse stock
CREATE TABLE product (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    is_bundle BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_company
        FOREIGN KEY (company_id)
        REFERENCES company(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_company_sku
        UNIQUE (company_id, sku)
);


-- Stores current inventory quantity of a product in a specific warehouse
CREATE TABLE inventory (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_inventory_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_product_warehouse
        UNIQUE (product_id, warehouse_id)
);


-- Tracks every change made to inventory quantities for auditing and history
CREATE TABLE inventory_transaction (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    change_quantity INTEGER NOT NULL,
    reason VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_transaction_product
        FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_transaction_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(id)
        ON DELETE CASCADE
);


-- Stores suppliers that provide products to a company
CREATE TABLE supplier (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_supplier_company
        FOREIGN KEY (company_id)
        REFERENCES company(id)
        ON DELETE CASCADE
);


-- Maps suppliers to the products they provide, including cost details
CREATE TABLE supplier_product (
    id BIGSERIAL PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    supplier_sku VARCHAR(100),
    cost_price DECIMAL(12, 2),

    CONSTRAINT fk_supplier_product_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES supplier(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_supplier_product_product
        FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_supplier_product
        UNIQUE (supplier_id, product_id)
);


-- Defines bundled products made up of multiple component products
CREATE TABLE product_bundle (
    id BIGSERIAL PRIMARY KEY,
    bundle_product_id BIGINT NOT NULL,
    component_product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,

    CONSTRAINT fk_bundle_product
        FOREIGN KEY (bundle_product_id)
        REFERENCES product(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_component_product
        FOREIGN KEY (component_product_id)
        REFERENCES product(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_bundle_not_self
        CHECK (bundle_product_id <> component_product_id)
);
CREATE INDEX idx_product_sku ON product (sku);
CREATE INDEX idx_inventory_product_warehouse ON inventory (product_id, warehouse_id);
CREATE INDEX idx_inventory_transaction_created_at ON inventory_transaction (created_at);
CREATE INDEX idx_supplier_product_product_id ON supplier_product (product_id);
